# Pharo Copilot – Documentation

---

## 1. Executive Summary

AI-Pharo-Copilot is an AI-powered code completion assistant integrated directly into the Pharo Smalltalk development environment. It provides intelligent, context-aware code suggestions using Large Language Models (LLMs) running locally via Ollama, eliminating the need to send code to external servers.

### Key Features

- **Local LLM Integration**: Runs models locally via Ollama for complete privacy
- **Context-Aware Completions**: Analyzes class structure, methods, and surrounding code
- **Fill-in-the-Middle (FIM) Support**: Completes code based on prefix and suffix context
- **Real-time Evaluation**: Tracks suggestion acceptance rates and quality metrics
- **Asynchronous Processing**: Non-blocking completion fetching for smooth editing
- **Comprehensive Logging**: Detailed activity tracking for debugging and analysis
- **Auto-Installation**: Automatically pulls recommended models when missing
- **Extensive Testing**: Full test suite with mock support for reliable development

### Technology Stack

- **Language**: Pharo Smalltalk (13 & 14 compatible)
- **LLM Backend**: Ollama (local inference server)
- **Completion Framework**: Pharo's native Completion Engine
- **HTTP Client**: ZnClient (Zinc HTTP Components)
- **Persistence**: STON (Smalltalk Object Notation) and JSONL
- **Logging**: File-based logging with structured events

---

## 2. Architecture Overview

AI-Pharo-Copilot follows a layered architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                   Editor Integration                    │
│        (RubSmalltalkEditor, Completion Engine)          │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                 Completion Layer                        │
│  (CoCompletionEnginePharoCopilot, ResultSetBuilder)    │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                   Client Layer                          │
│    (OllamaClient, HTTP Transport, FIM Template)         │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                Evaluation & Logging                     │
│  (CoSuggestionEvaluator, CoCopilotLogger, Reports)      │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              Settings & Configuration                   │
│  (CopilotSettings, OModelRegistry, Model Catalog)       │
└─────────────────────────────────────────────────────────┘
```

### Package Structure

| Package | Purpose |
|---------|---------|
| **AI-Pharo-Copilot** | Core completion engine, result builder, context, and logging |
| **AI-Pharo-Copilot-Ollama** | Ollama client, HTTP transport, model registry, and settings |
| **AI-Pharo-Copilot-Evaluator** | Suggestion evaluation, metrics tracking, and reporting |
| **AI-Pharo-Copilot-Tests** | Comprehensive test suite with mock infrastructure |

---

## 3. Core Components

### 3.1 CoCompletionEnginePharoCopilot (Completion Engine)

**Location**: `src/AI-Pharo-Copilot/CoCompletionEnginePharoCopilot.class.st`

**Purpose**: The main completion engine that integrates with Pharo's editor.

**Responsibilities**:
- Provides completion builder instance
- Handles token replacement in editor
- Maintains cursor position after insertion
- Logs completion requests

**Key Methods**:

```smalltalk
CoCompletionEnginePharoCopilot >> completionBuilder
    "Returns memoized CoPharoCopilotResultSetBuilder instance"
    ^ completionBuilder ifNil: [ 
        completionBuilder := CoPharoCopilotResultSetBuilder new ]

CoCompletionEnginePharoCopilot >> replaceTokenInEditorWith: newString
    "Replaces text and maintains original cursor position"
    | originalCaretPosition |
    originalCaretPosition := self editor caret.
    super replaceTokenInEditorWith: newString.
    self editor selectAt: originalCaretPosition.
```

**Integration**:

```smalltalk
"Set as active completion engine"
RubSmalltalkEditor completionEngineClass: CoCompletionEnginePharoCopilot
```

---

### 3.2 CoPharoCopilotResultSetBuilder (Result Builder)

**Location**: `src/AI-Pharo-Copilot/CoPharoCopilotResultSetBuilder.class.st`

**Purpose**: Builds completion result sets by coordinating with Ollama and processing responses.

**Responsibilities**:
- Extracts code context (class definition, methods, prefix/suffix)
- Dispatches asynchronous completion requests
- Cleans and normalizes LLM responses
- Applies suggestions to editor

**Key Attributes**:

```smalltalk
completionContext    "The completion context from editor"
```

**Key Methods**:

```smalltalk
buildCompletion
    "Main entry point - dispatches async fetch and returns empty result set"
    
classContextFor: aContext
    "Extracts class definition and all methods for context"
    
processCompletionFor: aContext prefix: prefix suffix: suffix contextInfo: dict
    "Background worker that queries Ollama and applies result"
    
cleanedContentFrom: aString
    "Removes markdown fences and language specifiers"
```

**Process Flow**:

1. **Context Extraction**: Gathers class definition, instance methods, class methods
2. **Async Dispatch**: Forks background process at `userBackgroundPriority`
3. **API Call**: Sends request to OllamaClient with FIM template
4. **Response Cleaning**: Removes ```smalltalk fences and metadata
5. **Editor Update**: Applies cleaned suggestion to editor
6. **Logging**: Records all stages with detailed context

**Context Structure**:

```smalltalk
contextInfo := Dictionary new
    at: #contextClass put: context class name;
    at: #cursorPosition put: context position;
    at: #sourceSize put: context source size;
    at: #fullSource put: context source;
    at: #prefix put: prefix;
    at: #suffix put: suffix;
    at: #classContextLength put: classContext size;
    yourself.
```

---

### 3.3 CoPharoCopilotContext (Completion Context)

**Location**: `src/AI-Pharo-Copilot/CoPharoCopilotContext.class.st`

**Purpose**: Specialized completion context for Pharo Copilot.

**Initialization**:

```smalltalk
CoPharoCopilotContext >> initialize
    super initialize.
    completionBuilder := CoPharoCopilotResultSetBuilder 
        initializeOnContext: self
```

---

### 3.4 CoCopilotEntry (Suggestion Entry)

**Location**: `src/AI-Pharo-Copilot/CoCopilotEntry.class.st`

**Purpose**: Represents a single completion suggestion.

**Attributes**:

```smalltalk
text    "The completion text"
```

**Key Methods**:

```smalltalk
CoCopilotEntry class >> contents: aString
    "Factory method"
    ^ self new text: aString; yourself.

activateOn: aCoCompletionContext
    "Apply suggestion to editor"
    aCoCompletionContext replaceTokenInEditorWith: text

displayString
    "Truncate long suggestions for display"
    ^ text size > 120
        ifTrue: [ (text copyFrom: 1 to: 117), '…' ]
        ifFalse: [ text ]
```

---

### 3.5 CoCopilotLogger (Activity Logger)

**Location**: `src/AI-Pharo-Copilot/CoCopilotLogger.class.st`

**Purpose**: Centralized logging system for all copilot activities.

**Log Files**:
- **Activity Log**: `pharo-copilot/copilot-logs/copilot.log`
- **Evaluation Log**: `pharo-copilot/copilot-logs/copilot-evaluation-log.jsonl`

**Class Variables**:

```smalltalk
logFileReference
logsDirectoryReference
evaluationLogFileReference
```

**Key Methods**:

```smalltalk
CoCopilotLogger class >> logFrontEndEvent: eventName details: aDictionary
    "Log user-facing events"
    
CoCopilotLogger class >> logBackEndEvent: eventName details: aDictionary
    "Log backend/API events"
    
CoCopilotLogger class >> logError: eventName origin: originSymbol 
    exception: anException payload: aDictionary
    "Log errors with stack traces"
```

