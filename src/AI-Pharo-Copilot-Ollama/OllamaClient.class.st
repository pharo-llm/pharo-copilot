"
Simple client for invoking the Ollama REST API.
"
Class {
	#name : 'OllamaClient',
	#superclass : 'Object',
	#instVars : [
		'transport',
		'modelSpec',
		'stream',
		'format',
		'options'
	],
	#classInstVars : [
		'defaultModelFullName'
	],
	#category : 'AI-Pharo-Copilot-Ollama',
	#package : 'AI-Pharo-Copilot-Ollama'
}

{ #category : 'accessing' }
OllamaClient class >> defaultModelFullName [

	^ defaultModelFullName ifNil: [ defaultModelFullName := self nullModelFullName  ]
]

{ #category : 'accessing' }
OllamaClient class >> nullModelFullName [

  ^ 'pharo-copilot-null'
]

{ #category : 'accessing' }
OllamaClient class >> nullModelResponseString [

  ^ ''
]

{ #category : 'private' }
OllamaClient >> coerceResponseValueToString: value default: fallbackString [

        value isNil ifTrue: [ ^ '' ].
        value isString ifTrue: [ ^ value ].
        [ ^ STONJSON toString: value ] on: Error do: [ ].
        (value respondsTo: #asString)
                ifTrue: [ ^ value asString ].
        ^ fallbackString
]

{ #category : 'private' }
OllamaClient >> ensureStringFromResponse: container fallback: fallbackString [

        | value |
        container ifNil: [ ^ fallbackString ].
        value := (container respondsTo: #at:ifAbsent:)
                ifTrue: [ container
                        at: #response ifAbsent: [
                                container
                                        at: 'response' ifAbsent: [
                                                container
                                                        at: #content ifAbsent: [
                                                                container at: 'content' ifAbsent: [ container ] ] ] ] ]
                ifFalse: [ container ].
        ^ self coerceResponseValueToString: value default: fallbackString
]

{ #category : 'as yet unclassified' }
OllamaClient >> expandFimTemplate: templateString prefix: prefixString suffix: suffixString context: contextString [ 

        | prompt safePrefix safeSuffix safeContext includesContextPlaceholder |
        safePrefix := prefixString ifNil: [ '' ] ifNotNil: [ prefixString asString ].
        safeSuffix := suffixString ifNil: [ '' ] ifNotNil: [ suffixString asString ].
        safeContext := contextString ifNil: [ '' ] ifNotNil: [ contextString asString ].
        prompt := templateString ifNil: [ '' ].
        includesContextPlaceholder := (prompt includesSubstring: '{{ .Context }}')
                or: [ (prompt includesSubstring: '{{.Context}}') or: [ prompt includesSubstring: '{3}' ] ].
        prompt := prompt copyReplaceAll: '{{ .Prompt }}' with: safePrefix.
        prompt := prompt copyReplaceAll: '{{.Prompt}}' with: safePrefix.
        prompt := prompt copyReplaceAll: '{{ .Suffix }}' with: safeSuffix.
        prompt := prompt copyReplaceAll: '{{.Suffix}}' with: safeSuffix.
        prompt := prompt copyReplaceAll: '{{ .Context }}' with: safeContext.
        prompt := prompt copyReplaceAll: '{{.Context}}' with: safeContext.
        prompt := prompt format: {
                safePrefix.
                safeSuffix.
                safeContext }.
        (includesContextPlaceholder not and: [ safeContext isEmpty not ]) ifTrue: [
                prompt := self prependContext: safeContext toPrompt: prompt ].
        ^ prompt
]

{ #category : 'operations' }
OllamaClient >> generate: aPromptString [

	| payload resp normalized |
	self isNullModel ifTrue: [
			^ self class nullModelResponseString ].
	payload := Dictionary new
		           at: #model put: modelSpec fullName;
		           at: #prompt put: aPromptString;
		           at: #stream put: stream;
		           yourself.
	format ifNotNil: [ payload at: #format put: format ].
	options isEmpty ifFalse: [ payload at: #options put: options ].
	resp := transport postJsonAt: 'api/generate' body: payload.


	normalized := self normalizeResponse: resp.

	^ normalized
]

{ #category : 'as yet unclassified' }
OllamaClient >> generateForPrefix: prefixString suffix: suffixString context: contextString [

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
]

{ #category : 'initialization' }
OllamaClient >> initialize [

	super initialize.
	transport := OAHttpTransport new.
	stream := false.
	options := Dictionary new.
	self useModelNamed: CopilotSettings modelName.
]

{ #category : 'operations' }
OllamaClient >> isNullModel [

        modelSpec ifNil: [ ^ false ].
        ^ modelSpec fullName = self class nullModelFullName
]

{ #category : 'operations' }
OllamaClient >> listModels [

	| response |
	response := transport getJsonAt: 'api/tags'.
	^ response
]

{ #category : 'private' }
OllamaClient >> normalizeResponse: resp [
	"If streaming=false, Ollama returns a dict; prefer #response or #content."

	"Handle case where resp might be a string representation of JSON"
resp isNil ifTrue: [ ^ '' ].
	resp isString ifTrue: [
			    | parsed |
    parsed := self parseJsonSafely: resp.
    parsed ifNil: [ ^ resp ].
    (parsed isKindOf: Dictionary) ifTrue: [
        ^ self ensureStringFromResponse: parsed fallback: resp ].
    ^ self coerceResponseValueToString: parsed default: resp ].

	^ self ensureStringFromResponse: resp fallback: resp asString .

  ^ self coerceResponseValueToString: resp default: resp asString
]

{ #category : 'operations' }
OllamaClient >> optionAt: aKey [

	| value |
	value := options ifNil: [ nil ] ifNotNil: [ options at: aKey ifAbsent: [ nil ] ].
	^ value
]

{ #category : 'private' }
OllamaClient >> optionAt: aKey put: aValue [

	options ifNil: [ options := Dictionary new ].
	^ options at: aKey put: aValue
]

{ #category : 'operations' }
OllamaClient >> options [

	^ options
]

{ #category : 'operations' }
OllamaClient >> options: aDictionary [

	options := aDictionary ifNil: [ Dictionary new ]
]

{ #category : 'private' }
OllamaClient >> parseJsonSafely: aString [

        ^ [ STONJSON fromString: aString ] on: Error do: [ nil ]
]

{ #category : 'as yet unclassified' }
OllamaClient >> prependContext: contextString toPrompt: promptString [

        | delimiter | 
        delimiter := String lf , String lf.
        ^ String streamContents: [ :stream |
                stream
                        nextPutAll: 'Class context provided by Pharo Copilot:';
                        nextPutAll: delimiter;
                        nextPutAll: contextString;
                        nextPutAll: delimiter;
                        nextPutAll: promptString ]
]

{ #category : 'operations' }
OllamaClient >> pullModelNamed: aString [

	| payload response |
	payload := Dictionary new
		           at: #name put: aString;
		           yourself.
	response := transport postJsonAt: 'api/pull' body: payload.
	^ response
]

{ #category : 'as yet unclassified' }
OllamaClient >> showModelNamed: aModelFullName [

	| payload response |
	payload := Dictionary new
		           at: #model put: aModelFullName;
		           yourself.
	response := transport postJsonAt: 'api/show' body: payload.
	^ response
]

{ #category : 'operations' }
OllamaClient >> useDefaultModel [
	self useModelNamed: self class defaultModelFullName
]

{ #category : 'operations' }
OllamaClient >> useModelNamed: aString [

	| tokens family tag |
	modelSpec := OModelRegistry current specByFullName: aString.
	modelSpec ifNil: [
			tokens := aString findTokens: ':'.
			family := tokens isEmpty
				          ifTrue: [ aString ]
				          ifFalse: [ tokens first ].
			tag := tokens size > 1
				       ifTrue: [
						       | parts |
						       parts := tokens copyFrom: 2 to: tokens size.
						       String streamContents: [ :stream | parts do: [ :each | stream nextPutAll: each ] separatedBy: [ stream nextPut: $: ] ] ]
				       ifFalse: [ nil ].
			modelSpec := OModelSpec family: family tag: tag label: aString ].
		^ modelSpec
]
