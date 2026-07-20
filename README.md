[![Pharo 13 & 14](https://img.shields.io/badge/Pharo-13%20%7C%2014-2c98f0.svg)](https://github.com/pharo-llm/pharo-copilot)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/pharo-llm/pharo-copilot/blob/master/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/pharo-llm/pharo-copilot/pulls)
[![Status: Active](https://img.shields.io/badge/status-active-success.svg)](https://github.com/pharo-llm/pharo-copilot/)
[![CI](https://github.com/pharo-llm/pharo-copilot/actions/workflows/CI.yml/badge.svg)](https://github.com/pharo-llm/pharo-copilot/actions/workflows/CI.yml)


# Pharo-Copilot

Pharo-Copilot is an AI-powered code completion engine for Pharo, designed to enhance your coding experience with intelligent, context-aware suggestions.

## Installation

Ensure you have **Pharo** installed on your system as well as **[Ollama]([https://ollama.com/](https://ollama.com/download/windows))** for the underlying AI model hosting.

To install `pharo-copilot` in your image you can use:

```smalltalk
Metacello new
  githubUser: 'pharo-llm' project: 'pharo-copilot' commitish: 'main' path: 'src';
  baseline: 'AIPharoCopilot';
  load.
```

## Troubleshooting Ollama model downloads

If setup downloads a model but it does not appear in `ollama list`, verify that Pharo-Copilot and your terminal are talking to the same Ollama server and model store. On Linux, the system service often runs as the `ollama` user and stores models under `/usr/share/ollama/.ollama/models`, while an `ollama serve` process launched from Pharo can use your user account's `~/.ollama/models`. Also check whether `OLLAMA_HOST` or `OLLAMA_MODELS` differs between Pharo and your shell.

You can install the default model manually with:

```sh
ollama pull pharo-llm/Qwen2.5-Coder-SFT:q4_K_M
```

## Optional Usage Data Collection

After setup finishes downloading/verifying the required models, Pharo-Copilot
asks whether the user wants to send anonymous usage data to help improve
Pharo-Copilot. The default is opt-in only: if the user answers No, no remote
telemetry is sent.

User images cannot write directly to a server filesystem path such as
`/home/oabedelk/pharo-copilot-collector`. They must send HTTP to a deployed
collector URL. The Python collector stores received data on the server side.

For local development with the Python collector:

```sh
cd /home/oabedelk/pharo-copilot-collector
./start.sh --port 9093 --routes / --data-dir /home/oabedelk/pharo-copilot-collector/data
```

Then configure the Pharo image before running setup:

```smalltalk
CopilotSettings dataSharingEndpointUrl: 'http://127.0.0.1:9093/'.
```

For released images, do not use `127.0.0.1`: that would point to the user's
own computer. Deploy the Python collector on the server machine, expose it with
a public HTTPS URL, and set that URL instead:

```smalltalk
CopilotSettings dataSharingEndpointUrl: 'https://rmod-xp.lille.inria.fr/'.
```

You can also provide the URL when the image starts:

```sh
PHARO_COPILOT_COLLECTOR_URL='https://rmod-xp.lille.inria.fr/' pharo Pharo.image
```

The default production endpoint is `https://rmod-xp.lille.inria.fr/`.
`PHARO_COPILOT_COLLECTOR_URL` or a saved
`CopilotSettings dataSharingEndpointUrl:` value can override it.

The public domain must forward `PUT /` requests to the Python collector. For
example, a reverse proxy can terminate HTTPS on port 443 and forward to the
collector running locally on `127.0.0.1:9093`.

The collector metadata path is:

```text
data/pharo-copilot/pharo-copilot/<anonymous-participant-id>/usage/
```

Telemetry payloads intentionally avoid source code, prompts, and generated
completions.


# Example

https://github.com/user-attachments/assets/dc33edb3-6e3c-4d1d-a6f8-550f03c17631
