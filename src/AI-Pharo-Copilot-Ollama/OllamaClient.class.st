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
      defaultModelFullName := 'codellama:7b' ]  "safe fallback"
]

{ #category : 'operations' }
OllamaClient >> generate: aPromptString [ 

  | payload resp |
  payload := Dictionary new
    at: #model put: modelSpec fullName;
    at: #prompt put: aPromptString;
    at: #stream put: stream;
    yourself.
  format ifNotNil: [ payload at: #format put: format ].
  (options isEmpty) ifFalse: [ payload at: #options put: options ].

  resp := transport postJsonAt: 'api/generate' body: payload.
  ^ self normalizeResponse: resp
]

{ #category : 'as yet unclassified' }
OllamaClient >> generateForPrefix: prefixString suffix: suffixString [
  | prompt |
  prompt := '<PRE>', prefixString, '<SUF>', suffixString, '<MID>'.
  ^ self generate: prompt
]

{ #category : 'initialization' }
OllamaClient >> initialize [ 

  super initialize.
  transport := OAHttpTransport new.
  stream := false.
  options := Dictionary new.
  self useDefaultModel.
]

{ #category : 'operations' }
OllamaClient >> listModels [ 

  ^ transport getJsonAt: 'api/tags'

]

{ #category : 'private' }
OllamaClient >> normalizeResponse: resp [

  "If streaming=false, Ollama returns a dict; prefer #response or #content."
  (resp isKindOf: Dictionary) ifTrue: [
    ^ (resp at: #response ifAbsent: [
        resp at: #content ifAbsent: [ resp asString ] ]) ].
  ^ resp asString
]

{ #category : 'operations' }
OllamaClient >> optionAt: aKey [ 

  ^ options ifNil: [ nil ] ifNotNil: [ options at: aKey ifAbsent: [ nil ] ]
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
    options := aDictionary ifNil: [ Dictionary new ].
]

{ #category : 'operations' }
OllamaClient >> useDefaultModel [
  modelSpec := OModelRegistry current specByFullName:
                 (self class defaultModelFullName).
  modelSpec ifNil: [ modelSpec := OModelSpec family: 'codellama' tag: '7b' label: 'Code Llama 7B' ].
]
