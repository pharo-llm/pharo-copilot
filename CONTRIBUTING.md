# Contributing to Pharo-Copilot

Thanks for your interest in improving Pharo-Copilot! This guide explains how to propose changes and what to expect during review.

## Ways to contribute
- Report bugs or request features by opening an issue.
- Improve documentation and examples.
- Submit pull requests for fixes and new features.

## Development setup
1. Install **Pharo 13 or 14** and **[Ollama](https://ollama.com/)**.
2. Load the project into your image using Metacello:
   ```smalltalk
   Metacello new
     githubUser: 'pharo-llm' project: 'pharo-copilot' commitish: 'main' path: 'src';
     baseline: 'AIPharoCopilot';
     load
   ```
3. Ensure you have internet access so the completion engine can reach the underlying model.

## Pull request guidelines
- Discuss large changes in an issue before opening a PR.
- Keep PRs focused and clearly describe the motivation and approach.
- Update or add tests when relevant and ensure the test suite passes.
- Follow existing code style and avoid introducing unrelated formatting changes.

## Commit messages
Use clear, descriptive commit messages that explain the change. Reference related issues when applicable.

## Code of conduct
Please be respectful and collaborative. Interactions in issues, discussions, and pull requests should remain constructive and inclusive.
