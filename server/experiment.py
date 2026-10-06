"""Private, persistent experiment directories and durable completion history."""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import tempfile
import uuid


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def write_json(path, payload):
    path = Path(path)
    fd, name = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            json.dump(payload, stream, indent=2)
            stream.write('\n')
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
        fd = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(fd)
        finally:
            os.close(fd)
    finally:
        Path(name).unlink(missing_ok=True)


def create(data_root):
    data_root = Path(data_root).expanduser().resolve()
    data_root.mkdir(parents=True, exist_ok=True, mode=0o700)
    experiments = data_root / 'experiments'
    experiments.mkdir(exist_ok=True, mode=0o700)
    now = datetime.now(timezone.utc)
    day = experiments / now.strftime('%Y-%m-%d')
    day.mkdir(exist_ok=True, mode=0o700)
    run = day / (now.strftime('%Y-%m-%dT%H-%M-%S.%fZ') + '-' + uuid.uuid4().hex[:8])
    run.mkdir(mode=0o700)
    for name in ('logs', 'participants'):
        (run / name).mkdir(mode=0o700)
    write_json(run / 'experiment.json', {
        'experiment_id': run.name, 'created_at': utc_now(), 'status': 'starting',
        'timezone': 'UTC', 'directory': str(run)})
    latest = experiments / ('.latest-' + uuid.uuid4().hex)
    latest.symlink_to(run.relative_to(experiments), target_is_directory=True)
    os.replace(latest, experiments / 'latest')
    return run


def update(run, **fields):
    path = Path(run) / 'experiment.json'
    record = json.loads(path.read_text())
    record.update(fields)
    write_json(path, record)


def record_completion(**fields):
    run = os.getenv('COPILOT_EXPERIMENT_DIR')
    if not run:
        return  # Container/test installations may opt in with this variable.
    path = Path(run) / 'completions.jsonl'
    entry = dict(timestamp=utc_now(), **fields)
    existed = path.exists()
    # Called synchronously by the single gateway worker. Commit before acknowledging.
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_APPEND, 0o600)
    with os.fdopen(fd, 'a') as stream:
        stream.write(json.dumps(entry, ensure_ascii=True) + '\n')
        stream.flush()
        os.fsync(stream.fileno())
    if not existed:
        fd = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(fd)
        finally:
            os.close(fd)


def statistics(run):
    path = Path(run) / 'completions.jsonl'
    started, completed, failed = set(), set(), set()
    users = set()
    total_ms = 0
    prompt_tokens = output_tokens = damaged = 0
    if path.exists():
        with path.open() as stream:
            for line in stream:
                try:
                    item = json.loads(line)
                    request_id = item['request_id']
                    if item['event'] == 'completion_started':
                        started.add(request_id)
                        users.add(item['token_id'])
                    elif item['event'] == 'completion_finished':
                        completed.add(request_id)
                        total_ms += item['duration_ms']
                        result = item['result']
                        prompt_tokens += result.get('prompt_eval_count', 0)
                        output_tokens += result.get('eval_count', 0)
                    elif item['event'] == 'completion_failed':
                        failed.add(request_id)
                except (ValueError, KeyError, TypeError):
                    damaged += 1
    return dict(generated_at=utc_now(), requested=len(started), completed=len(completed),
                failed=len(failed), interrupted=len(started - completed - failed),
                participants=len(users), prompt_tokens=prompt_tokens, output_tokens=output_tokens,
                mean_generation_ms=round(total_ms / len(completed), 2) if completed else None,
                unreadable_records=damaged)


def finish(run, **fields):
    write_json(Path(run) / 'completion-stats.json', statistics(run))
    update(run, stopped_at=utc_now(), **fields)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['create', 'stats'])
    parser.add_argument('directory', type=Path)
    args = parser.parse_args()
    if args.action == 'create':
        print(create(args.directory))
    else:
        if not args.directory.is_dir():
            parser.error('Experiment directory not found; start the server or supply an existing run directory')
        print(json.dumps(statistics(args.directory), indent=2))


if __name__ == '__main__':
    main()
