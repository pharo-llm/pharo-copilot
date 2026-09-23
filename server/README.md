# Private hosted completions

The user's Pharo image sends completion context over HTTPS and receives suggestions.
Only this server runs Ollama and stores the model. Local mode remains available for
existing installations; configure remote mode below for hosted users.

```text
Pharo plugin -- HTTPS + individual credential --> Caddy :443
                                                  |
                                           gateway :8080
                                                  |
                                            Ollama :11434
```

## Security boundary

This is an **authenticated service**, not proof that a caller runs the plugin.
An owner of a Pharo image can inspect its code, read its credential, and reproduce
requests with another program. A shared embedded secret, user-agent check, CORS,
request signature, or client certificate would not prevent that owner from doing
so. Never distribute one shared credential to all users.

The implemented controls are:

- A random 256-bit credential per user, SHA-256 hashes stored server-side, default
  expiry of 30 days, immediate revocation for subsequent requests.
- HTTPS with explicit client certificate-chain and exact hostname checks before
  credentials or code are sent; redirects disabled. Use a certificate for the
  exact hostname, not a wildcard. Update the Pharo VM/CA trust store if verification
  fails; do not disable validation.
- Only model discovery, limited metadata, and completion generation are exposed.
  Pull, delete, push, create, chat and all other routes are unavailable.
- One administrator-selected model. Fixed 8192-token context, at most 256 output
  tokens, at most two simultaneous generations globally and one per credential.
  Each credential allows 120 requests/minute. Invalid generation bounds are rejected.
- A 64 KiB request limit, 48 KB prompt limit, 2 MiB upstream response limit and
  55-second model deadline. The gateway overrides GPU/context/keep-alive settings
  and does not forward arbitrary client options or credentials to Ollama.
- No gateway request-body or access logging. Tokens are not saved in Pharo's
  settings file. Tokens and source code necessarily exist transiently in client
  memory; never share a running/saved image containing sensitive state.

A permitted user can still submit arbitrary text as a completion prompt. These
controls bound resource access, not prompt intent. Revocation does not cancel an
already-running generation. Limits are per **single gateway process**; do not
increase Uvicorn workers or replicas without a shared quota/concurrency store.
For network-level privacy, place the HTTPS endpoint behind your institution's VPN
and restrict TCP 443 to its address ranges. This further limits reachability but
still cannot attest which application an authorized user runs.

## Deploy on this server

Requires Docker Engine + Compose v2, a DNS hostname pointing to this server, and
sufficient RAM/VRAM for the selected model. GPU acceleration requires the NVIDIA
Container Toolkit; the base deployment can run on CPU, with higher latency.

From this directory:

```sh
cp .env.example .env
id -u
id -g
```

Edit `.env`: set `COPILOT_DOMAIN` to the real DNS hostname, and `COPILOT_UID` /
`COPILOT_GID` to the values above. The unprivileged gateway must be able to read
`secrets/tokens.json`, owned by that user. Keep the same model name in Pharo and
`.env`; the default is `pharo-llm/Qwen2.5-Coder-SFT:q4_K_M`.

Issue the first user's credential before starting the gateway:

```sh
umask 077
python3 credentials.py issue alice > alice.token
```

Deliver `alice.token` through a private channel to that user. Do not commit it,
put it in a URL, or paste it into a public Pharo script. Move it out of the repo
after delivery. `secrets/` contains only hashes and expiry metadata and is ignored
by Git. Run credential administration commands one at a time.

```sh
docker compose config --quiet
docker compose up -d ollama
docker compose exec ollama ollama pull pharo-llm/Qwen2.5-Coder-SFT:q4_K_M
docker compose up -d --build
docker compose logs --tail=50 gateway edge
```

For an NVIDIA GPU, use `docker compose -f compose.yaml -f compose.gpu.yaml`
in place of `docker compose` in these commands. The model download may be large.
Choose and pin tested image digests for Caddy/Ollama in your production rollout;
the supplied image tags follow upstream releases. Python dependencies are pinned.

**Open inbound TCP 443 only for this service.** Do not open 8080 or 11434.
Port 80 and UDP 443 are not required: Caddy is configured for HTTP/1.1 + HTTP/2
and ACME TLS-ALPN validation on 443. Existing SSH access is a separate concern.
Caddy needs outbound DNS/HTTPS for certificates, and Ollama needs outbound HTTPS
for administrator-initiated model downloads. No container publishes the model or
gateway port. Check for any separately installed host Ollama service that might
already expose 11434; this deployment does not reconfigure existing host services.

