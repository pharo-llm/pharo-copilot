"""Completion-only Ollama gateway. Run one worker; expose only through HTTPS."""
import asyncio
from collections import deque
from contextlib import asynccontextmanager
import hashlib
import json
import math
import logging
from logging.handlers import RotatingFileHandler
from contextlib import suppress
import os
from pathlib import Path
import time
import uuid

from experiment import record_completion
from session_state import SessionState

import httpx
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse

MODEL = os.getenv('COPILOT_MODEL', 'pharo-llm/Qwen2.5-Coder-SFT:q4_K_M')
TOKEN_FILE = Path(os.getenv('COPILOT_TOKEN_FILE', '/run/copilot/tokens.json'))
MAX_BODY = 65536
MAX_RESPONSE = 2 * 1024 * 1024
RPM = 120
MAX_ACTIVE = 2
STOP = ['<|endoftext|>', '<|fim_prefix|>', '<|fim_suffix|>', '<|fim_middle|>', '<|repo_name|>', '<|file_sep|>']


def read_tokens():
    records = json.loads(TOKEN_FILE.read_text())
    if not isinstance(records, dict):
        raise ValueError('Invalid credential store')
    for digest, record in records.items():
        if (len(digest) != 64 or any(c not in '0123456789abcdef' for c in digest)
                or not isinstance(record, dict)
                or type(record.get('expires_at')) not in (float, int)
                or not math.isfinite(record['expires_at'])):
            raise ValueError('Invalid credential record')
    return records


audit = logging.getLogger('copilot.audit')
audit.setLevel(logging.INFO)


def event(name, **fields):
    audit.info(json.dumps({'timestamp': time.time(), 'event': name, **fields}))


async def expire_sessions():
    while True:
        await asyncio.sleep(10)
        try:
            app.state.sessions.expire()
        except (OSError, ValueError):
            event('session_store_error')


@asynccontextmanager
async def lifespan(app):
    read_tokens()  # Fail closed at startup if credentials are missing/malformed.
    log_file = Path(os.getenv('COPILOT_AUDIT_LOG', str(TOKEN_FILE.parent / 'admin-events.jsonl')))
    log_file.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    handler = (logging.FileHandler(log_file) if os.getenv('COPILOT_EXPERIMENT_DIR')
               else RotatingFileHandler(log_file, maxBytes=10 * 1024 * 1024, backupCount=5))
    log_file.chmod(0o600)
    audit.addHandler(handler)
    app.state.sessions = SessionState(
        os.getenv('COPILOT_SESSION_FILE', str(TOKEN_FILE.parent / 'sessions.json')),
        timeout=int(os.getenv('COPILOT_SESSION_TIMEOUT', '300')), emit=event)
    event('server_started')
    expiry_task = asyncio.create_task(expire_sessions())
    app.state.client = httpx.AsyncClient(
        base_url=os.getenv('OLLAMA_URL', 'http://ollama:11434'),
        timeout=httpx.Timeout(55, connect=5), trust_env=False,
        limits=httpx.Limits(max_connections=4))
    try:
        yield
    finally:
        expiry_task.cancel()
        with suppress(asyncio.CancelledError):
            await expiry_task
        await app.state.client.aclose()
        event('server_stopped')
        audit.removeHandler(handler)
        handler.close()


app = FastAPI(lifespan=lifespan, docs_url=None, redoc_url=None, openapi_url=None)
app.state.hits = {}
app.state.active = set()


@app.middleware('http')
async def authenticate(request: Request, call_next):
    # No user agent, Origin, or secret embedded in the plugin can attest its identity.
    authorization = request.headers.get('authorization', '')
    if not authorization.startswith('Bearer ') or len(authorization) > 256:
        return JSONResponse({'error': 'Unauthorized'}, status_code=401)
    digest = hashlib.sha256(authorization[7:].encode()).hexdigest()
    try:
        records = read_tokens()  # Reload every request: revocation needs no restart.
    except (OSError, ValueError, TypeError):
        return JSONResponse({'error': 'Credentials unavailable'}, status_code=503)
    record = records.get(digest)
    if record is None or record['expires_at'] <= time.time():
        return JSONResponse({'error': 'Unauthorized'}, status_code=401)
    now = time.monotonic()
    # Bound memory to active credentials, including after token rotation.
    app.state.hits = {k: v for k, v in app.state.hits.items() if k in records}
    hits = app.state.hits.setdefault(digest, deque())
    while hits and hits[0] <= now - 60:
        hits.popleft()
    if len(hits) >= RPM and request.url.path != '/api/session/close':
        return JSONResponse({'error': 'Rate limit exceeded'}, status_code=429,
                            headers={'Retry-After': '60'})
    if request.url.path != '/api/session/close':
        hits.append(now)
    request.state.identity = digest
    request.state.user = record.get('user')
    if request.url.path in SESSION_PATHS:
        try:
            failure = app.state.sessions.touch(
                digest, record, request.headers.get('x-copilot-session', ''),
                request.client.host if request.client else None)
        except (OSError, ValueError):
            event('session_store_error')
            return JSONResponse({'error': 'Session store unavailable'}, status_code=503)
        if failure:
            code, message = failure
            return JSONResponse({'error': message}, status_code=code)
    response = await call_next(request)
    response.headers['Cache-Control'] = 'no-store'
    return response


async def body(request):
    if request.headers.get('content-type', '').split(';')[0].strip() != 'application/json':
        raise HTTPException(415, 'Expected application/json')
    data = bytearray()
    async for chunk in request.stream():
        data.extend(chunk)
        if len(data) > MAX_BODY:
            raise HTTPException(413, 'Request too large')
    try:
        result = json.loads(data)
    except (ValueError, RecursionError):
        raise HTTPException(400, 'Invalid JSON') from None
    if not isinstance(result, dict):
        raise HTTPException(400, 'Expected JSON object')
    return result


