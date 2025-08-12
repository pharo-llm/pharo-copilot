# Pharo-Copilot

**Pharo-Copilot is an AI-powered code completion engine for Pharo, designed to enhance your coding experience with intelligent, context-aware suggestions.**

## Installation

Load **Pharo-Copilot** directly into your Pharo image using Metacello:

```smalltalk
Metacello new
  githubUser: 'omarabedelkader' project: 'Pharo-Copilot' commitish: 'main' path: 'src';
  baseline: 'AIPharoCopilot';
  load
```

Make sure you are connected to the internet before loading, as the engine may require online requests for AI completions.

---

## Usage

Once installed, you can enable **Pharo-Copilot** as your completion engine:

1. Open **Pharo Settings**
   `Pharo → Settings`
2. Navigate to:
   `Code Browser → Code Completion → Completion Engine`
3. From the dropdown, **select `Copilot`**.