**Log Format**:

```
===== [FRONTEND] Preparing completion request @ 2025-01-15 14:23:45 =====
  - contextClass: CoPharoCopilotContext
  - cursorPosition: 45
  - sourceSize: 120
  - fullSource: Object subclass: #MyClass...

===== [BACKEND] Dispatching generate request @ 2025-01-15 14:23:46 =====
  - endpoint: api/generate
  - modelFullName: pharo-coder-1.5b-fim-f16.gguf:latest
  - optionsSnapshot: {"task": "fill-in-the-middle"}

===== [ERROR] Asynchronous completion failed @ 2025-01-15 14:23:50 =====
  - origin: CoPharoCopilotResultSetBuilder
  - error: Connection timeout
  - stackTrace: ...
```

**Enabling/Disabling**:

```smalltalk
CopilotSettings loggingEnabled: true.   "Enable"
CopilotSettings loggingEnabled: false.  "Disable"
```

---

## 4. Ollama Integration

### 4.1 OllamaClient (REST API Client)

**Location**: `src/AI-Pharo-Copilot-Ollama/OllamaClient.class.st`

**Purpose**: Simple client for invoking the Ollama REST API.

**Attributes**:

```smalltalk
transport    "OAHttpTransport instance"
modelSpec    "OModelSpec - current model"
stream       "Boolean - streaming mode (currently false)"
format       "Output format (optional)"
options      "Dictionary of Ollama options"
```

**Key Methods**:

```smalltalk
generate: aPromptString
    "Main API call to /api/generate endpoint"
    | payload resp normalized |
    self isNullModel ifTrue: [ ^ self class nullModelResponseString ].
    payload := Dictionary new
        at: #model put: modelSpec fullName;
        at: #prompt put: aPromptString;
        at: #stream put: stream;
        yourself.
    resp := transport postJsonAt: 'api/generate' body: payload.
    ^ self normalizeResponse: resp

generateForPrefix: prefixString suffix: suffixString context: contextString
    "Fill-in-the-middle completion"
    | prompt originalOptions response |
    prompt := self
        expandFimTemplate: CopilotSettings fimTemplate
        prefix: prefixString
        suffix: suffixString
        context: contextString.
    originalOptions := options copy.
    options at: #task put: 'fill-in-the-middle'.
    response := self generate: prompt.
    options := originalOptions.
    ^ response

listModels
    "Query available models from Ollama"
    ^ transport getJsonAt: 'api/tags'
```

**Null Model**:

When no model is configured, Copilot uses a special "null model":

```smalltalk
OllamaClient class >> nullModelFullName
    ^ 'pharo-copilot-null'

OllamaClient class >> nullModelResponseString
    ^ 'no output, please configure.'
```

---

### 4.2 OAHttpTransport (HTTP Client)

**Location**: `src/AI-Pharo-Copilot-Ollama/OAHttpTransport.class.st`

**Purpose**: Performs HTTP JSON requests against the local Ollama server.

**Attributes**:

```smalltalk
host             "Server host (default: 127.0.0.1)"
port             "Server port (default: 11434)"
defaultHeaders   "HTTP headers dictionary"
jsonReader       "STON JSON reader"
jsonWriter       "STON JSON writer"
```

**Key Methods**:

```smalltalk
postJsonAt: aPath body: aDictionary
    "POST request with JSON payload"
    | cl |
    cl := ZnClient new.
    cl accept: ZnMimeType applicationJson.
    cl contentWriter: [:data | ZnEntity json: (jsonWriter toString: data) ].
    cl host: host; port: port; path: aPath.
    cl forJsonREST.
    cl contentReader: [:entity | jsonReader fromString: entity contents ].
    cl contents: aDictionary.
    ^ cl post.

getJsonAt: aPath
    "GET request returning JSON"
    | cl |
    cl := ZnEasy client.
    cl forJsonREST; host: host; port: port; path: aPath.
    ^ cl get
```

---

### 4.3 OModelRegistry (Model Discovery)

**Location**: `src/AI-Pharo-Copilot-Ollama/OModelRegistry.class.st`

**Purpose**: Registry that builds and looks up available model specs.

**Class Variables**:

```smalltalk
current         "Singleton instance"
modelsFetcher   "Optional block to override model fetching"
```

**Attributes**:

```smalltalk
byFullName    "Dictionary of specs by full name (e.g., 'codellama:7b')"
byLabel       "Dictionary of specs by friendly label"
```

**Key Methods**:

```smalltalk
OModelRegistry class >> refresh
    "Rebuild registry from Ollama API"
    current := self new.
    current rebuild.
    ^ current

rebuild
    "Fetch models from Ollama and create specs"
    | knownSpecs nullSpec |
    byFullName := Dictionary new.
    byLabel := Dictionary new.
    knownSpecs := Dictionary new.
    
    "Collect pragmas"
    (Pragma allNamed: #ollamaModel:tag:label:) do: [ :p |
        | fam tag label spec full |
        fam := p arguments first.
        tag := p arguments second.
        label := p arguments third.
        spec := OModelSpec family: fam tag: tag label: label.
        full := spec fullName.
        knownSpecs at: full put: spec ].
    
    "Fetch from Ollama"
    [ | resp models |
        resp := self class fetchModelsResponse.
        models := resp at: #models ifAbsent: [ #() ].
        models do: [ :m |
            | name spec |
            name := m at: #name.
            spec := knownSpecs at: name ifAbsent: [
                self specFromModelName: name ].
            self addSpec: spec ]
    ] on: Error do: [ :ex | "ignore if server unreachable" ]

domainValuesForSettings
    "Returns array of label -> fullName associations for UI"
    ^ (self allSpecs collect: [ :spec | 
        spec label -> spec fullName ]) asArray
```

**Model Spec Format**:

```smalltalk
OModelSpec
    family: 'codellama'    "Base model name"
    tag: '7b'              "Size/variant tag"
    label: 'Code Llama 7B' "Human-readable label"
```

---

### 4.4 OModelSpec (Model Specification)

**Location**: `src/AI-Pharo-Copilot-Ollama/OModelSpec.class.st`

**Purpose**: Represents an Ollama model identified by family, tag, and label.

**Attributes**:

```smalltalk
family    "Base model name (e.g., 'codellama')"
tag       "Version/size tag (e.g., '7b')"
label     "Human-readable display name"
```

**Key Methods**:

```smalltalk
fullName
    "Returns family:tag format"
    ^ tag
        ifNil:  [ family ]
        ifNotNil: [ family , ':' , tag ]
```

**Example**:

```smalltalk
spec := OModelSpec 
    family: 'pharo-coder-1.5b-fim-f16.gguf' 
    tag: 'latest' 
    label: 'Pharo Coder 1.5B'.

spec fullName.  "=> 'pharo-coder-1.5b-fim-f16.gguf:latest'"
spec label.     "=> 'Pharo Coder 1.5B'"
```

---

### 4.5 OModelCatalog (Built-in Models)

**Location**: `src/AI-Pharo-Copilot-Ollama/OModelCatalog.class.st`

**Purpose**: Catalog of built-in Ollama model definitions using pragmas.

**Example Pragma**:

```smalltalk
OModelCatalog class >> pharoCopilotNull
    <ollamaModel: 'pharo-copilot-null' tag: nil label: 'Pharo Null Copilot'>
```

Custom models can be registered by adding methods with the `<ollamaModel:tag:label:>` pragma.

---

## 5. Completion Engine