async def upstream(path, payload=None):
    try:
        # Wall-clock deadline as well as socket timeouts; never follow redirects.
        async with asyncio.timeout(55):
            async with app.state.client.stream(
                'GET' if payload is None else 'POST', path, json=payload
            ) as response:
                response.raise_for_status()
                data = bytearray()
                async for chunk in response.aiter_bytes():
                    data.extend(chunk)
                    if len(data) > MAX_RESPONSE:
                        raise ValueError('Response too large')
                result = json.loads(data)
                if not isinstance(result, dict) or 'error' in result:
                    raise ValueError('Invalid upstream response')
                return result
    except (TimeoutError, httpx.TimeoutException):
        raise HTTPException(504, 'Model timed out') from None
    except (httpx.HTTPError, ValueError):
        raise HTTPException(502, 'Model unavailable') from None


def check_model(payload):
    if str(payload.get('model', MODEL)).lower() != MODEL.lower():
        raise HTTPException(403, 'Model not allowed')


@app.get('/api/tags')
async def tags():
    response = await upstream('/api/tags')
    return {'models': [m for m in response.get('models', [])
                       if m.get('name', '').lower() == MODEL.lower()]}


@app.post('/api/show')
async def show(request: Request):
    payload = await body(request)
    check_model(payload)
    result = await upstream('/api/show', {'model': MODEL})
    # Do not expose model files, paths or arbitrary model administration.
    return {k: result[k] for k in ('template', 'parameters', 'details', 'capabilities') if k in result}


@app.post('/api/generate')
async def generate(request: Request):
    payload = await body(request)
    check_model(payload)
    prompt = payload.get('prompt')
    if not isinstance(prompt, str) or not prompt or len(prompt.encode()) > 48000:
        raise HTTPException(400, 'Invalid completion prompt')
    if payload.get('stream', False) is not False:
        raise HTTPException(400, 'Streaming is disabled')
    options = payload.get('options', {})
    if not isinstance(options, dict):
        raise HTTPException(400, 'Invalid options')
    # Explicit allowlist: users cannot control context allocation, GPU options,
    # keep-alive, templates, arbitrary stop lists or unlimited output tokens.
    safe = {'num_ctx': 8192, 'num_predict': 128, 'temperature': 0.2,
            'top_p': 0.9, 'top_k': 40, 'repeat_penalty': 1.1, 'stop': STOP}
    bounds = {'num_predict': (1, 256), 'temperature': (0, 1),
              'top_p': (0, 1), 'top_k': (1, 100), 'repeat_penalty': (0.5, 2)}
    for key, (low, high) in bounds.items():
        value = options.get(key, safe[key])
        if type(value) not in (int, float) or not low <= value <= high:
            raise HTTPException(400, 'Invalid generation option')
        if key in ('num_predict', 'top_k') and type(value) is not int:
            raise HTTPException(400, 'Expected integer option')
        safe[key] = value
    identity = request.state.identity
    if identity in app.state.active or len(app.state.active) >= MAX_ACTIVE:
        raise HTTPException(429, 'Model busy', headers={'Retry-After': '2'})
    app.state.active.add(identity)
    request_id = uuid.uuid4().hex
    started = time.monotonic()
    details = dict(request_id=request_id, token_id=identity,
                   user=request.state.user,
                   session_id=request.headers.get('x-copilot-session'))
    try:
        save_completion(event='completion_started', **details, model=MODEL,
                        prompt=prompt, options=safe)
        result = await upstream('/api/generate', {
            'model': MODEL, 'prompt': prompt, 'raw': True, 'stream': False,
            'keep_alive': '30m', 'options': safe})
        result = {k: result[k] for k in (
            'model', 'response', 'done', 'done_reason', 'created_at',
            'total_duration', 'load_duration', 'prompt_eval_count',
            'prompt_eval_duration', 'eval_count', 'eval_duration') if k in result}
        save_completion(event='completion_finished', **details,
                        duration_ms=round((time.monotonic() - started) * 1000, 2), result=result)
        return result
    except HTTPException as error:
        save_completion(event='completion_failed', **details, status=error.status_code,
                        duration_ms=round((time.monotonic() - started) * 1000, 2))
        raise
    finally:
        app.state.active.remove(identity)


SESSION_PATHS = {
    '/api/tags', '/api/show', '/api/generate', '/api/session/heartbeat',
    '/api/session/close', '/api/sessions', '/api/session-telemetry',
    '/api/connections/register', '/api/connections/ping'}


@app.post('/api/session/heartbeat')
async def heartbeat():
    return {'ok': True}


@app.post('/api/session/close')
async def close_session(request: Request):
    app.state.sessions.close(request.state.identity)
    return {'ok': True, 'status': 'closed'}


@app.middleware('http')
async def log_request(request: Request, call_next):
    started = time.monotonic()
    code = 500
    try:
        response = await call_next(request)
        code = response.status_code
        response.headers['Cache-Control'] = 'no-store'
        return response
    finally:
        # No authorization, body, query string or arbitrary URL goes into the audit log.
        event('request', method=request.method,
              path=request.url.path if request.url.path in SESSION_PATHS | {'/'} else '<unknown>',
              status=code, duration_ms=round((time.monotonic() - started) * 1000, 2),
              peer=request.client.host if request.client else None,
              token_id=getattr(request.state, 'identity', None),
              user=getattr(request.state, 'user', None))


def save_completion(**fields):
    try:
        record_completion(**fields)
    except OSError:
        event('completion_history_write_failed')
        raise HTTPException(503, 'Completion history storage unavailable') from None
