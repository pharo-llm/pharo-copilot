"""Build a private, self-contained Pharo installer with an individual credential."""
import argparse
import base64
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent


def st_string(value):
    return "'" + value.replace("'", "''") + "'"


def settings(path):
    return dict(line.split('=', 1) for line in path.read_text().splitlines()
                if line.strip() and not line.lstrip().startswith('#') and '=' in line)


def installer_source(host, model, token, plugin):
    # Bundle this checkout so the user does not depend on unpublished GitHub changes.
    files = sorted((plugin / 'src').rglob('*.st'))
    if not files or not (plugin / 'src/BaselineOfAIPharoCopilot/BaselineOfAIPharoCopilot.class.st').is_file():
        raise ValueError('Expected a pharo-copilot checkout with src/')
    sources = []
    for path in files:
        relative = path.relative_to(plugin).as_posix()
        sources.append('  { ' + st_string(relative) + '. ' + st_string(base64.b64encode(path.read_bytes()).decode('ascii')) + ' }')
    return '''"PERSONAL INSTALLER: contains an individual credential. Do not share or publish.
Evaluate this entire file in a Pharo Playground. No server/token configuration needed."
| directory files file copilot |
directory := FileLocator temp / ('pharo-copilot-install-', UUID new asString).
Smalltalk globals at: #CoPCHostedInstallInProgress put: true.
[
  directory ensureCreateDirectory.
  files := {
''' + '.\n'.join(sources) + '''
  }.
  files do: [ :entry |
    file := directory.
    (entry first findTokens: '/') do: [ :component | file := file / component ].
    file parent ensureCreateDirectory.
    file writeStreamDo: [ :stream | stream nextPutAll: entry second base64Decoded utf8Decoded ] ].
  Metacello new
    baseline: 'AIPharoCopilot';
    repository: 'tonel://', (directory / 'src') fullName;
    load.
  copilot := Smalltalk globals at: #CopilotSettings.
  copilot configureHostedServer: ''' + st_string(host) + '''
    accessToken: ''' + st_string(token) + '''
    model: ''' + st_string(model) + '''.
] ensure: [
  Smalltalk globals removeKey: #CoPCHostedInstallInProgress ifAbsent: [ ].
  directory exists ifTrue: [ directory deleteAll ] ].
(Smalltalk globals at: #BaselineOfAIPharoCopilot) showFirstLaunchSetupIfNeeded.
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('user')
    parser.add_argument('--days', type=int, default=30)
    parser.add_argument('--config', type=Path, default=HERE / '.env')
    default_plugin = HERE.parent if (HERE.parent / 'src').is_dir() else HERE.parent / 'pharo-copilot'
    parser.add_argument('--plugin', type=Path, default=default_plugin)
    parser.add_argument('--store', type=Path, default=HERE / 'secrets/tokens.json')
    parser.add_argument('--output-dir', type=Path, default=HERE / 'installers')
    args = parser.parse_args()
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]{0,63}', args.user):
        parser.error('Use a simple user name containing letters, digits, dots, hyphens or underscores')
    if not 1 <= args.days <= 365:
        parser.error('--days must be between 1 and 365')
    try:
        config = settings(args.config)
        host = config['COPILOT_DOMAIN'].strip()
        model = config['COPILOT_MODEL'].strip()
        if not re.fullmatch(r'[A-Za-z0-9.-]+', host) or not re.fullmatch(r'[A-Za-z0-9_./:+-]+', model):
            raise ValueError('Invalid hostname or model in .env')
        # Validate the checkout and build before changing a user's existing credential.
        placeholder = 'COPILOT_PRIVATE_TOKEN_PLACEHOLDER'
        source = installer_source(host, model, placeholder, args.plugin.resolve())
    except (OSError, KeyError, ValueError) as exc:
        parser.error(str(exc))
    args.output_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    destination = args.output_dir / (args.user + '-install.st')
    fd, temporary = tempfile.mkstemp(dir=args.output_dir)
    try:
        token = subprocess.check_output([
            sys.executable, str(HERE / 'credentials.py'), '--store', str(args.store),
            'issue', args.user, '--days', str(args.days)], text=True).strip()
        with os.fdopen(fd, 'w') as output:
            output.write(source.replace(st_string(placeholder), st_string(token)))
        os.replace(temporary, destination)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    print(f'Personal installer: {destination}')
    print('Deliver this file privately. The user evaluates it in a Pharo Playground.')
    print(f'Access expires in {args.days} days. This replaces any previous credential for {args.user}.')


if __name__ == '__main__':
    main()