### 5.1 Response Cleaning

The result builder includes sophisticated response cleaning to handle various LLM output formats:

**Markdown Fence Removal**:

```smalltalk
cleanedContentFrom: aString
    "Removes ```language fences and extracts code"
    | text start rest closingIndex body |
    text := (aString ifNil: [ '' ]) asString.
    
    "Find opening fence"
    start := text indexOfSubCollection: '```' startingAt: 1.
    start > 0 ifTrue: [
        rest := text copyFrom: start + 3 to: text size.
        closingIndex := self indexOfClosingFenceIn: rest.
        body := rest copyFrom: 1 to: closingIndex - 1.
        
        "Remove language specifier line"
        newlineIndex := body indexOf: Character lf.
        newlineIndex > 0 ifTrue: [
            firstLine := body copyFrom: 1 to: newlineIndex - 1.
            (self isLanguageSpec: firstLine) ifTrue: [
                body := body copyFrom: newlineIndex + 1 to: body size ] ].
        ^ body trimBoth ].
    
    "No fence - return up to double newline"
    idx := text indexOfSubCollection: String lf , String lf.
    body := idx = 0
        ifTrue: [ text ]
        ifFalse: [ text copyFrom: 1 to: idx - 1 ].
    ^ body trimBoth
```

**Language Specifier Detection**:

```smalltalk
isLanguageSpec: aString
    "Check if line is a language identifier"
    | trimmed |
    trimmed := aString trimBoth.
    ^ (#('smalltalk' 'pharo' 'bash' 'python' 'javascript' 'json' ...)
        includes: trimmed asLowercase)
        or: [ trimmed allSatisfy: [ :ch |
            ch isLetter or: [ ch isDigit or: [ '#+-_' includes: ch ] ] ] ]
