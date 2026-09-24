[![Pharo 13 & 14 & 15](https://img.shields.io/badge/Pharo-13%20%7C%2014%20%7C%2015-2c98f0.svg)](https://github.com/pharo-llm/pharo-copilot)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/pharo-llm/pharo-copilot/blob/master/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/pharo-llm/pharo-copilot/pulls)
[![Status: Active](https://img.shields.io/badge/status-active-success.svg)](https://github.com/pharo-llm/pharo-copilot/)
[![CI](https://github.com/pharo-llm/pharo-copilot/actions/workflows/CI.yml/badge.svg)](https://github.com/pharo-llm/pharo-copilot/actions/workflows/CI.yml)


# Pharo-Copilot

Pharo-Copilot is an AI-powered code completion engine for Pharo, designed to enhance your coding experience with intelligent, context-aware suggestions.

## Installation

Install this repository in Pharo. When loading finishes, a small setup window
asks for your access token. Paste the token supplied by the administrator and
click **Connect**. The plugin connects to `http://193.49.213.153:8080` and enables
completion after verifying access. If the token is rejected, use **Enter access
token** to correct it and retry.

Users only need Pharo. The model runs on the server in
`/home/oabedelk/pharo-copilot-server`, started with `./run-server.sh`.
Tokens are stored in a file under the user's home directory.

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
