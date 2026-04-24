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

| safePrefix safeSuffix safeContext template size i ch includesContext result |
	safePrefix := prefixString ifNil: [ '' ] ifNotNil: [ prefixString asString ].
	safeSuffix := suffixString ifNil: [ '' ] ifNotNil: [ suffixString asString ].
	safeContext := contextString ifNil: [ '' ] ifNotNil: [ contextString asString ].
	template := templateString ifNil: [ '' ].
	size := template size.
	includesContext := false.

	result := size = 0
		ifTrue: [ '' ]
		ifFalse: [ String streamContents: [ :s |
			i := 1.
			[ i <= size ] whileTrue: [
				| consumed |
				ch := template at: i.
				consumed := 0.

				(ch = ${ and: [ i + 1 <= size and: [ (template at: i + 1) = ${ ] ]) ifTrue: [
					| closeIdx |
					closeIdx := self indexOfDoubleBraceCloseIn: template from: i + 2 upTo: size.
					closeIdx > 0 ifTrue: [
						| token |
						token := (template copyFrom: i + 2 to: closeIdx - 1) trimBoth.
						token = '.Prompt' ifTrue: [ s nextPutAll: safePrefix. consumed := closeIdx + 2 - i ]
						ifFalse: [ token = '.Suffix' ifTrue: [ s nextPutAll: safeSuffix. consumed := closeIdx + 2 - i ]
						ifFalse: [ token = '.Context' ifTrue: [ s nextPutAll: safeContext. includesContext := true. consumed := closeIdx + 2 - i ] ] ] ] ].

				(consumed = 0 and: [ ch = $% and: [ i + 1 <= size ] ]) ifTrue: [
					| next |
					next := template at: i + 1.
					next = $1 ifTrue: [ s nextPutAll: safePrefix. consumed := 2 ]
					ifFalse: [ next = $2 ifTrue: [ s nextPutAll: safeSuffix. consumed := 2 ]
					ifFalse: [ next = $3 ifTrue: [ s nextPutAll: safeContext. includesContext := true. consumed := 2 ] ] ] ].

				(consumed = 0 and: [ ch = ${ and: [ i + 2 <= size and: [ (template at: i + 2) = $} ] ] ]) ifTrue: [
					| digit |
					digit := template at: i + 1.
					digit = $1 ifTrue: [ s nextPutAll: safePrefix. consumed := 3 ]
					ifFalse: [ digit = $2 ifTrue: [ s nextPutAll: safeSuffix. consumed := 3 ]
					ifFalse: [ digit = $3 ifTrue: [ s nextPutAll: safeContext. includesContext := true. consumed := 3 ] ] ] ].

				consumed = 0 ifTrue: [ s nextPut: ch. consumed := 1 ].
				i := i + consumed ] ] ].

	(includesContext not and: [ safeContext isEmpty not ]) ifTrue: [ result := self prependContext: safeContext toPrompt: result ].

	^ result
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

{ #category : 'generation-operations' }
CoPCOllamaClient >> indexOfDoubleBraceCloseIn: aString from: startIndex upTo: size [ 

	| i |
	i := startIndex.
	[ i < size ] whileTrue: [
		((aString at: i) = $} and: [ (aString at: i + 1) = $} ]) ifTrue: [ ^ i ].
		i := i + 1 ].
	^ 0
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
