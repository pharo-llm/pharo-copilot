"
Minimal, class-side configuration for Pharo Copilot.

Only what's actually needed for the core loop:
  - enabled flag
  - Ollama host/port/model
  - FIM template loading (file-based or inline)
  - Generation options (temperature, top_p, ..., num_predict)
  - Debounce + suggestion count
"
Class {
	#name : 'CopilotSettings',
	#superclass : 'Object',
	#classInstVars : [
		'enabled',
		'modelName',
		'host',
		'port',
		'fimTemplateString',
		'templatesDirectory',
		'completionDebounceMilliseconds',
		'requestTimeoutSeconds',
		'temperature',
		'topP',
		'topK',
		'numPredict',
		'numCtx',
		'minimumPrefixLength',
		'completionSuggestionsCount',
		'backgroundColor'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'class initialization' }
CopilotSettings class >> initialize [

	super initialize.
	self initializeDefaults
]

{ #category : 'class initialization' }
CopilotSettings class >> initializeDefaults [

	enabled := true.
	modelName := 'qwen2.5-coder:1.5b-base'.
	host := '127.0.0.1'.
	port := 11434.
	fimTemplateString := nil. "nil => use Ollama native FIM (prompt + suffix fields)"
	templatesDirectory := (FileLocator imageDirectory / 'pharo-copilot' / 'templates') asFileReference.
	completionDebounceMilliseconds := 200.
	requestTimeoutSeconds := 300.
	temperature := 0.2.
	topP := 0.9.
	topK := 40.
	numPredict := 128.
	numCtx := 4096.
	minimumPrefixLength := 1.
	completionSuggestionsCount := 1.
	backgroundColor := Color darkGray
]

{ #category : 'accessing' }
CopilotSettings class >> copilotEnabled [

	^ enabled ifNil: [ enabled := true ]
]

{ #category : 'accessing' }
CopilotSettings class >> copilotEnabled: aBoolean [

	enabled := aBoolean
]

{ #category : 'accessing' }
CopilotSettings class >> host [

	^ host ifNil: [ host := '127.0.0.1' ]
]

{ #category : 'accessing' }
CopilotSettings class >> host: aString [

	host := aString
]

{ #category : 'accessing' }
CopilotSettings class >> port [

	^ port ifNil: [ port := 11434 ]
]

{ #category : 'accessing' }
CopilotSettings class >> port: anInteger [

	port := anInteger
]

{ #category : 'accessing' }
CopilotSettings class >> modelName [

	^ modelName ifNil: [ modelName := 'qwen2.5-coder:1.5b-base' ]
]

{ #category : 'accessing' }
CopilotSettings class >> modelName: aString [

	modelName := aString
]

{ #category : 'accessing' }
CopilotSettings class >> requestTimeoutSeconds [

	^ requestTimeoutSeconds ifNil: [ requestTimeoutSeconds := 300 ]
]

{ #category : 'accessing' }
CopilotSettings class >> completionDebounceMilliseconds [

	^ completionDebounceMilliseconds ifNil: [ completionDebounceMilliseconds := 200 ]
]

{ #category : 'accessing' }
CopilotSettings class >> completionDebounceMilliseconds: anInteger [

	completionDebounceMilliseconds := anInteger
]

{ #category : 'accessing' }
CopilotSettings class >> completionSuggestionsCount [

	^ completionSuggestionsCount ifNil: [ completionSuggestionsCount := 1 ]
]

{ #category : 'accessing' }
CopilotSettings class >> completionSuggestionsCount: anInteger [

	completionSuggestionsCount := anInteger
]

{ #category : 'accessing' }
CopilotSettings class >> minimumPrefixLength [

	^ minimumPrefixLength ifNil: [ minimumPrefixLength := 1 ]
]

{ #category : 'accessing' }
CopilotSettings class >> minimumPrefixLength: anInteger [

	minimumPrefixLength := anInteger
]

{ #category : 'accessing' }
CopilotSettings class >> backgroundColor [

	^ backgroundColor ifNil: [ backgroundColor := Color darkGray ]
]

{ #category : 'accessing' }
CopilotSettings class >> backgroundColor: aColor [

	backgroundColor := aColor
]

{ #category : 'ollama - options' }
CopilotSettings class >> allOllamaOptions [
	"Options dictionary sent to Ollama's /api/generate."

	| options |
	options := Dictionary new.
	temperature ifNotNil: [ options at: #temperature put: temperature ].
	topP          ifNotNil: [ options at: #top_p       put: topP ].
	topK          ifNotNil: [ options at: #top_k       put: topK ].
	numPredict    ifNotNil: [ options at: #num_predict put: numPredict ].
	numCtx        ifNotNil: [ options at: #num_ctx     put: numCtx ].
	^ options
]

{ #category : 'fim-template' }
CopilotSettings class >> fimTemplate [
	"Return the FIM template string to use, or nil to let the client
	 fall back to Ollama's native FIM API (prompt + suffix fields).

	 Priority:
	   1. Inline template set via #fimTemplate:
	   2. Bundled file: <templatesDirectory>/<model>/template.txt
	   3. Bundled file: <templatesDirectory>/template.txt
	   4. nil (native FIM)"

	| directory modelDir topLevel |
	fimTemplateString ifNotNil: [
		(fimTemplateString asString trimBoth isEmpty) ifFalse: [
			^ fimTemplateString asString ] ].

	directory := self templatesDirectory.
	directory ifNil: [ ^ nil ].
	directory exists ifFalse: [ ^ nil ].

	modelDir := directory / (self sanitizedFileComponentFor: self modelName) / 'template.txt'.
	(modelDir exists and: [ modelDir isFile ]) ifTrue: [
		^ [ modelDir readStreamDo: [ :s | s contents ] ]
			on: Error do: [ nil ] ].

	topLevel := directory / 'template.txt'.
	(topLevel exists and: [ topLevel isFile ]) ifTrue: [
		^ [ topLevel readStreamDo: [ :s | s contents ] ]
			on: Error do: [ nil ] ].

	^ nil
]

{ #category : 'fim-template' }
CopilotSettings class >> fimTemplate: aString [
	"Set an inline FIM template. Pass nil to revert to file/native resolution."

	fimTemplateString := aString
]

{ #category : 'fim-template' }
CopilotSettings class >> templatesDirectory [

	^ templatesDirectory ifNil: [
		templatesDirectory := (FileLocator imageDirectory / 'pharo-copilot' / 'templates') asFileReference ]
]

{ #category : 'fim-template' }
CopilotSettings class >> templatesDirectory: aFileReference [

	templatesDirectory := aFileReference asFileReference
]

{ #category : 'private' }
CopilotSettings class >> sanitizedFileComponentFor: aString [
	"Replace characters unsafe for file names with '-'."

	| safe |
	aString ifNil: [ ^ 'unknown-model' ].
	safe := String streamContents: [ :stream |
		aString do: [ :ch |
			(ch isLetter or: [ ch isDigit or: [ '._-' includes: ch ] ])
				ifTrue: [ stream nextPut: ch ]
				ifFalse: [ stream nextPut: $- ] ] ].
	^ safe isEmpty ifTrue: [ 'unknown-model' ] ifFalse: [ safe ]
]
