"""Offline credential administration. No public signup or admin HTTP endpoint."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import secrets
import tempfile
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--store', type=Path, default=Path('secrets/tokens.json'))
    sub = parser.add_subparsers(dest='action', required=True)
    issue = sub.add_parser('issue')
    issue.add_argument('user')
    issue.add_argument('--days', type=int, default=30)
    revoke = sub.add_parser('revoke')
    revoke.add_argument('user')
    args = parser.parse_args()
    if args.action == 'issue' and not 1 <= args.days <= 365:
        parser.error('--days must be between 1 and 365')
    args.store.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    records = json.loads(args.store.read_text()) if args.store.exists() else {}
    records = {k: v for k, v in records.items() if v['user'] != args.user}
    token = None
    if args.action == 'issue':
        token = secrets.token_urlsafe(32)
        records[hashlib.sha256(token.encode()).hexdigest()] = {
            'user': args.user, 'expires_at': time.time() + args.days * 86400}
    fd, name = tempfile.mkstemp(dir=args.store.parent)
    with os.fdopen(fd, 'w') as output:
        json.dump(records, output, indent=2)
        output.write('\n')
    os.replace(name, args.store)
    if token:
        print(token)  # Only printed once. Deliver privately to this user.


if __name__ == '__main__':
    main()
