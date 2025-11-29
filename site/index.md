{
"title" : "Pharo-Copilot Documentation",
"layout": "index",
"publishDate": "2025-11-30"
}


# Pharo Copilot – System Documentation

## Overview
Pharo Copilot is an AI-powered completion engine for the Pharo environment that supplies context-aware code suggestions through an Ollama-backed language model. It installs as a completion engine within Pharo’s settings and can be loaded via Metacello for Pharo 13 or 14 images.【F:README.md†L6-L31】

## Architecture
The project is organized into distinct packages that separate editor integration, backend communication, configuration, and evaluation:

- **Baseline**: `BaselineOfAIPharoCopilot` defines the project baseline and assets such as the Copilot logo used by the tooling.
- **Front-End Completion Engine (`AI-Pharo-Copilot`)**: Implements the completion engine, result-set builder, and logging utilities that interface with the Pharo editor.
- **Backend & Settings (`AI-Pharo-Copilot-Ollama`)**: Provides the Ollama HTTP client, model registry/specification helpers, and centralized settings for model selection, templates, logging, and auto-install behavior.
- **Evaluator (`AI-Pharo-Copilot-Evaluator`)**: Captures acceptance/rejection metrics for suggested completions and can export evaluation reports.

These packages combine to deliver an asynchronous completion pipeline that gathers editor context, queries the Ollama model, and applies normalized completions back into the editor while logging telemetry for diagnostics.


## Visual Architecture

```
┌────────────────────────────────────────────────────────────┐
│ IDE Integration Layer                                      │
│ (Pharo editor hooks)                                       │
│  • CoCompletionEnginePharoCopilot                          │
└───────────────┬────────────────────────────────────────────┘
                │ triggers completions
┌───────────────▼────────────────────────────────────────────┐
│ Completion Workflow Layer                                  │
│ (Result building & normalization)                          │
│  • CoPharoCopilotResultSetBuilder                          │
│  • cleanedContentFrom:, applySuggestion:                   │
└───────────────┬────────────────────────────────────────────┘
                │ gathers context & builds prompts
┌───────────────▼────────────────────────────────────────────┐
│ Prompting & Backend Layer                                  │
│ (Prompt formatting, HTTP calls, model options)             │
│  • CoPromptFormatter                                       │
│  • OllamaClient (generateForPrefix:suffix:context:)        │
└───────────────┬────────────────────────────────────────────┘
                │ returns streamed model text
┌───────────────▼────────────────────────────────────────────┐
│ Observability & Evaluation Layer                           │
│ (Usage telemetry and feedback)                             │
│  • CoCopilotLogger                                         │
│  • CoSuggestionEvaluator                                   │
└────────────────────────────────────────────────────────────┘
```

The diagram shows the full lifecycle: Pharo’s editor hands control to the completion engine, which collects contextual source, formats it through the prompt formatter, and sends a fill-in-the-middle request to the Ollama backend. Responses stream back through the client, are cleaned and applied to the editor, and are recorded by both the runtime logger and the evaluator.

## Completion Pipeline
1. **Engine initialization**: `CoCompletionEnginePharoCopilot` lazily instantiates a `CoPharoCopilotResultSetBuilder`, logging whether a builder already exists before serving completions.

2. **Context capture**: `CoPharoCopilotResultSetBuilder>>buildCompletion` extracts the source prefix/suffix around the cursor, records metadata (cursor position, source length, prefix/suffix snippets), and dispatches an asynchronous process to fetch suggestions. An empty `CoResultSet` backed by a `CoCollectionFetcher` is returned immediately so the editor remains responsive.

3. **Class context harvesting**: When building the request, `classContextFor:` safely collects the active class definition plus instance/class-side method sources to provide richer context to the model.

4. **Model request**: The asynchronous worker (`processCompletionFor:prefix:suffix:contextInfo:`) logs the request, invokes `OllamaClient>>generateForPrefix:suffix:context:` to run a fill-in-the-middle prompt, and attempts to parse JSON payloads, falling back to raw text when necessary.

