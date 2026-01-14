"
OAHttpTransport is a small HTTP helper that talks to a local Ollama server and
returns Smalltalk objects by sending/receiving JSON over HTTP (GET and POST).
It centralizes host/port, JSON encoding/decoding, and default headers.
"
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

{ #category : 'private' }
OAHttpTransport >> applyDefaultHeadersTo: aClient [
	"Apply the transport default headers to the given Zinc client."

	defaultHeaders keysAndValuesDo: [ :key :value |
		aClient headerAt: key put: value ]
]

{ #category : 'requests' }
OAHttpTransport >> configureJsonOn: aClient [
	"Configure JSON accept/content reader/writer on the given Zinc client using the transport JSON reader/writer."

	aClient accept: ZnMimeType applicationJson.

	aClient contentWriter: [ :data |
		ZnEntity json: (jsonWriter toString: data) ].

	aClient contentReader: [ :entity |
		jsonReader fromString: entity contents ]
]

{ #category : 'accessing' }
OAHttpTransport >> defaultHeaders [
	"Answer the dictionary of headers applied to every request."

	^ defaultHeaders
]

{ #category : 'accessing' }
OAHttpTransport >> defaultHeaders: aDictionary [
	"Set the dictionary of headers applied to every request."

	defaultHeaders := aDictionary
]

{ #category : 'requests' }
OAHttpTransport >> getJsonAt: aPath [
	"Perform a GET request on the given path and answer the decoded JSON response."

	| client |
	client := self newJsonClientForPath: aPath.
	^ client get
]

{ #category : 'accessing' }
OAHttpTransport >> host [
	"Answer the configured host used for requests."

	^ host
]

{ #category : 'accessing' }
OAHttpTransport >> host: anObject [
	"Set the host used for requests."

	host := anObject
]

{ #category : 'initialization' }
OAHttpTransport >> initialize [
	"Initialize the transport with settings (host/port), JSON reader/writer, and an empty default header set."

	super initialize.
	host := CopilotSettings host.
	port := CopilotSettings port.
	defaultHeaders := Dictionary new.
	jsonReader := ZnUtils defaultJSONReader.
	jsonWriter := ZnUtils defaultJSONWriter
]

{ #category : 'accessing' }
OAHttpTransport >> jsonReader [
	"Answer the JSON reader used to decode responses."

	^ jsonReader
]

{ #category : 'accessing' }
OAHttpTransport >> jsonReader: anObject [
	"Set the JSON reader used to decode responses."

	jsonReader := anObject
]

{ #category : 'accessing' }
OAHttpTransport >> jsonWriter [
	"Answer the JSON writer used to encode request bodies."

	^ jsonWriter
]

{ #category : 'accessing' }
OAHttpTransport >> jsonWriter: anObject [
	"Set the JSON writer used to encode request bodies."

	jsonWriter := anObject
]

{ #category : 'requests' }
OAHttpTransport >> newJsonClientForPath: aPath [
	"Create and configure a Zinc client for JSON REST calls to the configured host/port and the given path."

	| client |
	client := ZnClient new.
	client forJsonREST.
	client host: host; port: port; path: aPath.

	self applyDefaultHeadersTo: client.
	self configureJsonOn: client.

	^ client
]

{ #category : 'accessing' }
OAHttpTransport >> port [
	"Answer the configured port used for requests."

	^ port
]

{ #category : 'accessing' }
OAHttpTransport >> port: anObject [
	"Set the port used for requests."

	port := anObject
]

{ #category : 'requests' }
OAHttpTransport >> postJsonAt: aPath body: aDictionary [
	"Perform a POST request on the given path with the given Smalltalk object as JSON body, answering the decoded JSON response."

	| client |
	client := self newJsonClientForPath: aPath.
	client contents: aDictionary.
	^ client post
]