```

---

### 5.2 Context Extraction

**Class Context Building**:

```smalltalk
classContextFor: aContext
    "Extract comprehensive class information"
    | behavior compiledMethod methodClass classDefinition instanceSide classSide |
    
    "Get behavior from context"
    behavior := (aContext respondsTo: #behavior)
        ifTrue: [ [ aContext behavior ] on: Error do: [ nil ] ]
        ifFalse: [ nil ].
    
    "Get method if available"
    compiledMethod := (aContext respondsTo: #method)
        ifTrue: [ [ aContext method ] on: Error do: [ nil ] ]
        ifFalse: [ nil ].
    
    "Determine method class"
    methodClass := behavior 
        ifNil: [ compiledMethod ifNotNil: [ compiledMethod methodClass ] ] 
        ifNotNil: [ behavior ].
    
    "Build context string"
    classDefinition := self safeDefinitionStringFor: methodClass.
    instanceSide := self methodSourcesFor: methodClass.
    classSide := self methodSourcesFor: (methodClass ifNotNil: [ methodClass class ]).
    
    ^ self
        classDefinition: classDefinition
        instanceMethods: instanceSide
        classMethods: classSide
```

**Method Sources Extraction**:

```smalltalk
methodSourcesFor: aBehavior
    "Collect all method sources from a behavior"
    aBehavior ifNil: [ ^ '' ].
    ^ String streamContents: [ :stream |
        [ (aBehavior selectors asSortedCollection) do: [ :selector |
            | source |
            source := [ aBehavior sourceCodeAt: selector ] 
                on: Error do: [ nil ].
            source ifNotNil: [
                stream
                    nextPutAll: source;
                    cr; cr ] ] ]
            on: Error do: [ ] ]
```

---

## 6. Evaluation System

### 6.1 CoSuggestionEvaluator (Metrics Tracker)

**Location**: `src/AI-Pharo-Copilot-Evaluator/CoSuggestionEvaluator.class.st`

**Purpose**: Tracks suggestion acceptance rates and generates comprehensive reports.

**Attributes**:

```smalltalk
acceptedEntries     "OrderedCollection of CoEvaluationEntry"
rejectedEntries     "OrderedCollection of CoEvaluationEntry"
sessionStats        "Dictionary of current session statistics"
persistentStats     "Dictionary of lifetime statistics"
```

**Class Methods**:

```smalltalk
CoSuggestionEvaluator class >> default
    "Singleton instance"
    ^ default ifNil: [ default := self new ]
```

**Key Methods**:

```smalltalk
recordSuggestionAccepted: aCopilotEntry context: aContext
    "Record accepted suggestion"
    | entry contextType |
    entry := CoEvaluationEntry new
        suggestion: aCopilotEntry;
        context: aContext;
        timestamp: DateAndTime now;
        action: #accepted;
        yourself.
    acceptedEntries add: entry.
    self updateSessionStats: entry.
    self announceEvaluation: entry.

recordSuggestionRejected: aCopilotEntry context: aContext reason: reasonString
    "Record rejected suggestion with reason"
    | entry |
    entry := CoEvaluationEntry new
        suggestion: aCopilotEntry;
        context: aContext;
        timestamp: DateAndTime now;
        action: #rejected;
        rejectionReason: reasonString;
        yourself.
    rejectedEntries add: entry.
    self updateSessionStats: entry.
    self announceEvaluation: entry.

acceptanceRate
    "Calculate percentage of accepted suggestions"
    | total accepted |
    total := sessionStats at: #totalSuggestions ifAbsent: [ 0 ].
    total = 0 ifTrue: [ ^ 0 ].
    accepted := sessionStats at: #totalAccepted ifAbsent: [ 0 ].
    ^ (accepted / total * 100) rounded
```

**Session Statistics Structure**:

```smalltalk
sessionStats := Dictionary new
    at: #sessionStartTime put: DateAndTime now;
    at: #totalSuggestions put: 0;
    at: #totalAccepted put: 0;
    at: #totalRejected put: 0;
    at: #modelStats put: Dictionary new;
    at: #contextStats put: Dictionary new;
    at: #lengthStats put: Dictionary new;
    yourself.
```

**Context Type Classification**:

```smalltalk
determineContextType: aContext
    "Classify the code context"
    | src |
    src := aContext source.
    (self isClassDef: src)         ifTrue: [ ^ #classDef ].
    (self isMethodDef: src)        ifTrue: [ ^ #method ].
    (self hasTopLevel: '^' in: src)    ifTrue: [ ^ #return ].
    (self hasTopLevel: ':=' in: src)   ifTrue: [ ^ #assignment ].
    (self hasAnyTopLevel: self iterationSelectors in: src)
        ifTrue: [ ^ #iteration ].
    (self hasAnyTopLevel: self conditionSelectors in: src)
        ifTrue: [ ^ #condition ].
    ^ #other
```

**Export to CSV**:

```smalltalk
exportToCSV: filename
    "Export evaluation data for external analysis"
    filename asFileReference writeStreamDo: [ :stream |
        "Header"
        stream nextPutAll: 'Timestamp,Action,Suggestion,Context,Model,Length,Reason'; lf.
        
        "Data rows"
        (acceptedEntries , rejectedEntries) do: [ :entry |
            stream 
                nextPutAll: entry timestamp asString; nextPut: $,;
                nextPutAll: entry action asString; nextPut: $,;
                nextPutAll: '"', (entry suggestion contents 
                    copyReplaceAll: '"' with: '""'), '"'; nextPut: $,;
                nextPutAll: '"', (entry context source copyFrom: 1 
                    to: (50 min: entry context source size)), '"'; nextPut: $,;
                nextPutAll: CopilotSettings modelName; nextPut: $,;
                nextPutAll: entry suggestion contents size asString; nextPut: $,;
                nextPutAll: (entry rejectionReason ifNil: [ '' ]); lf ] ]
```

---

### 6.2 CoEvaluationReport (Report Generator)

**Location**: `src/AI-Pharo-Copilot-Evaluator/CoEvaluationReport.class.st`

**Purpose**: Generates comprehensive evaluation reports.

**Report Sections**:

1. **Overview**: Total suggestions, acceptance rate, rejection rate
2. **Model Performance**: Statistics per model
3. **Context Analysis**: Acceptance rates by code context type
4. **Length Analysis**: Success rates by suggestion length
5. **Top Rejection Reasons**: Most common rejection causes
6. **Recommendations**: Actionable insights

**Example Report**:

```
=== Copilot Evaluation Report ===

OVERVIEW
--------
Session started: 2025-01-15 14:23:45
Total suggestions: 150
Accepted: 105 (70%)
Rejected: 30 (20%)
Ignored: 15

MODEL PERFORMANCE
----------------
pharo-coder-1.5b-fim-f16.gguf:latest: 105/150 accepted (70%)

CONTEXT ANALYSIS
----------------
method: 80/100 accepted (80%)
assignment: 15/25 accepted (60%)
return: 10/25 accepted (40%)

SUGGESTION LENGTH ANALYSIS
--------------------------
short suggestions: 60/75 accepted (80%)
medium suggestions: 35/50 accepted (70%)
long suggestions: 10/25 accepted (40%)

TOP REJECTION REASONS
--------------------
Incorrect syntax: 12 times
Incomplete suggestion: 8 times
Wrong method name: 5 times
Irrelevant context: 5 times

RECOMMENDATIONS
---------------
• High acceptance rate - model is performing well
• Export data to CSV for detailed analysis: CoSuggestionEvaluator default exportToCSV: 'evaluation.csv'
```

---

### 6.3 CoEvaluationEntry (Evaluation Record)

**Location**: `src/AI-Pharo-Copilot-Evaluator/CoEvaluationEntry.class.st`

**Purpose**: Represents a single evaluation record.

**Attributes**:

```smalltalk
suggestion         "CoCopilotEntry - the suggestion"
context            "CoPharoCopilotContext - code context"
timestamp          "DateAndTime - when recorded"
action             "Symbol - #accepted, #rejected, or #ignored"
rejectionReason    "String - why rejected (optional)"
metadata           "Dictionary - additional data"
```

---

### 6.4 CoEvaluationAnnouncement (Event Notification)

**Location**: `src/AI-Pharo-Copilot-Evaluator/CoEvaluationAnnouncement.class.st`

**Purpose**: Announcement broadcast when evaluations are recorded.

**Usage**:

```smalltalk
"Listen for evaluation events"
SystemAnnouncer uniqueInstance weak
    when: CoEvaluationAnnouncement
    send: #handleEvaluation:
    to: self.

handleEvaluation: anAnnouncement
    | entry |
    entry := anAnnouncement entry.
    "Process evaluation..."
```

---

## 7. Fill-in-the-Middle (FIM) Templates

### 7.1 Template System

FIM templates define how to format the prompt for models that support fill-in-the-middle completion.

**Template Placeholders**:

- `{{ .Prompt }}` or `{{.Prompt}}` - Code before cursor (prefix)
- `{{ .Suffix }}` or `{{.Suffix}}` - Code after cursor (suffix)
- `{{ .Context }}` or `{{.Context}}` - Class/method context
- `{1}`, `{2}`, `{3}` - Positional format strings (prefix, suffix, context)

**Template Expansion**:

```smalltalk
expandFimTemplate: templateString prefix: prefixString 
    suffix: suffixString context: contextString
    
    | prompt safePrefix safeSuffix safeContext includesContextPlaceholder |
    safePrefix := prefixString ifNil: [ '' ] ifNotNil: [ prefixString asString ].
    safeSuffix := suffixString ifNil: [ '' ] ifNotNil: [ suffixString asString ].
    safeContext := contextString ifNil: [ '' ] ifNotNil: [ contextString asString ].
    
    prompt := templateString ifNil: [ '' ].
    
    "Check if context placeholder exists"
    includesContextPlaceholder := (prompt includesSubstring: '{{ .Context }}')
        or: [ (prompt includesSubstring: '{{.Context}}') 
        or: [ prompt includesSubstring: '{3}' ] ].
    
    "Replace placeholders"
    prompt := prompt copyReplaceAll: '{{ .Prompt }}' with: safePrefix.
    prompt := prompt copyReplaceAll: '{{.Prompt}}' with: safePrefix.
    prompt := prompt copyReplaceAll: '{{ .Suffix }}' with: safeSuffix.
    prompt := prompt copyReplaceAll: '{{.Suffix}}' with: safeSuffix.
    prompt := prompt copyReplaceAll: '{{ .Context }}' with: safeContext.
    prompt := prompt copyReplaceAll: '{{.Context}}' with: safeContext.
    
    "Positional format"
    prompt := prompt format: { safePrefix. safeSuffix. safeContext }.
    
    "Prepend context if not in template"
    (includesContextPlaceholder not and: [ safeContext isEmpty not ]) 
        ifTrue: [ prompt := self prependContext: safeContext toPrompt: prompt ].
    
    ^ prompt
```

---

### 7.2 Template Storage

**Locations**:

1. **Bundled Templates**: `pharo-copilot/templates/` directory
2. **Cached Templates**: `pharo-copilot/copilot-logs/{model-name}/template.txt`

**Template Discovery**:

```smalltalk
CopilotSettings class >> defaultFimTemplate
    "Returns FIM template for current model"
    | template cacheFile |
    
    "Try cached template first"
    cacheFile := self templateFileForModelNamed: self modelName.
    template := self fimTemplateFromFile: cacheFile.
    template ifNotNil: [ ^ template ].
    
    "Fall back to bundled templates"
    template := self fimTemplateFromBundledTemplates.
    template ifNotNil: [ ^ template ].
    
    "Error if no template found"
    self logMissingFimTemplate.
    ^ self error: 'No fill-in-the-middle template is available 
        for the current Copilot model.'
```

**Example Template** (CodeLlama format):

```
<PRE> {{ .Prompt }} <SUF> {{ .Suffix }} <MID>
```

**Example Template** (Pharo Coder format):

```
Complete the following Smalltalk code:

Class Context:
{{ .Context }}

Code to complete:
{{ .Prompt }}<FILL>{{ .Suffix }}

Completion:
```

---

### 7.3 Model Metadata

Model metadata is fetched from Ollama and cached locally:

**Fetch Metadata**:

```smalltalk
CopilotSettings class >> fetchModelMetadata
    "Query model details from Ollama"
    | client response metadata |
    client := self newOllamaClient.
    
    [ response := client showModelNamed: self modelName.
      metadata := self populateMetadata: Dictionary new fromResponse: response.
      self saveModelMetadataToDisk: metadata forModel: self modelName.
    ] on: Error do: [ :ex |
        metadata := self nullModelMetadata ].
    
    ^ metadata
```

**Metadata Structure**:

```smalltalk
metadata := Dictionary new
    at: #model put: 'pharo-coder-1.5b-fim-f16.gguf:latest';
    at: #template put: '<PRE> {1} <SUF> {2} <MID>';
    at: #system put: 'You are a Smalltalk code completion assistant...';
    at: #parameters put: '{"temperature": 0.3, ...}';
    at: #modelfile put: 'FROM pharo-coder-1.5b-fim-f16.gguf...';
    yourself.
```

---

## 8. Installation & Setup

### 8.1 Prerequisites

1. **Pharo 13 or 14**: Download from [pharo.org](https://pharo.org)
2. **Ollama**: Install from [ollama.com](https://ollama.com)
3. **Git** (optional): For cloning repository

---

### 8.2 Installation

**Option 1: Metacello (Recommended)**

```smalltalk
"Latest stable release"
Metacello new
    repository: 'github://omarabedelkader/Pharo-Copilot:main/src';
    baseline: 'PharoCopilot';
    load.

**Option 2: Manual Loading**

```smalltalk
"Clone repository and load packages"
repo := IceRepositoryCreator new
    location: '/path/to/pharo-copilot';
    createRepository.

"Load packages in order"
#(
    'AI-Pharo-Copilot'
    'AI-Pharo-Copilot-Ollama'
    'AI-Pharo-Copilot-Evaluator'
    'AI-Pharo-Copilot-Tests'
) do: [ :pkgName |
    Metacello new
        baseline: pkgName;
        repository: 'gitlocal:///path/to/pharo-copilot';
        load ].
```

---

### 8.3 Ollama Setup

**1. Install Ollama**

```bash
# macOS/Linux
curl https://ollama.ai/install.sh | sh

# Windows
# Download installer from ollama.com
```

**2. Start Ollama Service**

```bash
ollama serve
```

**3. Pull Recommended Model**

```bash
# Recommended for Pharo
ollama pull pharo-coder-1.5b-fim-f16.gguf:latest

# Alternative: CodeLlama
ollama pull codellama:7b
```

**4. Verify Installation**

```bash
# List installed models
ollama list

# Test model
ollama run pharo-coder-1.5b-fim-f16.gguf:latest "Hello"
```

---

### 8.4 Initial Configuration

**1. Enable Copilot Engine**

```smalltalk
"Set as active completion engine"
RubSmalltalkEditor completionEngineClass: CoCompletionEnginePharoCopilot.

"Verify"
RubSmalltalkEditor completionEngineClass.
"=> CoCompletionEnginePharoCopilot"
```

**2. Configure Settings**

```smalltalk
"Enable copilot"
CopilotSettings copilotEnabled: true.

"Set provider"
CopilotSettings copilotProvider: #ollama.

"Select model"
CopilotSettings modelName: 'pharo-coder-1.5b-fim-f16.gguf:latest'.

"Configure host/port (defaults: 127.0.0.1:11434)"
CopilotSettings host: '127.0.0.1'.
CopilotSettings port: 11434.

"Enable logging"
CopilotSettings loggingEnabled: true.

"Enable auto-install"
CopilotSettings autoInstallModelScriptEnabled: true.
```

**3. Test Connection**

```smalltalk
"Verify Ollama is reachable"
client := OllamaClient new.
models := client listModels.
models inspect.

"Test generation"
client generate: 'Hello, world!'.
```

---

### 8.5 System Settings UI

Access settings through Pharo's Settings Browser:

1. Open **Settings Browser**: `Settings > System Settings`
2. Navigate to **Code Browsing > Copilot**
3. Configure:
   - **Provider**: Select `ollama`
   - **Model**: Choose from dropdown (auto-populated from Ollama)
   - **Enable logging**: Check to enable activity logs
   - **Auto-install model**: Check to auto-pull recommended model
   - **Server host**: Default `127.0.0.1`
   - **Server port**: Default `11434`

---

## 9. Usage Guide

### 9.1 Basic Completion

**1. Open a Browser/Playground**

```smalltalk
"Open System Browser"
Smalltalk tools browser open.

"Or Playground"
Smalltalk tools playground open.
```

**2. Start Typing Code**

```smalltalk
Object subclass: #MyClass
    instanceVariableNames: 'name age'
    classVariableNames: ''
    package: 'MyPackage'

MyClass >> initialize
    super initialize.
    "Place cursor here and wait for suggestions"
```

**3. Accept Suggestion**

- Suggestion appears automatically after brief pause
- Press **Tab** to accept
- Press **Esc** to reject
- Continue typing to ignore

---

### 9.2 Context-Aware Completion

Copilot provides better suggestions with more context:

**Example 1: Method Completion**

```smalltalk
"Given class:"
Person >> initialize
    super initialize.
    name := ''.
    age := 0.

"Type this:"
Person >> description
    "Copilot suggests:"
    ^ String streamContents: [ :s |
        s nextPutAll: 'Person: '.
        s nextPutAll: name.
        s nextPutAll: ', Age: '.
        s nextPutAll: age asString ]
```

**Example 2: Iterating Collections**

```smalltalk
"Type this:"
collection := #(1 2 3 4 5).
collection collect: [ :each | 
    "Copilot suggests:"
    each squared ]
```

**Example 3: Conditional Logic**

```smalltalk
"Type this:"
value ifNil: [ 
    "Copilot suggests:"
    ^ self defaultValue ]
ifNotNil: [ :v |
    ^ v + 1 ]
```

---

### 9.3 Fill-in-the-Middle

Copilot uses FIM to complete code in the middle of a method:

```smalltalk
"Before cursor:"
MyClass >> processData
    | result |
    result := data collect: [ :item | item * 2 ].
    "Place cursor here"

"After cursor:"
    ^ result

"Copilot suggests between lines:"
    result := result select: [ :each | each > 10 ].
```

---

### 9.4 Evaluation & Feedback

**Track Your Usage**:

```smalltalk
"View session statistics"
CoSuggestionEvaluator default sessionStats inspect.

"Generate report"
report := CoSuggestionEvaluator default generateReport.
report inspect.

"Export to CSV"
CoSuggestionEvaluator default exportToCSV: 'copilot-evaluation.csv'.

"Check acceptance rate"
CoSuggestionEvaluator default acceptanceRate.
"=> 75"
```

**Manual Rejection**:

```smalltalk
"If you want to explicitly mark a suggestion as rejected"
entry := CoCopilotEntry contents: 'bad suggestion'.
context := CoPharoCopilotContext new.
CoSuggestionEvaluator default
    recordSuggestionRejected: entry
    context: context
    reason: 'Incorrect syntax'.
```

---

### 9.5 Viewing Logs

**Activity Log**:

```smalltalk
"Open log file"
logFile := CoCopilotLogger logFileReference.
logFile exists ifTrue: [ 
    logFile openWithShell ].

"Or inspect contents"
logFile contents inspect.
```

**Evaluation Log (JSONL)**:

```smalltalk
"Open evaluation log"
evalLog := CoCopilotLogger evaluationLogFileReference.
evalLog exists ifTrue: [
    evalLog openWithShell ].

"Parse JSON lines"
lines := evalLog contents lines.
entries := lines collect: [ :line |
    STONJSON fromString: line ].
entries inspect.
```

---

## 10. Configuration & Settings

### 10.1 CopilotSettings (Global Configuration)

**Location**: `src/AI-Pharo-Copilot-Ollama/CopilotSettings.class.st`

**Class Variables**:

```smalltalk
Enabled                        "Boolean - enable/disable copilot"
Provider                       "Symbol - backend provider (#ollama)"
ModelName                      "String - selected model full name"
Host                           "String - Ollama server host"
Port                           "Integer - Ollama server port"
ModelMetadata                  "Dictionary - cached model info"
OllamaClientFactory            "Block - factory for creating clients"
AutoInstallModelScriptEnabled  "Boolean - auto-pull missing models"
LoggingEnabled                 "Boolean - enable activity logging"
TemplatesDirectory             "FileReference - FIM templates location"
```

**Key Methods**:

```smalltalk
CopilotSettings class >> copilotEnabled
    "Check if copilot is enabled"
    ^ Enabled ifNil: [ Enabled := true ].

CopilotSettings class >> copilotEnabled: aBool
    "Enable/disable copilot"
    Enabled := aBool.

CopilotSettings class >> modelName
    "Get current model name"
    ^ ModelName ifNil: [ ModelName := OllamaClient defaultModelFullName ]

CopilotSettings class >> modelName: aString
    "Set model and clear cached metadata"
    ModelName := aString.
    self clearCachedModelMetadata.

CopilotSettings class >> availableModelNames
    "Returns array of label->fullName pairs for UI"
    ^ OModelRegistry refresh domainValuesForSettings

CopilotSettings class >> newOllamaClient
    "Create new Ollama client instance"
    ^ self ollamaClientFactory value
```

---

### 10.2 Model Auto-Installation

When configured model is missing, Copilot can automatically pull it from Ollama:

**Configuration**:

```smalltalk
"Enable auto-install for recommended model"
CopilotSettings autoInstallModelScriptEnabled: true.
```

**Auto-Install Process**:

```smalltalk
CopilotSettings class >> attemptAutoInstallForModelNamed: modelName 
    usingInitialResponse: response
    
    "Check if auto-install is enabled and model is recommended"
    (self shouldAutoInstallModelNamed: modelName) ifFalse: [ ^ false ].
    
    "Log attempt"
    CoCopilotLogger
        logBackEndEvent: 'Attempting auto-install for missing Ollama model'
        details: (Dictionary new
            at: #model put: modelName;
            at: #availableModelsBefore put: (self modelNamesFromResponse: response);
            yourself).
    
    "Run install script"
    (self installModelNamed: modelName) ifFalse: [ ^ false ].
    
    "Verify model is now available"
    [ | refreshedResponse refreshedModels |
        refreshedResponse := self newOllamaClient listModels.
        refreshedModels := self modelNamesFromResponse: refreshedResponse.
        (refreshedModels includes: modelName) ifTrue: [
            OModelRegistry refresh.
            ^ true ].
    ] on: Error do: [ :ex | self logError: ex ].
    
    ^ false
```

**Recommended Model**:

```smalltalk
CopilotSettings class >> shouldAutoInstallModelNamed: modelName
    (self autoInstallModelScriptEnabled) ifFalse: [ ^ false ].
    modelName ifNil: [ ^ false ].
    ^ modelName = 'pharo-coder-1.5b-fim-f16.gguf:latest'
```

---

### 10.3 Custom Client Factory

For testing or custom backends, override the client factory:

```smalltalk
"Use mock client for testing"
CopilotSettings ollamaClientFactory: [ MockOllamaClient new ].

"Restore default"
CopilotSettings ollamaClientFactory: [ OllamaClient new ].
```

---

### 10.4 Settings Snapshot & Restore

**Snapshot Current Settings**:

```smalltalk
snapshot := CopilotSettings settingsSnapshot.
"=> Dictionary with all settings"
```

**Restore Settings**:

```smalltalk
CopilotSettings restoreSettingsFromSnapshot: snapshot.
```

**Temporary Settings**:

```smalltalk
"Execute block with default settings"
CopilotSettings withDefaultSettingsDo: [
    "Your code here - settings are reset"
    client := OllamaClient new.
    client generate: 'test prompt' ].

"Settings restored automatically after block"
```

---

## 11. Extension Points

### 11.1 Custom Models

**Register Model via Pragma**:

```smalltalk
MyModelCatalog class >> myCustomModel
    <ollamaModel: 'mycustom' tag: 'v1' label: 'My Custom Model'>
```

**After registration**:

```smalltalk
"Refresh registry to pick up new pragmas"
OModelRegistry refresh.

"Model appears in settings dropdown"
CopilotSettings availableModelNames.
"=> includes: 'My Custom Model' -> 'mycustom:v1'"
```

---

### 11.2 Custom FIM Templates

**Create Template File**:

```
pharo-copilot/templates/mycustom-v1-template.txt
```

**Template Content**:

```
<|fim_prefix|>{{ .Prompt }}<|fim_suffix|>{{ .Suffix }}<|fim_middle|>
```

**Or provide via code**:

```smalltalk
"Override template method"
CopilotSettings class >> fimTemplateForModel: modelName
    modelName = 'mycustom:v1' ifTrue: [
        ^ '<|fim_prefix|>{1}<|fim_suffix|>{2}<|fim_middle|>' ].
    ^ super fimTemplateForModel: modelName
```

---

### 11.3 Custom Result Processing

**Subclass Result Builder**:

```smalltalk
CoPharoCopilotResultSetBuilder subclass: #MyCustomResultSetBuilder
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'MyExtension'

MyCustomResultSetBuilder >> cleanedContentFrom: aString
    "Custom cleaning logic"
    | cleaned |
    cleaned := super cleanedContentFrom: aString.
    
    "Additional processing"
    cleaned := self removeComments: cleaned.
    cleaned := self formatCode: cleaned.
    
    ^ cleaned
```

**Use Custom Builder**:

```smalltalk
CoPharoCopilotContext >> initialize
    super initialize.
    completionBuilder := MyCustomResultSetBuilder initializeOnContext: self
```

---

### 11.4 Evaluation Listeners

**Subscribe to Evaluation Events**:

```smalltalk
Object subclass: #MyEvaluationListener
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'MyExtension'

MyEvaluationListener >> initialize
    super initialize.
    SystemAnnouncer uniqueInstance weak
        when: CoEvaluationAnnouncement
        send: #handleEvaluation:
        to: self.

MyEvaluationListener >> handleEvaluation: anAnnouncement
    | entry |
    entry := anAnnouncement entry.
    
    entry action = #accepted ifTrue: [
        "Log accepted suggestion to external service"
        self logToExternalService: entry ].
    
    entry action = #rejected ifTrue: [
        "Analyze rejection for improvement"
        self analyzeRejection: entry ]
```

---

## 12. Troubleshooting

### 12.1 Common Issues

**Issue 1: "Ollama service unavailable"**

**Symptoms**: No completions, error in log

**Checks**:

```bash
# Verify Ollama is running
ps aux | grep ollama

# Test API
curl http://127.0.0.1:11434/api/tags

# Check port
lsof -i :11434
```

**Solutions**:

```bash
# Start Ollama
ollama serve

# Or restart service
pkill ollama && ollama serve
```

---

**Issue 2: "Model not found"**

**Symptoms**: Error message, null model fallback

**Checks**:

```bash
# List installed models
ollama list

# Check if model exists in Ollama
ollama show pharo-coder-1.5b-fim-f16.gguf:latest
```

**Solutions**:

```bash
# Pull missing model
ollama pull pharo-coder-1.5b-fim-f16.gguf:latest

# Or enable auto-install
```

```smalltalk
CopilotSettings autoInstallModelScriptEnabled: true.
```

---

**Issue 3: "No completions appearing"**

**Checks**:

```smalltalk
"Verify copilot is enabled"
CopilotSettings copilotEnabled.

"Check completion engine"
RubSmalltalkEditor completionEngineClass.
"Should be: CoCompletionEnginePharoCopilot"

"Test client manually"
client := OllamaClient new.
client generate: 'test'.
```

**Solutions**:

```smalltalk
"Enable copilot"
CopilotSettings copilotEnabled: true.

"Set correct engine"
RubSmalltalkEditor completionEngineClass: CoCompletionEnginePharoCopilot.

"Refresh model registry"
OModelRegistry refresh.
```

---

**Issue 4: "Slow completions"**

**Checks**:

```smalltalk
"Check if large context is being sent"
CoCopilotLogger logFileReference contents inspect.
"Look for 'classContextLength' in logs"
```

**Solutions**:

```bash
# Use smaller, faster model
ollama pull codellama:7b  # Instead of 34b

# Or use quantized model
ollama pull pharo-coder-1.5b-fim-f16.gguf:latest  # Optimized
```

```smalltalk
"Reduce context size (future enhancement)"
"Currently sends all methods - consider filtering"
```

---

**Issue 5: "Template not found"**

**Symptoms**: Error about missing FIM template

**Checks**:

```smalltalk
"Check template file"
CopilotSettings templateFileForModelNamed: CopilotSettings modelName.
"Check if file exists"

"Check bundled templates"
CopilotSettings templatesDirectory entries inspect.
```

**Solutions**:

```smalltalk
"Fetch metadata to create cached template"
CopilotSettings fetchModelMetadata.

"Or create template manually"
templateFile := CopilotSettings templateFileForModelNamed: CopilotSettings modelName.
templateFile parent ensureCreateDirectory.
templateFile writeStreamDo: [ :s |
    s nextPutAll: '<PRE> {1} <SUF> {2} <MID>' ].
```

---

### 12.2 Debugging

**Enable Verbose Logging**:

```smalltalk
"Ensure logging is enabled"
CopilotSettings loggingEnabled: true.

"Check log location"
CoCopilotLogger logFileReference fullName.
"=> '/path/to/pharo-copilot/copilot-logs/copilot.log'"

"Tail log file"
CoCopilotLogger logFileReference contents inspect.
```

**Inspect Internal State**:

```smalltalk
"Check settings"
CopilotSettings settingsSnapshot inspect.

"Check current model"
client := OllamaClient new.
client instVarNamed: 'modelSpec'.

"Check evaluator stats"
CoSuggestionEvaluator default sessionStats inspect.

"Check registry"
OModelRegistry current allSpecs inspect.
```

**Manual Completion Test**:

```smalltalk
"Create mock context"
context := CoPharoCopilotContext new.
context source: 'Object subclass: #Test'.

"Build completion manually"
builder := CoPharoCopilotResultSetBuilder new.
builder initializeOnContext: context.

"Extract context"
classContext := builder classContextFor: context.
classContext inspect.

"Test with client"
client := OllamaClient new.
response := client generateForPrefix: 'Object >> test' suffix: '' context: classContext.
response inspect.
```

---

### 12.3 Reset & Clean Start

**Reset Settings to Default**:

```smalltalk
CopilotSettings resetToDefaultSettings.
```

**Clear Caches**:

```smalltalk
"Clear model metadata cache"
CopilotSettings clearCachedModelMetadata.

"Reset model registry"
OModelRegistry reset.
OModelRegistry refresh.

"Reset evaluator"
CoSuggestionEvaluator reset.
```

**Delete Logs**:

```smalltalk
"Delete activity log"
CoCopilotLogger logFileReference delete.

"Delete evaluation log"
CoCopilotLogger evaluationLogFileReference delete.

"Re-initialize logger"
CoCopilotLogger initialize.
```

---

## 13. Testing Suite

### 13.1 Test Organization

**Test Packages**:

- **AI-Pharo-Copilot-Tests**: Main test suite
- **AI-Pharo-Copilot-Tests-Mock**: Mock infrastructure

**Test Categories**:

1. **Unit Tests**: Component-level testing
2. **Integration Tests**: Cross-component workflows
3. **Regression Tests**: Prevent known issues
4. **Usability Tests**: User experience validation
5. **Stress Tests**: Performance and scalability
6. **Advanced Tests**: Complex evaluation scenarios

---

### 13.2 Mock Infrastructure

**CopilotMockModelTestCase**:

Base test case that sets up mock models:

```smalltalk
CopilotMockModelTestCase >> setUp
    super setUp.
    mockContext := OTestModelSupport beginMockModels.

CopilotMockModelTestCase >> tearDown
    [ super tearDown ] ensure: [
        OTestModelSupport endMockModels: mockContext.
        mockContext := nil ].
```

**OTestModelSupport**:

Utility class for mock model management:

```smalltalk
OTestModelSupport class >> beginMockModels
    "Setup mock models for testing"
    | context originalFetcher |
    context := Dictionary new.
    
    "Save original fetcher"
    originalFetcher := OModelRegistry modelsFetcher.
    context at: #originalFetcher put: originalFetcher.
    
    "Install mock fetcher"
    OModelRegistry modelsFetcher: [
        self mockModelsResponse ].
    
    "Refresh registry with mocks"
    OModelRegistry refresh.
    
    ^ context

OTestModelSupport class >> endMockModels: context
    "Restore original state"
    | originalFetcher |
    originalFetcher := context at: #originalFetcher ifAbsent: [ nil ].
    OModelRegistry modelsFetcher: originalFetcher.
    OModelRegistry refresh.

OTestModelSupport class >> mockModelsResponse
    "Returns mock models list"
    ^ Dictionary new
        at: #models put: #(
            #{ #name -> 'mock:model' }
            #{ #name -> 'test:7b' }
        );
        yourself
```

---

### 13.3 Key Test Classes

**OAHttpTransportTest**:

Tests HTTP transport layer:

```smalltalk
testDefaultHostAndPort
    | transport |
    transport := OAHttpTransport new.
    self assert: transport host equals: '127.0.0.1'.
    self assert: transport port equals: 11434.

testJsonReaderWriterInitialization
    | transport |
    transport := OAHttpTransport new.
    self assert: transport jsonReader notNil.
    self assert: transport jsonWriter notNil.
```

**CopilotSettingsValidationTest**:

Tests settings validation:

```smalltalk
testModelNameWithInvalidValues
    | old longName |
    old := CopilotSettings modelName.
    [
        "Empty string should not crash"
        CopilotSettings modelName: ''.
        self assert: CopilotSettings modelName equals: ''.
        
        "Long name"
        longName := String new: 1000 withAll: $m.
        CopilotSettings modelName: longName.
        self assert: CopilotSettings modelName equals: longName.
    ] ensure: [ CopilotSettings modelName: old ]
```

**UsabilityTest**:

Tests user experience:

```smalltalk
testEntryDisplayStringIsInformative
    | shortEntry longEntry |
    shortEntry := CoCopilotEntry contents: 'def method'.
    longEntry := CoCopilotEntry contents: (String new: 200 withAll: $x).
    
    "Short content shown completely"
    self assert: shortEntry displayString equals: 'def method'.
    
    "Long content truncated with indicator"
    self assert: longEntry displayString size < 200.
    self assert: (longEntry displayString endsWith: '…').

testAvailableModelNamesAreUserFriendly
    | modelNames |
    modelNames := CopilotSettings availableModelNames.
    modelNames do: [ :assoc |
        "Keys should be human-readable labels"
        self assert: assoc key isString.
        self deny: assoc key isEmpty.
        "Labels should be more readable than identifiers"
        self deny: assoc key equals: assoc value ]
```

**RegressionTest**:

Tests for known issues:

```smalltalk
testCleanedContentFromDoesNotAlterOriginalString
    | builder original result |
    builder := CoPharoCopilotResultSetBuilder new.
    original := '```smalltalk', String lf, 'original code', String lf, '```'.
    result := builder cleanedContentFrom: original.
    
    "Original unchanged"
    self assert: (original includesSubstring: '```smalltalk').
    self assert: result equals: 'original code'.

testDefaultModelConsistency
    | defaultModel client1 client2 |
    defaultModel := OllamaClient defaultModelFullName.
    client1 := OllamaClient new.
    client2 := OllamaClient new.
    
    "Both clients use same model"
    self assert: (client1 instVarNamed: 'modelSpec') fullName equals: defaultModel.
    self assert: (client2 instVarNamed: 'modelSpec') fullName 
        equals: (client1 instVarNamed: 'modelSpec') fullName.
```

**CoSuggestionEvaluatorAdvancedTest**:

Tests evaluation system:

```smalltalk
testComplexEvaluationScenario
    | evaluator context suggestions lengthStats |
    evaluator := CoSuggestionEvaluator new.
    context := CoPharoCopilotContext new.
    
    "Create variety of suggestions"
    suggestions := {
        CoCopilotEntry contents: 'short'.
        CoCopilotEntry contents: (String new: 30 withAll: $m).
        CoCopilotEntry contents: (String new: 100 withAll: $l) }.
    
    "Record actions"
    evaluator recordSuggestionAccepted: suggestions first context: context.
    evaluator recordSuggestionIgnored: suggestions second context: context.
    evaluator recordSuggestionAccepted: suggestions third context: context.
    
    "Verify statistics"
    self assert: (evaluator sessionStats at: #totalSuggestions) equals: 3.
    self assert: (evaluator sessionStats at: #totalAccepted) equals: 2.
    self assert: evaluator acceptanceRate equals: 67.
```

**OModelRegistryStressTest**:

Tests scalability:

```smalltalk
testMassiveModelRegistry
    | registry |
    registry := OModelRegistry new.
    
    1 to: 100 do: [:i |
        | spec |
        spec := OModelSpec
            family: ('model', i asString)
            tag:    ('v', i asString)
            label:  ('Model ', i asString).
        registry addSpec: spec ].
    
    self assert: registry byFullName size equals: 100.
    self assert: registry byLabel size equals: 100.
    self assert: registry allSpecs size equals: 100.
```

---

### 13.4 Running Tests

**Run All Tests**:

```smalltalk
"Run all copilot tests"
testRunner := TestRunner new.
testRunner selectPackage: 'AI-Pharo-Copilot-Tests'.
testRunner runAll.

"Or use SUnit"
(TestCase allSubclasses select: [ :tc |
    tc category includesSubstring: 'Copilot' ]) do: [ :tc |
        tc suite run ].
```

**Run Specific Test Class**:

```smalltalk
"Run single test class"
UsabilityTest suite run.

"Run specific test"
UsabilityTest new testEntryDisplayStringIsInformative.
```

**CI Integration**:

```bash
# Run tests from command line
pharo Pharo.image test --junit-xml-output 'AI-Pharo-Copilot-Tests'
```

---

## Appendix A: Class Reference

### Core Package (AI-Pharo-Copilot)

| Class | Purpose |
|-------|---------|
| **CoCompletionEnginePharoCopilot** | Main completion engine integration |
| **CoPharoCopilotResultSetBuilder** | Builds completion result sets |
| **CoPharoCopilotContext** | Specialized completion context |
| **CoCopilotEntry** | Single completion suggestion |
| **CoCopilotLogger** | Centralized activity logging |

### Ollama Package (AI-Pharo-Copilot-Ollama)

| Class | Purpose |
|-------|---------|
| **OllamaClient** | REST API client for Ollama |
| **OAHttpTransport** | HTTP transport layer |
| **CopilotSettings** | Global configuration |
| **OModelRegistry** | Model discovery and management |
| **OModelSpec** | Model specification |
| **OModelCatalog** | Built-in model definitions |

### Evaluator Package (AI-Pharo-Copilot-Evaluator)

| Class | Purpose |
|-------|---------|
| **CoSuggestionEvaluator** | Tracks suggestion metrics |
| **CoEvaluationReport** | Generates evaluation reports |
| **CoEvaluationEntry** | Single evaluation record |
| **CoEvaluationAnnouncement** | Evaluation event notification |

### Test Package (AI-Pharo-Copilot-Tests)

| Class | Purpose |
|-------|---------|
| **CopilotMockModelTestCase** | Base test with mock setup |
| **OTestModelSupport** | Mock infrastructure utilities |
| **OAHttpTransportTest** | Tests HTTP transport |
| **CopilotSettingsValidationTest** | Tests settings validation |
| **UsabilityTest** | Tests user experience |
| **RegressionTest** | Tests for known issues |
| **CoSuggestionEvaluatorAdvancedTest** | Tests evaluation system |
| **OModelRegistryStressTest** | Tests scalability |

---

## Appendix B: Configuration Files

### Directory Structure

```
pharo-image-directory/
├── pharo-copilot/
│   ├── templates/                    # FIM templates
│   │   ├── codellama-7b-template.txt
│   │   ├── pharo-coder-template.txt
│   │   └── ...
│   └── copilot-logs/                 # Activity logs
│       ├── copilot.log               # Main activity log
│       ├── copilot-evaluation-log.jsonl  # Evaluation data
│       └── {model-name}/             # Per-model metadata
│           ├── template.txt
│           ├── system.txt
│           ├── parameters.txt
│           └── modelfile.txt
```

### Log File Formats

**Activity Log** (`copilot.log`):

```
===== [FRONTEND] Preparing completion request @ 2025-01-15 14:23:45 =====
  - contextClass: CoPharoCopilotContext
  - cursorPosition: 45
  - sourceSize: 120

===== [BACKEND] Dispatching generate request @ 2025-01-15 14:23:46 =====
  - endpoint: api/generate
  - modelFullName: pharo-coder-1.5b-fim-f16.gguf:latest
```

---

## Appendix C: API Reference

### Quick Reference

**Enable Copilot**:
```smalltalk
RubSmalltalkEditor completionEngineClass: CoCompletionEnginePharoCopilot.
CopilotSettings copilotEnabled: true.
```

**Configure Model**:
```smalltalk
CopilotSettings modelName: 'pharo-coder-1.5b-fim-f16.gguf:latest'.
```

**Test Connection**:
```smalltalk
OllamaClient new listModels.
```

**View Statistics**:
```smalltalk
CoSuggestionEvaluator default sessionStats inspect.
CoSuggestionEvaluator default generateReport inspect.
```

**Export Data**:
```smalltalk
CoSuggestionEvaluator default exportToCSV: 'evaluation.csv'.
```

**View Logs**:
```smalltalk
CoCopilotLogger logFileReference openWithShell.
```

---

## Contributors

- Omar AbedelKader - Original author and maintainer

## License

MIT License - See LICENSE file

## Repository

https://github.com/omarabedelkader/Pharo-Copilot

---

## Acknowledgments

- **Pharo Community** - For the robust Smalltalk environment
- **Ollama Team** - For making local LLMs accessible
- **All Contributors** - For testing and feedback

---

**Document Version**: 1.0  
**Last Updated**: January 2026  
**Compatible with**: Pharo 13, Pharo 14, Ollama 0.1.0+

---