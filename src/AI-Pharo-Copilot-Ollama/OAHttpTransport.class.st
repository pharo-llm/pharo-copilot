Class {
	#name : 'OAHttpTransport',
	#superclass : 'Object',
	#instVars : [
		'host',
		'port',
		'defaultHeaders',
		'jsonReader',
		'jsonWriter'
	],
	#category : 'AI-Pharo-Copilot-Ollama',
	#package : 'AI-Pharo-Copilot-Ollama'
}

{ #category : 'accessing' }
OAHttpTransport >> defaultHeaders [

	^ defaultHeaders
]

{ #category : 'accessing' }
OAHttpTransport >> defaultHeaders: anObject [

	defaultHeaders := anObject
]

{ #category : 'initialization' }
OAHttpTransport >> getJsonAt: aPath [

  | cl |
  cl := ZnEasy client.
  cl forJsonREST; host: host; port: port; path: aPath.
  ^ cl get
]

{ #category : 'accessing' }
OAHttpTransport >> host [

	^ host
]

{ #category : 'accessing' }
OAHttpTransport >> host: anObject [

	host := anObject
]

{ #category : 'initialization' }
OAHttpTransport >> initialize [ 

  super initialize.
  host := '127.0.0.1'.
  port := 11434.
  defaultHeaders := Dictionary new.
  jsonReader := ZnUtils defaultJSONReader.
  jsonWriter := ZnUtils defaultJSONWriter.
]

{ #category : 'accessing' }
OAHttpTransport >> jsonReader [

	^ jsonReader
]

{ #category : 'accessing' }
OAHttpTransport >> jsonReader: anObject [

	jsonReader := anObject
]

{ #category : 'accessing' }
OAHttpTransport >> jsonWriter [

	^ jsonWriter
]

{ #category : 'accessing' }
OAHttpTransport >> jsonWriter: anObject [

	jsonWriter := anObject
]

{ #category : 'accessing' }
OAHttpTransport >> port [

	^ port
]

{ #category : 'accessing' }
OAHttpTransport >> port: anObject [

	port := anObject
]

{ #category : 'initialization' }
OAHttpTransport >> postJsonAt: aPath body: aDictionary [ 

  | cl |
  cl := ZnClient new.
  cl accept: ZnMimeType applicationJson.
  cl contentWriter: [:data | ZnEntity json: (jsonWriter toString: data) ].
  cl host: host; port: port; path: aPath.
  cl forJsonREST.
  cl contentReader: [:entity | jsonReader fromString: entity contents ].
  ^ cl post: aDictionary
]
