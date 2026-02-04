[![Pharo 13 & 14](https://img.shields.io/badge/Pharo-13%20%7C%2014-2c98f0.svg)](https://github.com/pharo-llm/pharo-copilot)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/pharo-llm/pharo-copilot/blob/master/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/pharo-llm/pharo-copilot/pulls)
[![Status: Active](https://img.shields.io/badge/status-active-success.svg)](https://github.com/pharo-llm/pharo-copilot/)
[![CI](https://github.com/pharo-llm/pharo-copilot/actions/workflows/CI.yml/badge.svg)](https://github.com/pharo-llm/pharo-copilot/actions/workflows/CI.yml)


# Pharo-Copilot

Pharo-Copilot is an AI-powered code completion engine for Pharo, designed to enhance your coding experience with intelligent, context-aware suggestions.

## Installation

Ensure you have **Pharo** installed on your system as well as **[Ollama](https://ollama.com/)** for the underlying AI model hosting.

To install development version of `Pharo-Copilot` in your image you can use:

```smalltalk
Metacello new
  githubUser: 'omarabedelkader' project: 'Pharo-Copilot' commitish: 'main' path: 'src';
  baseline: 'AIPharoCopilot';
  load
```
Make sure you are connected to the internet before loading, as the engine may require online requests for AI completions.

## Usage

Once installed, you can enable **Pharo-Copilot** as your completion engine:

1. Open **Pharo Settings**
   `Pharo → Settings`
2. Navigate to:
   `Code Browser → Code Completion → Completion Engine`
3. From the dropdown, **select `Copilot`**.
