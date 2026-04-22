"
Simple client for invoking the Ollama REST API.
"
Class {
	#name : 'CoPCOllamaClient',
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
CoPCOllamaClient class >> defaultModelFullName [

	^ defaultModelFullName ifNil: [ defaultModelFullName := self nullModelFullName  ]
]

{ #category : 'accessing' }
CoPCOllamaClient class >> nullModelFullName [

  ^ 'pharo-copilot-null'
]

{ #category : 'accessing' }
CoPCOllamaClient class >> nullModelResponseString [

	^ 'nothing'
]

{ #category : 'response-normalization' }
CoPCOllamaClient >> coerceResponseValueToString: value default: fallbackString [

	value isNil ifTrue: [ ^ fallbackString ].
	value isString ifTrue: [ ^ value ].

	[ ^ STONJSON toString: value ]
		on: Error
		do: [ "Fall through" ].
	(value respondsTo: #asString) ifTrue: [ ^ value asString ].

	^ fallbackString
]

{ #category : 'response-normalization' }
CoPCOllamaClient >> ensureStringFromResponse: container fallback: fallbackString [

	| value |
	container ifNil: [ ^ fallbackString ].

	value := (container respondsTo: #at:ifAbsent:)
		         ifTrue: [
				         container
					         at: #response
					         ifAbsent: [
					         container
						         at: 'response'
						         ifAbsent: [ container at: #content ifAbsent: [ container at: 'content' ifAbsent: [ container ] ] ] ] ]
		         ifFalse: [ container ].

	^ self coerceResponseValueToString: value default: fallbackString
]

{ #category : 'generation-operations' }
CoPCOllamaClient >> expandFimTemplate: templateString prefix: prefixString suffix: suffixString context: contextString [

	| prompt safePrefix safeSuffix safeContext includesContext |
	safePrefix := prefixString ifNil: [ '' ] ifNotNil: [ prefixString asString ].
	safeSuffix := suffixString ifNil: [ '' ] ifNotNil: [ suffixString asString ].
	safeContext := contextString ifNil: [ '' ] ifNotNil: [ contextString asString ].
	prompt := templateString ifNil: [ '' ].

	includesContext := (prompt includesSubstring: '{{ .Context }}') or: [
		                   (prompt includesSubstring: '{{.Context}}') or: [
			                   (prompt includesSubstring: '{3}') or: [ prompt includesSubstring: '%3' ] ] ].

	prompt := prompt copyReplaceAll: '{{ .Prompt }}' with: safePrefix.
	prompt := prompt copyReplaceAll: '{{.Prompt}}' with: safePrefix.
	prompt := prompt copyReplaceAll: '{{ .Suffix }}' with: safeSuffix.
	prompt := prompt copyReplaceAll: '{{.Suffix}}' with: safeSuffix.
	prompt := prompt copyReplaceAll: '{{ .Context }}' with: safeContext.
	prompt := prompt copyReplaceAll: '{{.Context}}' with: safeContext.

	prompt := prompt copyReplaceAll: '%1' with: safePrefix.
	prompt := prompt copyReplaceAll: '%2' with: safeSuffix.
	prompt := prompt copyReplaceAll: '%3' with: safeContext.
	prompt := prompt format: {
			          safePrefix.
			          safeSuffix.
			          safeContext }.

	(includesContext not and: [ safeContext isEmpty not ]) ifTrue: [ prompt := self prependContext: safeContext toPrompt: prompt ].

	^ prompt
]

{ #category : 'generation-operations' }
CoPCOllamaClient >> generate: aPromptString [
	| payload response normalized |
	self isNullModel ifTrue: [ ^ self class nullModelResponseString ].

	payload := Dictionary new
		           at: #model put: modelSpec fullName;
		           at: #prompt put: aPromptString;
		           at: #stream put: stream;
		           yourself.
	format ifNotNil: [ payload at: #format put: format ].
	(options notNil and: [ options isEmpty not ]) ifTrue: [ payload at: #options put: options ].
	response := transport postJsonAt: 'api/generate' body: payload.
	normalized := self normalizeResponse: response.

	^ normalized
]

{ #category : 'generation-operations' }
CoPCOllamaClient >> generateForPrefix: prefixString suffix: suffixString context: contextString [
	"Generate a fill-in-the-middle completion using Ollama's native prompt/suffix API."

	| safePrefix safeSuffix safeSystem payload response normalized |
	self isNullModel ifTrue: [ ^ self class nullModelResponseString ].

	safePrefix := prefixString ifNil: [ '' ] ifNotNil: [ prefixString asString ].
	safeSuffix := suffixString ifNil: [ '' ] ifNotNil: [ suffixString asString ].
	safeSystem := self systemPromptPrefixedContextFor: contextString.

	payload := Dictionary new
		at: #model put: modelSpec fullName;
		at: #prompt put: safePrefix;
		at: #suffix put: safeSuffix;
		at: #stream put: stream;
		yourself.

	safeSystem isEmpty ifFalse: [
		payload at: #system put: safeSystem ].

	format ifNotNil: [
		payload at: #format put: format ].

	(options notNil and: [ options isEmpty not ]) ifTrue: [
		payload at: #options put: options copy ].

	response := transport postJsonAt: 'api/generate' body: payload.
	normalized := self normalizeResponse: response.

	^ normalized
]

{ #category : 'initialization' }
CoPCOllamaClient >> initialize [

	super initialize.
	transport := CoPCOAHttpTransport new.
	stream := false.
	options := Dictionary new.
	self loadOptionsFromSettings.
	self useModelNamed: CopilotSettings modelName.
]

{ #category : 'model-operations' }
CoPCOllamaClient >> isNullModel [

	modelSpec ifNil: [ ^ false ].
	^ modelSpec fullName = self class nullModelFullName
]

{ #category : 'ollama' }
CoPCOllamaClient >> listModels [

	| response |
	response := transport getJsonAt: 'api/tags'.
	^ response
]

{ #category : 'initialization' }
CoPCOllamaClient >> loadOptionsFromSettings [

	| settingsOptions |
	settingsOptions := CopilotSettings allOllamaOptions.
	settingsOptions keysAndValuesDo: [ :key :value | options at: key put: value ].
]

{ #category : 'response-normalization' }
CoPCOllamaClient >> normalizeResponse: response [

	| parsed |
	response isNil ifTrue: [ ^ '' ].

	response isString ifTrue: [
			parsed := self parseJsonSafely: response.
			parsed ifNil: [ ^ response ].
			^ (parsed isKindOf: Dictionary)
				  ifTrue: [ self ensureStringFromResponse: parsed fallback: response ]
				  ifFalse: [ self coerceResponseValueToString: parsed default: response ] ].

	^ self ensureStringFromResponse: response fallback: response asString
]

{ #category : 'api' }
CoPCOllamaClient >> optionAt: aKey [
^ options ifNil: [ nil ] ifNotNil: [ options at: aKey ifAbsent: [ nil ] ]
]

{ #category : 'api' }
CoPCOllamaClient >> optionAt: aKey put: aValue [

	options ifNil: [ options := Dictionary new ].
	^ options at: aKey put: aValue
]

{ #category : 'api' }
CoPCOllamaClient >> options [

	^ options
]

{ #category : 'api' }
CoPCOllamaClient >> options: aDictionary [

	options := aDictionary ifNil: [ Dictionary new ]
]

{ #category : 'response-normalization' }
CoPCOllamaClient >> parseJsonSafely: aString [

	^ [ STONJSON fromString: aString ]
		  on: Error
		  do: [ nil ]
]

{ #category : 'generation-operations' }
CoPCOllamaClient >> prependContext: contextString toPrompt: promptString [

	| delimiter |
	delimiter := String lf , String lf.
	^ String streamContents: [ :s |
			  s
				  nextPutAll: 'Class context provided by Pharo Copilot:';
				  nextPutAll: delimiter;
				  nextPutAll: contextString;
				  nextPutAll: delimiter;
				  nextPutAll: promptString ]
]

{ #category : 'ollama' }
CoPCOllamaClient >> pullModelNamed: aString [

	^ self pullModelNamed: aString timeoutSeconds: CopilotSettings modelInstallTimeoutSeconds
]

{ #category : 'ollama' }
CoPCOllamaClient >> pullModelNamed: aString timeoutSeconds: timeoutSeconds [

	| payload response |
	payload := Dictionary new
		           at: #name put: aString;
		           at: #stream put: false;
		           yourself.

	response := transport postJsonAt: 'api/pull' body: payload timeoutSeconds: timeoutSeconds.

	^ response
]

{ #category : 'ollama' }
CoPCOllamaClient >> showModelNamed: aModelFullName [

	| payload response |
	payload := Dictionary new
		           at: #model put: aModelFullName;
		           yourself.

	response := transport postJsonAt: 'api/show' body: payload.


	^ response
]

{ #category : 'generation-operations' }
CoPCOllamaClient >> systemPromptPrefixedContextFor: contextString [

	| systemPrompt safeContext |
	systemPrompt := CopilotSettings modelSystemPromptIfAvailable.
	safeContext := contextString ifNil: [ '' ] ifNotNil: [ contextString asString ].

	(systemPrompt isEmpty and: [ safeContext isEmpty ]) ifTrue: [ ^ safeContext ].

	^ String streamContents: [ :stream |
			  systemPrompt isEmpty ifFalse: [
					  stream
						  nextPutAll: 'System Prompt:';
						  cr;
						  nextPutAll: systemPrompt;
						  cr;
						  cr ].
			  safeContext isEmpty ifFalse: [ stream nextPutAll: safeContext ] ]
]

{ #category : 'accessing' }
CoPCOllamaClient >> transport [

	^ transport
]

{ #category : 'model-operations' }
CoPCOllamaClient >> useDefaultModel [

	self useModelNamed: self class defaultModelFullName
]

{ #category : 'model-operations' }
CoPCOllamaClient >> useModelNamed: aString [
	"Resolve and set the model spec for the given full name (family[:tag])."

	| tokens family tag |

	modelSpec := CoPCModelRegistry current specByFullName: aString.
	modelSpec ifNil: [
			tokens := aString findTokens: ':'.
			family := tokens isEmpty
				          ifTrue: [ aString ]
				          ifFalse: [ tokens first ].
			tag := tokens size > 1
				       ifTrue: [
						       String streamContents: [ :s |
							       (tokens copyFrom: 2 to: tokens size) do: [ :each | s nextPutAll: each ] separatedBy: [ s nextPut: $: ] ] ]
				       ifFalse: [ nil ].
			modelSpec := CoPCModelSpec family: family tag: tag label: aString ].
]
