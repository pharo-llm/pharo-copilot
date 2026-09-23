import asyncio
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import time

import httpx
import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import gateway as g

TOKEN = 'test-token-with-at-least-thirty-two-characters'
AUTH = {'Authorization': 'Bearer ' + TOKEN}


@pytest.fixture
def client(tmp_path, monkeypatch):
    store = tmp_path / 'tokens.json'
    store.write_text(json.dumps({hashlib.sha256(TOKEN.encode()).hexdigest(): {
        'user': 'alice', 'expires_at': time.time() + 600}}))
    monkeypatch.setattr(g, 'TOKEN_FILE', store)
    g.app.state.hits = {}
    g.app.state.active = set()
    with TestClient(g.app) as client:
        yield client


def test_auth_required_everywhere(client):
    for path in ['/api/tags', '/api/generate', '/docs', '/health']:
        assert client.get(path).status_code == 401
    assert client.get('/api/tags', headers={'Authorization': 'Bearer wrong'}).status_code == 401


def test_revoke_expire_and_broken_store_fail_closed(client):
    records = json.loads(g.TOKEN_FILE.read_text())
    next(iter(records.values()))['expires_at'] = time.time() - 1
    g.TOKEN_FILE.write_text(json.dumps(records))
    assert client.get('/api/tags', headers=AUTH).status_code == 401
    g.TOKEN_FILE.write_text('{}')
    assert client.get('/api/tags', headers=AUTH).status_code == 401
    g.TOKEN_FILE.write_text('broken')
    assert client.get('/api/tags', headers=AUTH).status_code == 503


@pytest.mark.parametrize('path', ['/api/pull', '/api/delete', '/api/create', '/api/chat', '/api/push', '/api/copy'])
def test_no_admin_or_chat_api(client, path):
    assert client.post(path, headers=AUTH, json={}).status_code == 404


def test_generation_enforces_server_policy(client, monkeypatch):
    seen = []
    async def upstream(path, payload=None):
        seen.append((path, payload))
        return {'response': '^ self', 'done': True, 'private': 'hidden'}
    monkeypatch.setattr(g, 'upstream', upstream)
    response = client.post('/api/generate', headers=AUTH, json={
        'model': g.MODEL, 'prompt': '<|fim_prefix|>foo<|fim_suffix|><|fim_middle|>',
        'options': {'num_ctx': 100000000, 'num_gpu': 999, 'stop': [], 'num_predict': 32},
        'keep_alive': '-1', 'system': 'ignore', 'raw': False})
    assert response.status_code == 200
    assert response.json() == {'response': '^ self', 'done': True}
    assert response.headers['cache-control'] == 'no-store'
    payload = seen[0][1]
    assert payload['options']['num_ctx'] == 8192
    assert payload['options']['num_predict'] == 32
    assert payload['options']['stop'] == g.STOP
    assert 'num_gpu' not in payload['options']
    assert payload['raw'] is True and payload['stream'] is False
    assert payload['keep_alive'] == '30m' and 'system' not in payload
    assert not g.app.state.active


@pytest.mark.parametrize('payload,code', [
    ({'model': 'other', 'prompt': 'hi'}, 403),
    ({'prompt': 'hi', 'stream': True}, 400),
    ({'prompt': 'hi', 'options': {'num_predict': -1}}, 400),
    ({'prompt': 'hi', 'options': {'num_predict': 100000}}, 400),
    ({'prompt': 'hi', 'options': {'num_predict': True}}, 400),
    ({'prompt': 'hi', 'options': []}, 400),
    ({'prompt': ['hi']}, 400),
    ({'prompt': 'x' * 49000}, 400),
    ({'prompt': 'x' * 66000}, 413),
    ([], 400),
])
def test_rejects_bad_requests(client, payload, code):
    assert client.post('/api/generate', headers=AUTH, json=payload).status_code == code


def test_bad_json(client):
    assert client.post('/api/generate', headers={**AUTH, 'Content-Type': 'application/json'}, content='{').status_code == 400
    assert client.post('/api/generate', headers=AUTH, content='{}').status_code == 415


def test_rate_limit(client, monkeypatch):
    monkeypatch.setattr(g, 'RPM', 2)
    assert client.get('/missing', headers=AUTH).status_code == 404
    assert client.get('/missing', headers=AUTH).status_code == 404
    assert client.get('/missing', headers=AUTH).status_code == 429


def test_concurrency_limit(client):
    identity = hashlib.sha256(TOKEN.encode()).hexdigest()
    g.app.state.active.add(identity)
    assert client.post('/api/generate', headers=AUTH, json={'prompt': 'hi'}).status_code == 429
    g.app.state.active = {'other1', 'other2'}
    assert client.post('/api/generate', headers=AUTH, json={'prompt': 'hi'}).status_code == 429


def test_model_discovery_filtered(client, monkeypatch):
    async def upstream(path, payload=None):
        if path == '/api/tags':
            return {'models': [{'name': g.MODEL.lower()}, {'name': 'secret'}]}
        return {'template': 'FIM', 'modelfile': '/secret/model', 'parameters': ''}
    monkeypatch.setattr(g, 'upstream', upstream)
    assert client.get('/api/tags', headers=AUTH).json() == {'models': [{'name': g.MODEL.lower()}]}
    response = client.post('/api/show', headers=AUTH, json={'model': g.MODEL})
    assert response.json() == {'template': 'FIM', 'parameters': ''}
    assert client.post('/api/show', headers=AUTH, json={'model': 'secret'}).status_code == 403


@pytest.mark.parametrize('kind,code', [('ok', 200), ('failure', 502), ('timeout', 504), ('redirect', 502), ('oversize', 502)])
def test_real_http_adapter_and_slot_cleanup(client, kind, code):
    def handle(request):
        assert request.url.path == '/api/generate'
        assert 'authorization' not in request.headers
        if kind == 'timeout':
            raise httpx.ReadTimeout('private upstream details')
        if kind == 'failure':
            return httpx.Response(500, text='private upstream details')
        if kind == 'redirect':
            return httpx.Response(302, headers={'Location': 'https://example.org'})
        if kind == 'oversize':
            return httpx.Response(200, content=b'x' * (g.MAX_RESPONSE + 1))
        return httpx.Response(200, json={'response': '^ 42', 'done': True})
    original = g.app.state.client
    g.app.state.client = httpx.AsyncClient(base_url='http://ollama:11434', transport=httpx.MockTransport(handle))
    try:
        response = client.post('/api/generate', headers=AUTH, json={'prompt': 'answer'})
        assert response.status_code == code
        assert 'private' not in response.text
        assert not g.app.state.active
    finally:
        asyncio.run(g.app.state.client.aclose())
        g.app.state.client = original


def test_credential_issue_rotate_revoke(tmp_path):
    store = tmp_path / 'tokens.json'
    cmd = [sys.executable, str(Path(g.__file__).with_name('credentials.py')), '--store', str(store)]
    token = subprocess.check_output(cmd + ['issue', 'alice'], text=True).strip()
    assert len(token) >= 40
    assert token not in store.read_text()
    assert store.stat().st_mode & 0o777 == 0o600
    replacement = subprocess.check_output(cmd + ['issue', 'alice'], text=True).strip()
    assert replacement != token
    assert len(json.loads(store.read_text())) == 1
    subprocess.run(cmd + ['revoke', 'alice'], check=True)
    assert json.loads(store.read_text()) == {}
