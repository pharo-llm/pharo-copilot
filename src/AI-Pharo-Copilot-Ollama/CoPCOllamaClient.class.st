"
Minimal Ollama client.

Two generation paths are kept:

  #generateForPrefix:suffix:context:
    - If CopilotSettings fimTemplate is set, the prompt is built by expanding the
      FIM template (placeholders {{ .Prompt }} / {{ .Suffix }} / {{ .Context }}
      and %1 / %2 / %3) and sent as a single `prompt` field.
    - Otherwise, Ollama's native FIM API is used (separate `prompt` and
      `suffix` fields) and the class context is passed via `system`.

No response cleaning, no prefix echo removal, no template-leak filtering.
The raw `response` field from Ollama is returned as a string.
"
Class {
	#name : 'CoPCOllamaClient',
	#superclass : 'Object',
	#instVars : [
		'transport',
		'modelFullName',
		'options'
	],
	#category : 'AI-Pharo-Copilot-Ollama',
	#package : 'AI-Pharo-Copilot-Ollama'
}

{ #category : 'initialization' }
CoPCOllamaClient >> initialize [

	super initialize.
	transport := CoPCOAHttpTransport new.
	modelFullName := CopilotSettings modelName.
	options := CopilotSettings allOllamaOptions copy
]

{ #category : 'accessing' }
CoPCOllamaClient >> transport [ ^ transport ]

{ #category : 'accessing' }
CoPCOllamaClient >> modelFullName [ ^ modelFullName ]

{ #category : 'accessing' }
CoPCOllamaClient >> useModelNamed: aString [

	modelFullName := aString
]

{ #category : 'accessing' }
CoPCOllamaClient >> options [ ^ options ]

{ #category : 'accessing' }
CoPCOllamaClient >> options: aDictionary [

	options := aDictionary ifNil: [ Dictionary new ]
]

{ #category : 'generation' }
CoPCOllamaClient >> generate: aPromptString [
	"POST /api/generate with a single prompt."

	| payload response |
	payload := Dictionary new
		at: #model   put: modelFullName;
		at: #prompt  put: aPromptString;
		at: #stream  put: false;
		yourself.
	(options notNil and: [ options isEmpty not ])
		ifTrue: [ payload at: #options put: options copy ].

	response := transport postJsonAt: 'api/generate' body: payload.
	^ self responseTextOf: response
]

{ #category : 'generation' }
CoPCOllamaClient >> generateForPrefix: prefixString suffix: suffixString context: contextString [
	"Main entry point used by the completion builder.

	If a FIM template is configured, expand it and send a single prompt.
	Otherwise use Ollama's native FIM API (prompt + suffix) and pass the
	class context as a `system` message."

	| template safePrefix safeSuffix safeContext |
	safePrefix  := prefixString  ifNil: [ '' ].
	safeSuffix  := suffixString  ifNil: [ '' ].
	safeContext := contextString ifNil: [ '' ].

	template := CopilotSettings fimTemplate.

	template ifNotNil: [
		| prompt |
		prompt := self
			expandFimTemplate: template
			prefix: safePrefix asString
			suffix: safeSuffix asString
			context: safeContext asString.
		^ self generate: prompt ].

	^ self
		nativeFimForPrefix: safePrefix asString
		suffix: safeSuffix asString
		context: safeContext asString
]

{ #category : 'generation' }
CoPCOllamaClient >> nativeFimForPrefix: prefixString suffix: suffixString context: contextString [

	| payload response |
	payload := Dictionary new
		at: #model   put: modelFullName;
		at: #prompt  put: prefixString;
		at: #suffix  put: suffixString;
		at: #stream  put: false;
		yourself.

	contextString isEmpty ifFalse: [
		payload at: #system put: contextString ].

	(options notNil and: [ options isEmpty not ])
		ifTrue: [ payload at: #options put: options copy ].

	response := transport postJsonAt: 'api/generate' body: payload.
	^ self responseTextOf: response
]

{ #category : 'generation' }
CoPCOllamaClient >> expandFimTemplate: templateString prefix: prefixString suffix: suffixString context: contextString [
	"Substitute FIM placeholders. Supported:
	   {{ .Prompt }}  {{.Prompt}}  %1    -> prefix
	   {{ .Suffix }}  {{.Suffix}}  %2    -> suffix
	   {{ .Context }} {{.Context}} %3    -> class context"

	| prompt |
	prompt := templateString ifNil: [ '' ].
	prompt := prompt copyReplaceAll: '{{ .Prompt }}'  with: prefixString.
	prompt := prompt copyReplaceAll: '{{.Prompt}}'    with: prefixString.
	prompt := prompt copyReplaceAll: '{{ .Suffix }}'  with: suffixString.
	prompt := prompt copyReplaceAll: '{{.Suffix}}'    with: suffixString.
	prompt := prompt copyReplaceAll: '{{ .Context }}' with: contextString.
	prompt := prompt copyReplaceAll: '{{.Context}}'   with: contextString.
	prompt := prompt copyReplaceAll: '%1' with: prefixString.
	prompt := prompt copyReplaceAll: '%2' with: suffixString.
	prompt := prompt copyReplaceAll: '%3' with: contextString.
	^ prompt
]

{ #category : 'response' }
CoPCOllamaClient >> responseTextOf: aResponse [
	"Extract the text of Ollama's `response` field as-is. No cleaning."

	| container value |
	aResponse ifNil: [ ^ '' ].

	container := aResponse isString
		ifTrue: [ [ STONJSON fromString: aResponse ] on: Error do: [ ^ aResponse ] ]
		ifFalse: [ aResponse ].

	(container isKindOf: Dictionary) ifFalse: [ ^ container asString ].

	value := container at: #response ifAbsent: [
		container at: 'response' ifAbsent: [
			container at: #content ifAbsent: [
				container at: 'content' ifAbsent: [ '' ] ] ] ].

	value isNil    ifTrue: [ ^ '' ].
	value isString ifTrue: [ ^ value ].
	^ value asString
]
