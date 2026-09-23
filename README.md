[![Pharo 13 & 14 & 15](https://img.shields.io/badge/Pharo-13%20%7C%2014%20%7C%2015-2c98f0.svg)](https://github.com/pharo-llm/pharo-copilot)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/pharo-llm/pharo-copilot/blob/master/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/pharo-llm/pharo-copilot/pulls)
[![Status: Active](https://img.shields.io/badge/status-active-success.svg)](https://github.com/pharo-llm/pharo-copilot/)
[![CI](https://github.com/pharo-llm/pharo-copilot/actions/workflows/CI.yml/badge.svg)](https://github.com/pharo-llm/pharo-copilot/actions/workflows/CI.yml)


# Pharo-Copilot

Pharo-Copilot is an AI-powered code completion engine for Pharo, designed to enhance your coding experience with intelligent, context-aware suggestions.

## Hosted model / private server

To run the model on a central server while users run only the plugin, see the
[private server deployment guide](server/README.md). It includes Docker deployment,
HTTPS, per-user credentials, revocation, resource limits and Pharo configuration.
Expose **TCP 443 only**; keep Ollama's 11434 and the gateway's 8080 private.
Approved users control their clients, so plugin-exclusive access cannot be guaranteed.

For automatic hosted installation, the administrator runs
`./make-user-installer.sh alice` in the server repository and privately sends
`installers/alice-install.st` to Alice. Evaluating that personal installer installs
the plugin and configures server access automatically. After setup verifies the
connection, it shows “OKAY! Pharo-Copilot installed successfully!”. See the
[automatic installation guide](server/README.md#automatic-installation-for-users).

## Installation

Ensure you have **Pharo** installed on your system as well as **[Ollama]([https://ollama.com/](https://ollama.com/download/windows))** for the underlying AI model hosting.

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
