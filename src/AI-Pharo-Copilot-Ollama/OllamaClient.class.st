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

{ #category : 'response-normalization' }
OllamaClient >> coerceResponseValueToString: value default: fallbackString [
	"Coerce arbitrary response values into a reasonable String representation."

	value isNil ifTrue: [ ^ fallbackString ].
	value isString ifTrue: [ ^ value ].

	[ ^ STONJSON toString: value ] on: Error do: [ "Fall through" ].
	(value respondsTo: #asString) ifTrue: [ ^ value asString ].

	^ fallbackString
]

{ #category : 'response-normalization' }
OllamaClient >> ensureStringFromResponse: container fallback: fallbackString [
	"Extract #response/#content (symbol or string keys) when possible, and coerce it to a String."

	| value |
	container ifNil: [ ^ fallbackString ].

	value := (container respondsTo: #at:ifAbsent:)
		ifTrue: [
			container
				at: #response ifAbsent: [
					container
						at: 'response' ifAbsent: [
							container
								at: #content ifAbsent: [
									container at: 'content' ifAbsent: [ container ] ] ] ] ]
		ifFalse: [ container ].

	^ self coerceResponseValueToString: value default: fallbackString
]

{ #category : 'generation-operations' }
OllamaClient >> expandFimTemplate: templateString prefix: prefixString suffix: suffixString context: contextString [
	"Expand the FIM template with prefix/suffix/context, and prepend context if the template does not reference it."

	| prompt safePrefix safeSuffix safeContext includesContext |
	safePrefix := prefixString ifNil: [ '' ] ifNotNil: [ prefixString asString ].
	safeSuffix := suffixString ifNil: [ '' ] ifNotNil: [ suffixString asString ].
	safeContext := contextString ifNil: [ '' ] ifNotNil: [ contextString asString ].
	prompt := templateString ifNil: [ '' ].

	includesContext := (prompt includesSubstring: '{{ .Context }}')
		or: [ (prompt includesSubstring: '{{.Context}}')
		or: [ prompt includesSubstring: '{3}' ] ].

	prompt := prompt copyReplaceAll: '{{ .Prompt }}' with: safePrefix.
	prompt := prompt copyReplaceAll: '{{.Prompt}}' with: safePrefix.
	prompt := prompt copyReplaceAll: '{{ .Suffix }}' with: safeSuffix.
	prompt := prompt copyReplaceAll: '{{.Suffix}}' with: safeSuffix.
	prompt := prompt copyReplaceAll: '{{ .Context }}' with: safeContext.
	prompt := prompt copyReplaceAll: '{{.Context}}' with: safeContext.

	"Support {1}/{2}/{3} style formatting as well."
	prompt := prompt format: { safePrefix. safeSuffix. safeContext }.

	(includesContext not and: [ safeContext isEmpty not ]) ifTrue: [
		prompt := self prependContext: safeContext toPrompt: prompt ].

	^ prompt
]

{ #category : 'generation-operations' }
OllamaClient >> generate: aPromptString [
	"Send a generate request and answer the normalized response as a String."

	| payload response normalized |
	self isNullModel ifTrue: [
			CoCopilotLogger logBackEndEvent: 'Null model responded to completion request' details: (Dictionary new
					 at: #modelFullName put: (modelSpec ifNil: [ self class nullModelFullName ] ifNotNil: [ modelSpec fullName ]);
					 yourself).
			^ self class nullModelResponseString ].

	payload := Dictionary new
		           at: #model put: modelSpec fullName;
		           at: #prompt put: aPromptString;
		           at: #stream put: stream;
		           yourself.

	format ifNotNil: [ payload at: #format put: format ].
	(options notNil and: [ options isEmpty not ]) ifTrue: [ payload at: #options put: options ].

	self haltOnce.
	CoCopilotLogger logBackEndEvent: 'Dispatching generate request' details: (Dictionary new
			 at: #endpoint put: 'api/generate';
			 at: #modelFullName put: modelSpec fullName;
			 at: #payload put: payload;
			 at: #optionsSnapshot put: options copy;
			 yourself).

	response := transport postJsonAt: 'api/generate' body: payload.

	CoCopilotLogger logBackEndEvent: 'Received generate response' details: (Dictionary new
			 at: #responseClass put: (response ifNil: [ 'nil' ] ifNotNil: [ response class name ]);
			 at: #rawResponse put: ([ response asString ]
					  on: Error
					  do: [ response printString ]);
			 yourself).

	normalized := self normalizeResponse: response.

	CoCopilotLogger logBackEndEvent: 'Normalized generate response' details: (Dictionary new
			 at: #normalizedResponse put: normalized;
			 at: #normalizedLength put: normalized size;
			 yourself).

	^ normalized
]

{ #category : 'generation-operations' }
OllamaClient >> generateForPrefix: prefixString suffix: suffixString context: contextString [
	"Generate a fill-in-the-middle completion by expanding the configured FIM template."

		| prompt originalOptions response combinedContext |
	combinedContext := self systemPromptPrefixedContextFor: contextString.
	CoCopilotLogger logBackEndEvent: 'Preparing fill-in-the-middle request' details: (Dictionary new
			 at: #prefix put: prefixString;
			 at: #suffix put: suffixString;
			 at: #contextBytes put: combinedContext size;
			 at: #template put: CopilotSettings fimTemplate;
			 at: #optionsBefore put: options copy;
			 yourself).

	prompt := self
		          expandFimTemplate: CopilotSettings fimTemplate
		          prefix: prefixString
		          suffix: suffixString
		          context: combinedContext.

	CoCopilotLogger logBackEndEvent: 'Expanded fill-in-the-middle template' details: (Dictionary new
			 at: #prompt put: prompt;
			 yourself).

	originalOptions := options copy.
	[
		self optionAt: #task put: 'fill-in-the-middle'.
		CoCopilotLogger logBackEndEvent: 'Augmented Ollama options for fill-in-the-middle' details: (Dictionary new
				 at: #optionsAfter put: options copy;
				 yourself).
		response := self generate: prompt ] ensure: [
			options := originalOptions.
			CoCopilotLogger logBackEndEvent: 'Restored Ollama options after fill-in-the-middle' details: (Dictionary new
					 at: #optionsRestored put: options copy;
					 yourself) ].

	^ response
]

{ #category : 'initialization' }
OllamaClient >> initialize [
	"Initialize default transport, options, streaming flag, and select the configured model."

	super initialize.
	transport := OAHttpTransport new.
	stream := false.
	options := Dictionary new.
	self useModelNamed: CopilotSettings modelName.

	CoCopilotLogger
		logBackEndEvent: 'Initialized Ollama client'
		details: (Dictionary new
			at: #transportClass put: transport class name;
			at: #streamingEnabled put: stream;
			at: #format put: format;
			at: #modelFullName put: (modelSpec
				ifNil: [ 'unassigned' ]
				ifNotNil: [ modelSpec fullName ]);
			yourself).
]

{ #category : 'model-operations' }
OllamaClient >> isNullModel [
	"Answer true when the current model spec is the configured null model."

	modelSpec ifNil: [ ^ false ].
	^ modelSpec fullName = self class nullModelFullName
]

{ #category : 'ollama' }
OllamaClient >> listModels [
	"Ask Ollama for the available models (tags endpoint)."

	| response |
	CoCopilotLogger
		logBackEndEvent: 'Listing available Ollama models'
		details: (Dictionary new
			at: #endpoint put: 'api/tags';
			yourself).

	response := transport getJsonAt: 'api/tags'.

	CoCopilotLogger
		logBackEndEvent: 'Received Ollama model list'
		details: (Dictionary new
			at: #response put: response;
			yourself).

	^ response
]

{ #category : 'response-normalization' }
OllamaClient >> normalizeResponse: response [
	"Return a best-effort String for typical Ollama responses (Dictionary or JSON string)."

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
OllamaClient >> optionAt: aKey [
	"Answer the option value for aKey or nil when absent."

	| value |
	value := options ifNil: [ nil ] ifNotNil: [ options at: aKey ifAbsent: [ nil ] ].

	CoCopilotLogger
		logBackEndEvent: 'Reading Ollama option'
		details: (Dictionary new
			at: #key put: aKey;
			at: #value put: value;
			yourself).

	^ value
]

{ #category : 'api' }
OllamaClient >> optionAt: aKey put: aValue [
	"Set an option value and answer it."

	options ifNil: [ options := Dictionary new ].

	CoCopilotLogger
		logBackEndEvent: 'Updating Ollama option'
		details: (Dictionary new
			at: #key put: aKey;
			at: #value put: aValue;
			yourself).

	^ options at: aKey put: aValue
]

{ #category : 'api' }
OllamaClient >> options [
	"Answer the current options dictionary."

	CoCopilotLogger
		logBackEndEvent: 'Accessing Ollama options snapshot'
		details: (Dictionary new
			at: #options put: options;
			yourself).

	^ options
]

{ #category : 'api' }
OllamaClient >> options: aDictionary [
	"Replace the current options dictionary (nil becomes an empty Dictionary)."

	CoCopilotLogger
		logBackEndEvent: 'Replacing Ollama options'
		details: (Dictionary new
			at: #newOptions put: (aDictionary ifNil: [ Dictionary new ]);
			yourself).

	options := aDictionary ifNil: [ Dictionary new ]
]

{ #category : 'response-normalization' }
OllamaClient >> parseJsonSafely: aString [
	"Parse JSON using STONJSON and answer nil if parsing fails."

	^ [ STONJSON fromString: aString ] on: Error do: [ nil ]
]

{ #category : 'generation-operations' }
OllamaClient >> prependContext: contextString toPrompt: promptString [
	"Prepend context to the prompt in a predictable, readable way."

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
OllamaClient >> pullModelNamed: aString [
	"Request Ollama to pull/install the given model name."

	^ self pullModelNamed: aString timeoutSeconds: CopilotSettings modelInstallTimeoutSeconds
]

{ #category : 'ollama' }
OllamaClient >> pullModelNamed: aString timeoutSeconds: timeoutSeconds [ 
	"Request Ollama to pull/install the given model name with a timeout override."

	| payload response |
	payload := Dictionary new
		at: #name put: aString;
		at: #stream put: false;
		yourself.

	CoCopilotLogger
		logBackEndEvent: 'Requesting Ollama model install'
		details: (Dictionary new
			at: #endpoint put: 'api/pull';
			at: #model put: aString;
			at: #payload put: payload;
			yourself).
			
		
response := transport postJsonAt: 'api/pull' body: payload timeoutSeconds: timeoutSeconds.

	CoCopilotLogger
		logBackEndEvent: 'Ollama model install request acknowledged'
		details: (Dictionary new
			at: #model put: aString;
			at: #responseClass put: (response ifNil: [ 'nil' ] ifNotNil: [ response class name ]);
			yourself).

	^ response
]

{ #category : 'ollama' }
OllamaClient >> showModelNamed: aModelFullName [
	"Ask Ollama for details about the given model."

	| payload response |
	payload := Dictionary new
		at: #model put: aModelFullName;
		yourself.

	CoCopilotLogger
		logBackEndEvent: 'Requesting Ollama model details'
		details: (Dictionary new
			at: #endpoint put: 'api/show';
			at: #modelFullName put: aModelFullName;
			yourself).

	response := transport postJsonAt: 'api/show' body: payload.

	CoCopilotLogger
		logBackEndEvent: 'Received Ollama model details'
		details: (Dictionary new
			at: #responseClass put: (response ifNil: [ 'nil' ] ifNotNil: [ response class name ]);
			at: #rawResponse put: ([ response asString ] on: Error do: [ response printString ]);
			yourself).

	^ response
]

{ #category : 'generation-operations' }
OllamaClient >> systemPromptPrefixedContextFor: contextString [
	"Combine the model system prompt with the provided context, if available."

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
		safeContext isEmpty ifFalse: [
			stream nextPutAll: safeContext ] ]
]

{ #category : 'model-operations' }
OllamaClient >> useDefaultModel [
	"Switch to the default model as defined on the class side."

	CoCopilotLogger
		logBackEndEvent: 'Switching to default Ollama model'
		details: (Dictionary new
			at: #defaultModelFullName put: self class defaultModelFullName;
			yourself).

	self useModelNamed: self class defaultModelFullName
]

{ #category : 'model-operations' }
OllamaClient >> useModelNamed: aString [
	"Resolve and set the model spec for the given full name (family[:tag])."

	| tokens family tag |
	CoCopilotLogger
		logBackEndEvent: 'Requested Ollama model change'
		details: (Dictionary new
			at: #requestedName put: aString;
			yourself).

	modelSpec := OModelRegistry current specByFullName: aString.
	modelSpec ifNil: [
		tokens := aString findTokens: ':'.
		family := tokens isEmpty ifTrue: [ aString ] ifFalse: [ tokens first ].
		tag := tokens size > 1
			ifTrue: [
				String streamContents: [ :s |
					(tokens copyFrom: 2 to: tokens size)
						do: [ :each | s nextPutAll: each ]
						separatedBy: [ s nextPut: $: ] ] ]
			ifFalse: [ nil ].
		modelSpec := OModelSpec family: family tag: tag label: aString ].

	CoCopilotLogger
		logBackEndEvent: 'Applied Ollama model change'
		details: (Dictionary new
			at: #resolvedName put: modelSpec fullName;
			at: #modelFamily put: modelSpec family;
			at: #modelTag put: modelSpec tag;
			at: #modelLabel put: modelSpec label;
			yourself).
]
