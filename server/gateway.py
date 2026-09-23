"""Completion-only Ollama gateway. Run one worker; expose only through HTTPS."""
import asyncio
from collections import deque
from contextlib import asynccontextmanager
import hashlib
import json
import math
import os
from pathlib import Path
import time

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


@asynccontextmanager
async def lifespan(app):
    read_tokens()  # Fail closed at startup if credentials are missing/malformed.
    app.state.client = httpx.AsyncClient(
        base_url=os.getenv('OLLAMA_URL', 'http://ollama:11434'),
        timeout=httpx.Timeout(55, connect=5), trust_env=False,
        limits=httpx.Limits(max_connections=4))
    yield
    await app.state.client.aclose()


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
    if len(hits) >= RPM:
        return JSONResponse({'error': 'Rate limit exceeded'}, status_code=429,
                            headers={'Retry-After': '60'})
    hits.append(now)
    request.state.identity = digest
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
    try:
        result = await upstream('/api/generate', {
            'model': MODEL, 'prompt': prompt, 'raw': True, 'stream': False,
            'keep_alive': '30m', 'options': safe})
        return {k: result[k] for k in (
            'model', 'response', 'done', 'done_reason', 'created_at',
            'total_duration', 'load_duration', 'prompt_eval_count',
            'prompt_eval_duration', 'eval_count', 'eval_duration') if k in result}
    finally:
        app.state.active.remove(identity)