5. **Content normalization**: `cleanedContentFrom:` strips markdown code fences and language headers to yield raw suggestion text before applying it to the editor and logging the outcome.

6. **Application**: If content remains after normalization, the builder replaces the token in the editor and logs whether text was applied or skipped due to missing content or context.

## Ollama Backend Integration
- **Client**: `OllamaClient` wraps REST calls to Ollama. It formats generate payloads with model name, prompt, streaming flag, optional format, and options, then normalizes responses for downstream consumption.

- **Fill-in-the-middle prompts**: `generateForPrefix:suffix:context:` expands the configured template with the editor prefix/suffix/context, temporarily injects a `task: 'fill-in-the-middle'` option, and restores prior options after the call.

- **Model enumeration**: `listModels` hits the Ollama `api/tags` endpoint to discover installed models, logging the request and response for traceability.

## Configuration & Templates
`CopilotSettings` centralizes user-facing knobs such as enabling Copilot, selecting the provider/model, and managing templates and logging.

- **Auto-install flow**: If the desired model is missing, `attemptAutoInstallForModelNamed:` can trigger a scripted install, refresh available models, and update the registry; failures are logged with contextual details.

- **Model availability checks**: `ensureSelectedModelAvailable` validates Ollama connectivity and confirms the chosen model exists, optionally prompting the user to install missing models.

- **Template resolution**: `defaultFimTemplate` first looks for cached per-model templates in the logs directory, then falls back to bundled templates, raising an error if none can be found.

## Logging
`CoCopilotLogger` is responsible for structured logging across front-end and back-end events.

- **Storage**: It initializes both a general log (`copilot.log`) and an evaluation log (`copilot-evaluation-log.jsonl`) inside a managed logs directory, creating directories/files on demand.

- **Formatting**: Values are normalized for readability (strings, JSON, collections, or printable fallbacks) and appended line by line, while errors during logging are surfaced via the Transcript.

- **Event helpers**: Convenience methods log backend events, frontend events (not shown above), or errors with optional stack traces to aid debugging.

## Evaluation & Reporting
`CoSuggestionEvaluator` tracks user feedback on suggestions to surface model quality metrics.

- **Session statistics**: The evaluator tracks totals, accepted/rejected counts, and per-model/context statistics initialized at startup. 
- **Acceptance rate**: `acceptanceRate` computes accepted suggestions as a percentage of total suggestions.

- **Export & reporting**: Users can generate reports or export evaluation data to CSV with timestamps, actions, suggestion text, truncated context, model name, length, and optional rejection reasons for offline analysis.

## Installation & Activation
Install the baseline with Metacello and switch the Pharo completion engine to Copilot via Settings: `Code Browser → Code Completion → Completion Engine → Copilot`. Ensure the environment can reach the Ollama service and that the configured model is available (automatic installation can help resolve missing models).

## Operational Notes
- **Asynchronous fetching** keeps the UI responsive while completions are generated in background processes.

- **Context-rich prompts** use current class and method source to improve suggestion relevance.

- **Safety fallbacks** normalize model responses and protect against missing contexts or parsing errors to avoid editor disruption.

- **Observability** via structured logs and evaluation metrics helps diagnose backend issues and tune model performance.

## Repository Layout & Key Packages

- `src/AI-Pharo-Copilot/`: Front-end editor integration, completion engine, result-set builder, and logging helper classes.

- `src/AI-Pharo-Copilot-Ollama/`: Ollama HTTP client, template management, model registry, and user-facing settings including auto-install support.

- `src/AI-Pharo-Copilot-Evaluator/`: Evaluation and reporting utilities that track accept/reject feedback and export reports/CSVs.

- `site/`: Static site assets (e.g., `copilot.svg`) used by the completion engine UI and settings panels.

