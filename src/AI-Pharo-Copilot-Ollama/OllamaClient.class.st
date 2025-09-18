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

  ^ defaultModelFullName ifNil: [
      defaultModelFullName := 'codellama:7b-code' ]  "safe fallback"
]

{ #category : 'operations' }
OllamaClient >> generate: aPromptString [

	| payload resp normalized |
	payload := Dictionary new
		           at: #model put: modelSpec fullName;
		           at: #prompt put: aPromptString;
		           at: #stream put: stream;
		           yourself.
	format ifNotNil: [ payload at: #format put: format ].
	options isEmpty ifFalse: [ payload at: #options put: options ].
	  CoCopilotLogger
        logBackEndEvent: 'Dispatching generate request'
        details: (Dictionary new
                at: #endpoint put: 'api/generate';
                at: #modelFullName put: modelSpec fullName;
                at: #payload put: payload;
                at: #optionsSnapshot put: options copy;
                yourself).

	resp := transport postJsonAt: 'api/generate' body: payload.
	  CoCopilotLogger
        logBackEndEvent: 'Received generate response'
        details: (Dictionary new
                at: #responseClass put: resp class name;
                at: #rawResponse put: ([ resp asString ] on: Error do: [ resp printString ]);
                yourself).

  normalized := self normalizeResponse: resp.
  CoCopilotLogger
        logBackEndEvent: 'Normalized generate response'
        details: (Dictionary new
                at: #normalizedResponse put: normalized;
                at: #normalizedLength put: normalized size;
                yourself).
  ^ normalized
]

{ #category : 'as yet unclassified' }
OllamaClient >> generateForPrefix: prefixString suffix: suffixString [

        | prompt originalOptions response |
        CoCopilotLogger
                logBackEndEvent: 'Preparing fill-in-the-middle request'
                details: (Dictionary new
                        at: #prefix put: prefixString;
                        at: #suffix put: suffixString;
                        at: #template put: CopilotSettings fimTemplate;
                        at: #optionsBefore put: options copy;
                        yourself).
        prompt := CopilotSettings fimTemplate format: { prefixString. suffixString }.
        originalOptions := options copy.
        options at: #task put: 'fill-in-the-middle'.
        CoCopilotLogger
                logBackEndEvent: 'Augmented Ollama options for fill-in-the-middle'
                details: (Dictionary new
                        at: #optionsAfter put: options;
                        yourself).
        response := self generate: prompt.
        options := originalOptions.
        CoCopilotLogger
                logBackEndEvent: 'Restored Ollama options after fill-in-the-middle'
                details: (Dictionary new
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
  resp isString ifTrue: [
    [ | parsed |
      parsed := STONJSON fromString: resp.
      (parsed isKindOf: Dictionary) ifTrue: [
        ^ parsed at: #response ifAbsent: [
          parsed at: 'response' ifAbsent: [
            parsed at: #content ifAbsent: [
              parsed at: 'content' ifAbsent: [ resp ] ] ] ] ].
    ] on: Error do: [ "If parsing fails, return as is" ].
    ^ resp ].
  
  (resp isKindOf: Dictionary) ifTrue: [
    ^ resp at: #response ifAbsent: [
        resp at: 'response' ifAbsent: [
          resp at: #content ifAbsent: [
            resp at: 'content' ifAbsent: [ resp asString ] ] ] ] ].
            
  ^ resp asString
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

        | tokens |
        CoCopilotLogger
                logBackEndEvent: 'Requested Ollama model change'
                details: (Dictionary new
                        at: #requestedName put: aString;
                        yourself).
        modelSpec := OModelRegistry current specByFullName: aString.
        modelSpec ifNil: [
                tokens := aString findTokens: ':'.
                modelSpec := OModelSpec
                        family: tokens first
                        tag: (tokens size > 1 ifTrue: [ tokens second ] ifFalse: [ nil ])
                        label: aString ].
        CoCopilotLogger
                logBackEndEvent: 'Applied Ollama model change'
                details: (Dictionary new
                        at: #resolvedName put: modelSpec fullName;
                        at: #modelFamily put: modelSpec family;
                        at: #modelTag put: modelSpec tag;
                        at: #modelLabel put: modelSpec label;
                        yourself).
]
