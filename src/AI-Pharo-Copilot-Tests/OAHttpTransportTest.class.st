Class {
	#name : 'OAHttpTransportTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
OAHttpTransportTest >> testDefaultHeadersInitialization [

	| transport |
	transport := OAHttpTransport new.

	self assert: ((transport defaultHeaders) isKindOf: Dictionary).
	self assert: transport defaultHeaders isEmpty
]

{ #category : 'tests' }
OAHttpTransportTest >> testDefaultHostAndPort [
	| transport |
	transport := OAHttpTransport new.
	
	self assert: transport host equals: '127.0.0.1'.
	self assert: transport port equals: 11434
]

{ #category : 'tests' }
OAHttpTransportTest >> testHostPortSetters [
	| transport |
	transport := OAHttpTransport new.
	
	transport host: '192.168.1.1'.
	transport port: 8080.
	
	self assert: transport host equals: '192.168.1.1'.
	self assert: transport port equals: 8080
]

{ #category : 'tests' }
OAHttpTransportTest >> testJsonReaderWriterInitialization [
	| transport |
	transport := OAHttpTransport new.
	
	self assert: transport jsonReader notNil.
	self assert: transport jsonWriter notNil
]
