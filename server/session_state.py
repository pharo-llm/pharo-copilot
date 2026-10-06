"""Single-worker, durable image sessions. Closed/expired tokens never bind again."""
import json
import math
import os
from pathlib import Path
import re
import tempfile
import time


class SessionState:
    def __init__(self, path, timeout=300, emit=lambda *a, **kw: None):
        self.path = Path(path)
        self.timeout = timeout
        self.emit = emit
        self.path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        # Missing state must not silently resurrect consumed credentials.
        marker = self.path.with_suffix('.initialized')
        if marker.exists() and not self.path.exists():
            raise ValueError('Session state missing; restore it from backup')
        self.records = json.loads(self.path.read_text()) if self.path.exists() else {}
        if not isinstance(self.records, dict):
            raise ValueError('Invalid session state')
        for key, record in self.records.items():
            if (not re.fullmatch(r'[0-9a-f]{64}', key) or not isinstance(record, dict)
                    or record.get('status') not in ('active', 'closed', 'expired')
                    or not isinstance(record.get('session_id'), str)
                    or type(record.get('lease_expires_at')) not in (int, float)
                    or not math.isfinite(record['lease_expires_at'])):
                raise ValueError('Invalid session record')
        self.save()
        marker.touch(mode=0o600, exist_ok=True)
        self.expire()

    def save(self):
        fd, name = tempfile.mkstemp(dir=self.path.parent)
        try:
            with os.fdopen(fd, 'w') as output:
                json.dump(self.records, output, indent=2)
                output.write('\n')
                output.flush()
                os.fsync(output.fileno())
            os.replace(name, self.path)
            fd = os.open(self.path.parent, os.O_RDONLY | os.O_DIRECTORY)
            try:
                os.fsync(fd)
            finally:
                os.close(fd)
        finally:
            Path(name).unlink(missing_ok=True)

    def expire(self):
        now = time.time()
        changed = False
        for digest, record in self.records.items():
            if record['status'] == 'active' and record['lease_expires_at'] <= now:
                record.update(status='expired', closed_at=now, close_reason='lease_expired')
                changed = True
                self.emit('session_expired', token_id=digest, session_id=record['session_id'])
        if changed:
            self.save()

    def touch(self, digest, credential, session_id, peer):
        self.expire()
        if not re.fullmatch(r'[A-Za-z0-9_-]{16,128}', session_id):
            return 426, 'Image session required; update the Pharo Copilot client'
        record = self.records.get(digest)
        if record and record['status'] != 'active':
            return 401, 'Access token expired: image session ended'
        if record and record['session_id'] != session_id:
            return 409, 'Access token belongs to another image session'
        now = time.time()
        if record is None:
            record = self.records[digest] = {
                'session_id': session_id, 'user': credential.get('user'),
                'status': 'active', 'started_at': now, 'request_count': 0}
            self.emit('session_started', token_id=digest, session_id=session_id, user=record['user'])
        record.update(last_seen_at=now, peer=peer,
                      lease_expires_at=min(now + self.timeout, credential['expires_at']),
                      request_count=record['request_count'] + 1)
        self.save()
        return None

    def close(self, digest):
        record = self.records[digest]
        record.update(status='closed', closed_at=time.time(), close_reason='image_closed')
        self.save()
        self.emit('session_closed', token_id=digest, session_id=record['session_id'])
