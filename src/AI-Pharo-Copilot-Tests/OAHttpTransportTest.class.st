Class {
	#name : 'OAHttpTransportTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
OAHttpTransportTest >> replaceGlobal: aSymbol with: aReplacementClass during: aBlock [
    | original |
    original := Smalltalk at: aSymbol.

    [
        Smalltalk at: aSymbol put: aReplacementClass.
        aBlock value
    ] ensure: [
        Smalltalk at: aSymbol put: original
    ]
]

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
OAHttpTransportTest >> testGetJsonUsesConfiguredHostAndPort [ 

    self replaceGlobal: #ZnEasy with: OAHttpTransportEasyDouble during: [
        | transport result client |
        OAHttpTransportEasyDouble reset.
        OAHttpTransportClientDouble nextGetResult: (Dictionary newFromPairs: { 'ok'. true }).

        transport := OAHttpTransport new.
        transport host: 'api.internal'.
        transport port: 5151.

        result := transport getJsonAt: '/models'.
        client := OAHttpTransportClientDouble lastCreated.

        self assert: client host equals: 'api.internal'.
        self assert: client port equals: 5151.
        self assert: client path equals: '/models'.
        self assert: client jsonRestEnabled.
        self assert: result equals: OAHttpTransportClientDouble nextGetResult
]
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
OAHttpTransportTest >> testInitializationUsesCopilotSettingsHostAndPort [
    | transport originalHost originalPort |
    originalHost := CopilotSettings host.
    originalPort := CopilotSettings port.
    [
        CopilotSettings host: '10.0.0.42'.
        CopilotSettings port: 4242.

        transport := OAHttpTransport new.

        self assert: transport host equals: '10.0.0.42'.
        self assert: transport port equals: 4242
    ] ensure: [
        CopilotSettings host: originalHost.
        CopilotSettings port: originalPort
    ]
]

{ #category : 'tests' }
OAHttpTransportTest >> testJsonReaderWriterInitialization [
	| transport |
	transport := OAHttpTransport new.
	
	self assert: transport jsonReader notNil.
	self assert: transport jsonWriter notNil
]

{ #category : 'tests' }
OAHttpTransportTest >> testPostJsonUsesCustomReaderAndWriter [

	self
		replaceGlobal: #ZnClient
		with: OAHttpTransportClientDouble
		during: [
				| transport writer reader payload result client |
				OAHttpTransportClientDouble reset.
				writer := OAHttpTransportJsonWriterDouble new.
				reader := OAHttpTransportJsonReaderDouble new.
				payload := Dictionary newFromPairs: { 'prompt'. 'generate' }.

				transport := OAHttpTransport new.
				transport host: 'post.host'.
				transport port: 4040.
				transport jsonWriter: writer.
				transport jsonReader: reader.

				result := transport postJsonAt: '/generate' body: payload.
				client := OAHttpTransportClientDouble lastCreated.
				self assert: writer lastWrittenObject identicalTo: payload.
				self assert: reader lastString equals: 'encoded:1'.
				self assert: client postedBody identicalTo: payload.
				self assert: client host equals: 'post.host'.
				self assert: client port equals: 4040.
				self assert: client path equals: '/generate'.
				self assert: result equals: reader lastResult ]
]

{ #category : 'tests' }
OAHttpTransportTest >> testSeparateDefaultHeadersPerInstance [

    | first second |
    first := OAHttpTransport new.
    second := OAHttpTransport new.

    first defaultHeaders at: 'X-Test' put: 'one'.

    self assert: (first defaultHeaders at: 'X-Test') equals: 'one'.
    self assert: (second defaultHeaders includesKey: 'X-Test') not
]