## Request Lifecycle (Step-by-Step)
1. **Editor triggers completion** via `CoCompletionEnginePharoCopilot`, which creates (or reuses) a `CoPharoCopilotResultSetBuilder` and immediately returns an empty fetcher-backed result set to avoid blocking the UI.
2. **Context collection** gathers prefix/suffix, cursor metadata, class/method source, and notebook context strings to construct a rich prompt payload.
3. **Backend call** prepares a fill-in-the-middle request by expanding the configured template and temporarily inserting `task: 'fill-in-the-middle'` into the Ollama options before sending HTTP JSON via `OllamaClient>>generateForPrefix:suffix:context:`.

4. **Response normalization** strips markdown fences, language headers, and whitespace to yield plain text snippets safe to apply in the editor.
5. **Result application** inserts the suggestion into the editor when non-empty, logging success or skips when nothing usable remains after cleaning.
6. **Evaluation logging** optionally records accept/reject actions into `copilot-evaluation-log.jsonl` along with context, timestamps, and model identifiers for later reporting.

## Configuration Reference

| Setting | Purpose | Location |
| --- | --- | --- |
| **Provider & Model** | Selects the provider (Ollama) and specific model name used for completions. | `CopilotSettings>>provider` / `selectedModel`
| **Auto-install** | Enables attempts to install missing models and refresh the registry automatically. | `CopilotSettings>>attemptAutoInstallForModelNamed:`
| **Template selection** | Controls the fill-in-the-middle prompt template resolution (cached, bundled, or error). | `CopilotSettings>>defaultFimTemplate` |
| **Logging toggle** | Determines whether structured logs are written to the Copilot logs directory. | `CopilotSettings>>loggingEnabled` & `CoCopilotLogger>>initialize` |
| **Context options** | Governs class/method context collection for richer prompts. | `CoPharoCopilotResultSetBuilder>>classContextFor:` |

## Logging & Artifacts

- **Log directory**: Created on demand inside the Copilot folder; contains `copilot.log` (runtime events) and `copilot-evaluation-log.jsonl` (accept/reject telemetry).
- **Human-readable formatting**: Strings, collections, JSON, and objects are normalized to printable forms; failures are reported via Transcript to avoid silent loss of diagnostics.
- **Evaluation exports**: CSV/JSONL exports include timestamps, actions, context excerpts, model names, lengths, and optional rejection reasons for downstream analytics.

## Template Flow

1. **Lookup**: `CopilotSettings>>defaultFimTemplate` first checks cached per-model templates in the logs directory before falling back to bundled templates, throwing an error if none are found.
2. **Formatting**: `CoPromptFormatter` fills placeholders for prefix, suffix, and optional context in the template prior to dispatching the Ollama request.
3. **Delivery**: `OllamaClient` merges the formatted prompt with user options and transient FIM options, then posts to the `/api/generate` endpoint.

## Troubleshooting

- **Model unavailable**: Run the built-in auto-install flow or refresh model tags using `CopilotSettings>>ensureSelectedModelAvailable` to validate connectivity and prompt for installation when missing.
- **Empty suggestions**: Confirm the model responds to fill-in-the-middle prompts and inspect `copilot.log` for normalization steps that may strip fenced code or language headers.
- **Slow responses**: Because requests are asynchronous, UI should remain responsive; investigate backend latency via Ollama logs and ensure network access to the service.
- **Logging disabled**: Verify `loggingEnabled` is set in `CopilotSettings`; logger initialization will skip writes otherwise.

## Extensibility Notes

- **Adding providers**: Implement a new client analogous to `OllamaClient` and extend `CopilotSettings` to register provider names/models while reusing the prompt formatter and logging facilities.
- **Custom templates**: Drop per-model templates into the logs directory to override bundled defaults without changing code; the settings lookup will prefer cached templates.
- **Alternative evaluation sinks**: Extend `CoSuggestionEvaluator` to emit additional formats (e.g., HTTP events) leveraging the existing metrics and CSV export helpers.
