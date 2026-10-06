[![Pharo 13 & 14 & 15](https://img.shields.io/badge/Pharo-13%20%7C%2014%20%7C%2015-2c98f0.svg)](https://github.com/pharo-llm/pharo-copilot)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/pharo-llm/pharo-copilot/blob/master/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/pharo-llm/pharo-copilot/pulls)
[![Status: Active](https://img.shields.io/badge/status-active-success.svg)](https://github.com/pharo-llm/pharo-copilot/)
[![CI](https://github.com/pharo-llm/pharo-copilot/actions/workflows/CI.yml/badge.svg)](https://github.com/pharo-llm/pharo-copilot/actions/workflows/CI.yml)


# Pharo-Copilot

Pharo-Copilot is an AI-powered code completion engine for Pharo, designed to enhance your coding experience with intelligent, context-aware suggestions.

## Installation

Install this repository in Pharo. When loading finishes, the setup window asks
where you want to run your completion model:

- **Use cloud (access token required)**: paste the token supplied by your
  administrator and click **Connect**. The plugin connects to
  `http://193.49.213.153:8080` and enables completion after verifying access.
  You only need Pharo; the model runs on the server. Tokens are stored in a file
  under your home directory. If access fails, retry, enter a corrected token,
  or choose a local model.
- **Use local model (no token needed)**: setup checks Ollama on your computer,
  checks the installed models, and downloads any missing required models before
  enabling completion. If Ollama is missing, setup offers its download page.

Use **Back** on the cloud token screen to return to the choice.

To install `pharo-copilot` in your image you can use:

```smalltalk
Metacello new
  githubUser: 'pharo-llm' project: 'pharo-copilot' commitish: 'main' path: 'src';
  baseline: 'AIPharoCopilot';
  load.
```

## Consent to Collect Data
On first launch, Pharo-Copilot asks whether you want to participate in anonymous
Pharo usage research. Telemetry is off by default; choosing
"No, don't collect data" or closing the dialog keeps telemetry disabled and
still lets setup continue.

**If you explicitly agree, Pharo-Copilot can send anonymous IDE interaction events
to the Inria-hosted research.**

## Troubleshooting Ollama model downloads

If setup downloads a model but it does not appear in `ollama list`, verify that Pharo-Copilot and your terminal are talking to the same Ollama server and model store. On Linux, the system service often runs as the `ollama` user and stores models under `/usr/share/ollama/.ollama/models`, while an `ollama serve` process launched from Pharo can use your user account's `~/.ollama/models`. Also check whether `OLLAMA_HOST` or `OLLAMA_MODELS` differs between Pharo and your shell.

You can install the default model manually with:

```sh
ollama pull pharo-llm/Qwen2.5-Coder-SFT:q4_K_M
```

Remote access tokens are bound to one running image session. Normal image exit
finishes telemetry upload and retires the token; crashes or disconnected clients
expire after the server's heartbeat grace period (five minutes by default).
Saving without quitting keeps the session. Opening the saved image starts a new
session and requires a fresh token if the previous token was already used.
Update client and gateway together for session support. The server administrator
can inspect `sessions.json` and `admin-events.jsonl`; the standalone server also
provides `scripts/show-access.sh` and `scripts/tail-completion-log.sh`.
