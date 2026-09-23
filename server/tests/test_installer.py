import hashlib
import base64
import json
from pathlib import Path
import subprocess
import sys

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import make_installer as m


@pytest.fixture
def setup(tmp_path):
    config = tmp_path / '.env'
    config.write_text('COPILOT_DOMAIN=copilot.example.org\nCOPILOT_MODEL=model:q4\n')
    plugin = tmp_path / 'plugin'
    package = plugin / 'src/BaselineOfAIPharoCopilot'
    package.mkdir(parents=True)
    (package / 'BaselineOfAIPharoCopilot.class.st').write_text("Class { #name : 'BaselineOfAIPharoCopilot' }")
    store = tmp_path / 'secrets/tokens.json'
    output = tmp_path / 'installers'
    command = [sys.executable, str(Path(m.__file__)), 'alice', '--config', str(config),
               '--plugin', str(plugin), '--store', str(store), '--output-dir', str(output)]
    return command, store, output


def test_private_installer_bundles_source_and_config(setup):
    command, store, output = setup
    result = subprocess.run(command, capture_output=True, text=True, check=True)
    installer = output / 'alice-install.st'
    source = installer.read_text()
    token = source.split("    accessToken: '")[1].split("'")[0]
    assert hashlib.sha256(token.encode()).hexdigest() in json.loads(store.read_text())
    assert token not in result.stdout and token not in store.read_text()
    assert installer.stat().st_mode & 0o777 == 0o600
    assert base64.b64encode(b"Class { #name : 'BaselineOfAIPharoCopilot' }").decode() in source
    assert "configureHostedServer: 'copilot.example.org'" in source
    assert "model: 'model:q4'" in source
    assert 'ensure:' in source and 'removeKey: #CoPCHostedInstallInProgress' in source
    assert source.index('configureHostedServer:') < source.index('showFirstLaunchSetupIfNeeded.')


def test_regenerating_installer_rotates_only_its_user(setup):
    command, store, output = setup
    subprocess.run(command, check=True, capture_output=True)
    previous = set(json.loads(store.read_text()))
    subprocess.run(command, check=True, capture_output=True)
    current = set(json.loads(store.read_text()))
    assert len(current) == 1 and current.isdisjoint(previous)


def test_invalid_checkout_does_not_revoke_existing_credential(setup):
    command, store, output = setup
    subprocess.run(command, check=True, capture_output=True)
    previous = store.read_text()
    command[command.index('--plugin') + 1] = '/missing-plugin-checkout'
    assert subprocess.run(command, capture_output=True).returncode != 0
    assert store.read_text() == previous


def test_user_cannot_escape_output_directory(setup):
    command, store, output = setup
    command[2] = '../alice'
    assert subprocess.run(command, capture_output=True).returncode != 0
    assert not store.exists()