Caddy certificate issuance requires the public DNS record and inbound 443 to work.
A VPN-only deployment should use an organization-issued certificate or DNS-based
ACME validation instead of the supplied public TLS-ALPN configuration.

## Automatic installation for users

After starting the server and setting its real hostname in `.env`, create an
individual installer:

```sh
./make-user-installer.sh alice
```

This creates `installers/alice-install.st`, containing the current modified plugin
source, the server address, and Alice's individual credential. Privately send this
one file to Alice. She opens it in a Pharo Playground and evaluates the entire
file. No server settings, credential copying, Ollama or model downloads are needed.
The existing optional research consent choices remain available. Once setup
verifies the authenticated connection and hosted model, it enables completion and
shows **“OKAY! Pharo-Copilot installed successfully!”**. If the server is unavailable
or access is invalid, setup offers a retry and does not report success.

The generator reads the adjacent `pharo-copilot` checkout by default; use
`--plugin /path/to/pharo-copilot` if it is elsewhere. It bundles the source so you
do not need to publish changes to GitHub first. Never publish personal installers
or put them in a public repository; each contains its user's credential. Generated
files have mode 0600 and their directory is ignored by Git. Generating another
installer for the same user rotates their credential. Access expires after 30
days by default (`--days 90` changes this); deliver a fresh personal installer to
renew it. The server startup command never rotates these credentials.

The plugin stores its credential automatically under the user's home directory,
separate from telemetry logs. On Unix it sets directory mode 0700 and file mode
0600 before writing the token; on Windows it relies on the home directory's user
ACLs. Do not share the personal installer or the user's configured image. Server
privacy still relies on individual authorization, not proof of plugin identity.

## Manual configuration (optional)

Install this modified checkout in Pharo, using an absolute local path:

```smalltalk
Metacello new
  baseline: 'AIPharoCopilot';
  repository: 'tonel:///absolute/path/to/pharo-copilot/src';
  load.
```

Close the initial local setup dialog if shown. Save the delivered credential in a
file readable only by that OS user (`chmod 600` on Linux/macOS; equivalent ACL on
Windows). Then evaluate:

```smalltalk
CopilotSettings
  useRemoteServer: 'copilot.example.org'
  tokenFile: '/absolute/private/path/alice.token'.
CopilotSettings modelName: 'pharo-llm/Qwen2.5-Coder-SFT:q4_K_M'.
CopilotSettings remoteModelAvailable. "Should answer true"
CopilotSettings installCompletionEngineIfAvailable.
```

Only the hostname, mode and credential **path** are persisted in plugin settings.
The token is read afresh for each request, allowing replacement without restarting
Pharo. Users do not need Ollama, a GPU, model weights or local model installation.
Remote mode cannot launch local Ollama or pull models, including when the server
is down. The settings reset command restores the original local defaults.

Source context is sent to your server to perform inference regardless of the
separate optional research telemetry setting. Existing telemetry consent remains
independent of completion authentication.

## Revoke or rotate a user

```sh
python3 credentials.py revoke alice
# Reissue replaces the previous credential for this user:
umask 077
python3 credentials.py issue alice --days 30 > alice-new.token
```

No restart is needed. Expired/revoked/missing credentials receive 401. Rate or
concurrency limits return 429. A missing/down model returns 502; a model deadline
returns 504. No remote administration API is provided.

## Verification

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt -r requirements-test.txt
.venv/bin/python -m pytest tests -q
```

The tests exercise the HTTP API, authentication, expiry/revocation, resource limits,
blocked routes, upstream failures, credential rotation and model allowlisting,
using a simulated Ollama backend. They do not require downloading model weights.

After deployment, verify that unauthenticated HTTPS returns 401, Pharo's
`remoteModelAvailable` returns true, a real completion works, and connections to
public ports 8080/11434 fail. Also verify that an invalid server certificate fails
before sending credentials from each supported Pharo VM. End-to-end Pharo/TLS and
real-model validation must be performed on the deployment host.

References: [Ollama generation API](https://docs.ollama.com/api/generate),
[Caddy TLS configuration](https://caddyserver.com/docs/caddyfile/directives/tls),
[Pharo TLS implementation](https://github.com/svenvc/zodiac).
