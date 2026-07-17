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

	(defaultModelFullName isNil or: [
		defaultModelFullName isEmpty or: [
			defaultModelFullName = self nullModelFullName ] ])
		ifTrue: [ defaultModelFullName := self availableDefaultModelFullName ].
	^ defaultModelFullName
]

{ #category : 'accessing' }
CoPCOllamaClient class >> availableDefaultModelFullName [

	^ 'pharo-llm/Qwen2.5-Coder-SFT:q4_K_M'
]

{ #category : 'accessing' }
CoPCOllamaClient class >> defaultFimGenerationTemplate [
	"Matches the TEMPLATE shipped with the pharo-llm Qwen2.5-Coder FIM models on Ollama."

	^ '<|fim_prefix|>{{ .Prompt }}<|fim_suffix|>{{ .Suffix }}<|fim_middle|>'
]

{ #category : 'accessing' }
CoPCOllamaClient class >> fimStopSequences [
	"Special tokens after which a FIM completion must stop generating."

	^ #( '<|endoftext|>' '<|fim_prefix|>' '<|fim_suffix|>' '<|fim_middle|>' '<|repo_name|>' '<|file_sep|>' )
]

{ #category : 'accessing' }
CoPCOllamaClient class >> nullModelFullName [

  ^ 'pharo-copilot-null'
]

{ #category : 'accessing' }
CoPCOllamaClient class >> quantizedDefaultModelFullName [
	"Compatibility alias for older callers."

	^ self availableDefaultModelFullName
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
		           at: #keep_alive put: CopilotSettings modelKeepAlive;
		           yourself.
	format ifNotNil: [ payload at: #format put: format ].
	(options notNil and: [ options isEmpty not ]) ifTrue: [ payload at: #options put: options ].
	response := transport postJsonAt: 'api/generate' body: payload.
	normalized := self normalizeResponse: response.

	^ normalized
]

{ #category : 'generation-operations' }
CoPCOllamaClient >> fimTemplateForGeneration [
	"Answer the FIM template used to assemble the raw prompt, falling back to the
	standard Qwen2.5-Coder template when model metadata is unavailable."

	^ [ CopilotSettings fimTemplate ]
		on: Error
		do: [ self class defaultFimGenerationTemplate ]
]

{ #category : 'generation-operations' }
CoPCOllamaClient >> generateForPrefix: prefixString suffix: suffixString context: contextString [
	"Generate a fill-in-the-middle completion.
	The full FIM prompt (class context + prefix + suffix) is assembled locally and sent
	with raw mode so the model receives exactly the repo-level format it was fine-tuned on.
	The class context must NOT be sent as a system prompt: the FIM model templates have
	no {{ .System }} slot, so Ollama silently drops system content."

	| safePrefix safeSuffix safeContext prompt payload requestOptions response |
	self isNullModel ifTrue: [ ^ self class nullModelResponseString ].

	safePrefix := self normalizeLineEndings: prefixString.
	safeSuffix := self normalizeLineEndings: suffixString.
	safeContext := self normalizeLineEndings: contextString.

	prompt := self
		expandFimTemplate: self fimTemplateForGeneration
		prefix: safePrefix
		suffix: safeSuffix
		context: safeContext.

	payload := Dictionary new
		at: #model put: modelSpec fullName;
		at: #prompt put: prompt;
		at: #raw put: true;
		at: #stream put: stream;
		at: #keep_alive put: CopilotSettings modelKeepAlive;
		yourself.

	format ifNotNil: [
		payload at: #format put: format ].

	requestOptions := options
		ifNil: [ Dictionary new ]
		ifNotNil: [ options copy ].
	requestOptions at: #stop ifAbsentPut: [ self class fimStopSequences ].
	payload at: #options put: requestOptions.

	response := transport postJsonAt: 'api/generate' body: payload.
	^ self normalizeResponse: response
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
CoPCOllamaClient >> normalizeLineEndings: aString [
	"Answer the string with all line endings normalized to LF. Pharo editors and method
	sources historically use CR, but the completion models are trained on LF text."

	| text |
	text := (aString ifNil: [ '' ]) asString.
	(text includes: Character cr) ifFalse: [ ^ text ].
	^ (text copyReplaceAll: String crlf with: String lf)
		copyReplaceAll: String cr with: String lf
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

	"No prose banner here: the context is already structured with repo/file markers and
	the whole string goes to the model verbatim (raw mode)."

	| delimiter |
	delimiter := String lf.
	^ String streamContents: [ :s |
			  s
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
CoPCOllamaClient >> pullModelNamed: aString timeoutSeconds: timeoutSeconds progress: aProgressBlock [
	"Pull a model with streaming progress. The block receives a dictionary per status line
	(keys: status, total, completed when Ollama provides them). Falls back to the blocking
	pull when streaming is unavailable. Answers true only when Ollama reported the final
	'success' status; an error status line signals an Error."

	| payload sawSuccess |
	aProgressBlock ifNil: [ ^ self pullModelNamed: aString timeoutSeconds: timeoutSeconds ].
	(transport respondsTo: #postStreamingAt:body:timeoutSeconds:linesDo:) ifFalse: [
		^ self pullModelNamed: aString timeoutSeconds: timeoutSeconds ].

	payload := Dictionary new
		           at: #name put: aString;
		           at: #stream put: true;
		           yourself.

	sawSuccess := false.
	transport
		postStreamingAt: 'api/pull'
		body: payload
		timeoutSeconds: timeoutSeconds
		linesDo: [ :line |
			| parsed errorText |
			parsed := self parseJsonSafely: line.
			(parsed isKindOf: Dictionary) ifTrue: [
				errorText := parsed at: #error ifAbsent: [ parsed at: 'error' ifAbsent: [ nil ] ].
				(errorText notNil and: [ errorText asString trimBoth isEmpty not ]) ifTrue: [
					self error: 'Ollama pull of ' , aString , ' failed: ' , errorText asString ].
				(self pullEventIndicatesSuccess: parsed) ifTrue: [ sawSuccess := true ].
				[ aProgressBlock value: parsed ]
					on: Error
					do: [ :ex |
						CoPharoCopilotLogger
							logBackEndEvent: 'Ollama pull progress callback failed'
							details: (Dictionary new
								at: #model put: aString;
								at: #errorClass put: ex class name;
								at: #error put: ex description;
								yourself) ] ] ].

	^ sawSuccess
]

{ #category : 'ollama' }
CoPCOllamaClient >> pullEventIndicatesSuccess: aDictionary [
	"Answer whether a streamed pull status line reports the final success state."

	| status |
	status := aDictionary at: #status ifAbsent: [ aDictionary at: 'status' ifAbsent: [ '' ] ].
	^ status asString trimBoth asLowercase = 'success'
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
