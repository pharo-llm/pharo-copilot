"
HTTP helper that talks to a local Ollama server with JSON bodies.
"
Class {
	#name : 'CoPCOAHttpTransport',
	#superclass : 'Object',
	#instVars : [
		'host',
		'port',
		'jsonReader',
		'jsonWriter'
	],
	#category : 'AI-Pharo-Copilot-Ollama',
	#package : 'AI-Pharo-Copilot-Ollama'
}

{ #category : 'initialization' }
CoPCOAHttpTransport >> initialize [

	super initialize.
	host := CopilotSettings host.
	port := CopilotSettings port.
	jsonReader := ZnUtils defaultJSONReader.
	jsonWriter := ZnUtils defaultJSONWriter
]

{ #category : 'accessing' }
CoPCOAHttpTransport >> host [ ^ host ]

{ #category : 'accessing' }
CoPCOAHttpTransport >> host: anObject [ host := anObject ]

{ #category : 'accessing' }
CoPCOAHttpTransport >> port [ ^ port ]

{ #category : 'accessing' }
CoPCOAHttpTransport >> port: anObject [ port := anObject ]

{ #category : 'private' }
CoPCOAHttpTransport >> newJsonClientForPath: aPath [

	| client |
	client := ZnEasy client.
	client forJsonREST.
	client
		host: host;
		port: port;
		path: aPath.
	(client respondsTo: #timeout:) ifTrue: [
		client timeout: CopilotSettings requestTimeoutSeconds ].

	client accept: ZnMimeType applicationJson.
	client contentWriter: [ :data | ZnEntity json: (jsonWriter toString: data) ].
	client contentReader: [ :entity | jsonReader fromString: entity contents ].
	^ client
]

{ #category : 'requests' }
CoPCOAHttpTransport >> postJsonAt: aPath body: aDictionary [

	| client |
	client := self newJsonClientForPath: aPath.
	client contents: aDictionary.
	^ client post
]
