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

  ^ 'no output, please configure.'
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

{ #category : 'operations' }
OllamaClient >> generate: aPromptString [

        | payload resp normalized |
        self isNullModel ifTrue: [
                CoCopilotLogger
                        logBackEndEvent: 'Null model responded to completion request'
                        details: (Dictionary new
                                at: #modelFullName put: (modelSpec ifNil: [ self class nullModelFullName ] ifNotNil: [ modelSpec fullName ]);
                                yourself).
                ^ self class nullModelResponseString ].
        payload := Dictionary new
                           at: #model put: modelSpec fullName;
                           at: #prompt put: aPromptString;
                           at: #stream put: stream;
                           yourself.
	format ifNotNil: [ payload at: #format put: format ].
	options isEmpty ifFalse: [ payload at: #options put: options ].
	CoCopilotLogger logBackEndEvent: 'Dispatching generate request' details: (Dictionary new
			 at: #endpoint put: 'api/generate';
			 at: #modelFullName put: modelSpec fullName;
			 at: #payload put: payload;
			 at: #optionsSnapshot put: options copy;
			 yourself).

	resp := transport postJsonAt: 'api/generate' body: payload.
	CoCopilotLogger logBackEndEvent: 'Received generate response' details: (Dictionary new
			 at: #responseClass put: resp class name;
			 at: #rawResponse put: ([ resp asString ]
					  on: Error
					  do: [ resp printString ]);
			 yourself).

	normalized := self normalizeResponse: resp.
	CoCopilotLogger logBackEndEvent: 'Normalized generate response' details: (Dictionary new
			 at: #normalizedResponse put: normalized;
			 at: #normalizedLength put: normalized size;
			 yourself).
	^ normalized
]

{ #category : 'as yet unclassified' }
OllamaClient >> generateForPrefix: prefixString suffix: suffixString [

	| prompt originalOptions response |
	CoCopilotLogger logBackEndEvent: 'Preparing fill-in-the-middle request' details: (Dictionary new
			 at: #prefix put: prefixString;
			 at: #suffix put: suffixString;
			 at: #template put: CopilotSettings fimTemplate;
			 at: #optionsBefore put: options copy;
			 yourself).

	prompt := CopilotSettings fimTemplate format: {
			          prefixString.
			          suffixString }.
        originalOptions := options copy.
        options at: #task put: 'fill-in-the-middle'.
        CoCopilotLogger logBackEndEvent: 'Prepared fill-in-the-middle prompt' details: (Dictionary new
                         at: #finalPrompt put: prompt;
                         at: #promptLength put: prompt size;
                         yourself).
        CoCopilotLogger logBackEndEvent: 'Augmented Ollama options for fill-in-the-middle' details: (Dictionary new
                         at: #optionsAfter put: options;
                         yourself).
	response := self generate: prompt.
	options := originalOptions.
	CoCopilotLogger logBackEndEvent: 'Restored Ollama options after fill-in-the-middle' details: (Dictionary new
			 at: #optionsRestored put: options;
			 yourself).
	^ response
]

{ #category : 'initialization' }
OllamaClient >> initialize [

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

{ #category : 'operations' }
OllamaClient >> isNullModel [

        modelSpec ifNil: [ ^ false ].
        ^ modelSpec fullName = self class nullModelFullName
]

{ #category : 'operations' }
OllamaClient >> listModels [

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
  CoCopilotLogger
        logBackEndEvent: 'Reading Ollama option'
        details: (Dictionary new
                at: #key put: aKey;
                at: #value put: value;
                yourself).
  ^ value
]

{ #category : 'private' }
OllamaClient >> optionAt: aKey put: aValue [

	options ifNil: [ options := Dictionary new ].
	  CoCopilotLogger
        logBackEndEvent: 'Updating Ollama option'
        details: (Dictionary new
                at: #key put: aKey;
                at: #value put: aValue;
                yourself).
	^ options at: aKey put: aValue
]

{ #category : 'operations' }
OllamaClient >> options [
    CoCopilotLogger
        logBackEndEvent: 'Accessing Ollama options snapshot'
        details: (Dictionary new
                at: #options put: options;
                yourself).

	^ options
]

{ #category : 'operations' }
OllamaClient >> options: aDictionary [
    CoCopilotLogger
        logBackEndEvent: 'Replacing Ollama options'
        details: (Dictionary new
                at: #newOptions put: (aDictionary ifNil: [ Dictionary new ]);
                yourself).
	options := aDictionary ifNil: [ Dictionary new ]
]

{ #category : 'private' }
OllamaClient >> parseJsonSafely: aString [

        ^ [ STONJSON fromString: aString ] on: Error do: [ nil ]
]

{ #category : 'operations' }
OllamaClient >> pullModelNamed: aString [

  | payload response |
  payload := Dictionary new
                 at: #name put: aString;
                 yourself.
  CoCopilotLogger
        logBackEndEvent: 'Requesting Ollama model install'
        details: (Dictionary new
                at: #endpoint put: 'api/pull';
                at: #model put: aString;
                at: #payload put: payload;
                yourself).
  response := transport postJsonAt: 'api/pull' body: payload.
  CoCopilotLogger
        logBackEndEvent: 'Ollama model install request acknowledged'
        details: (Dictionary new
                at: #model put: aString;
                at: #responseClass put: (response ifNotNil: [ response class name ] ifNil: [ 'nil' ]);
                yourself).
  ^ response
]

{ #category : 'as yet unclassified' }
OllamaClient >> showModelNamed: aModelFullName [

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
            at: #responseClass put: response class name;
            at: #rawResponse put: ([ response asString ] on: Error do: [ response printString ]);
            yourself).
    ^ response
]

{ #category : 'operations' }
OllamaClient >> useDefaultModel [

	        CoCopilotLogger
                logBackEndEvent: 'Switching to default Ollama model'
                details: (Dictionary new
                        at: #defaultModelFullName put: self class defaultModelFullName;
                        yourself).
        self useModelNamed: self class defaultModelFullName
]

{ #category : 'operations' }
OllamaClient >> useModelNamed: aString [

	| tokens family tag |
	CoCopilotLogger logBackEndEvent: 'Requested Ollama model change' details: (Dictionary new
			 at: #requestedName put: aString;
			 yourself).
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
	CoCopilotLogger logBackEndEvent: 'Applied Ollama model change' details: (Dictionary new
			 at: #resolvedName put: modelSpec fullName;
			 at: #modelFamily put: modelSpec family;
			 at: #modelTag put: modelSpec tag;
			 at: #modelLabel put: modelSpec label;
			 yourself)
]
