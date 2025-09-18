Class {
	#name : 'OllamaClientTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
OllamaClientTest >> testGenerateBuildsCorrectPayload [
    | client mock payload |
    client := OllamaClient new.
    mock := OAHttpTransportMockExtended new.
    client instVarNamed: 'transport' put: mock.

    client generate: 'test prompt'.

    payload := mock lastBody.

    "Model"
    self assert: (payload at: #model)
         equals: (client instVarNamed: 'modelSpec') fullName.

    "Prompt"
    self assert: (payload at: #prompt)
         equals: 'test prompt'.

    "Stream flag"
    self assert: (payload at: #stream)
         equals: false

]

{ #category : 'tests' }
OllamaClientTest >> testGenerateForPrefixSuffixBuildsPrompt [

	| client mock prefix suffix payload expected |
	client := OllamaClient new.
	mock := OAHttpTransportMock new.
	client instVarNamed: 'transport' put: mock.
	prefix := 'foo'.
	suffix := 'bar'.
	client generateForPrefix: prefix suffix: suffix.
	payload := mock lastBody.
	expected := CopilotSettings fimTemplate format: { prefix. suffix }.
  self assert: (payload at: #prompt) equals: expected.
	self assert: ((payload at: #options) at: #task) equals: 'fill-in-the-middle'.
	self assert: client options isEmpty
]

{ #category : 'tests' }
OllamaClientTest >> testGenerateIncludesFormatWhenSet [
	| client mock payload |
	client := OllamaClient new.
	client instVarNamed: 'format' put: 'json'.
	mock := OAHttpTransportMockExtended new.
	client instVarNamed: 'transport' put: mock.
	
	client generate: 'test'.
	
	payload := mock lastBody.
	self assert: (payload at: #format) equals: 'json'
]

{ #category : 'tests' }
OllamaClientTest >> testGenerateIncludesOptionsWhenNotEmpty [
	| client mock payload |
	client := OllamaClient new.
	client optionAt: #temperature put: 0.7.
	mock := OAHttpTransportMockExtended new.
	client instVarNamed: 'transport' put: mock.
	
	client generate: 'test'.
	
	payload := mock lastBody.
	self assert: ((payload at: #options) at: #temperature) equals: 0.7
]

{ #category : 'tests' }
OllamaClientTest >> testGenerateUsesCorrectEndpoint [
	| client mock |
	client := OllamaClient new.
	mock := OAHttpTransportMockExtended new.
	client instVarNamed: 'transport' put: mock.
	
	client generate: 'test'.
	
	self assert: mock lastPath equals: 'api/generate'
]

{ #category : 'tests' }
OllamaClientTest >> testInitializeUsesCopilotSettingsModel [
    | old client |
    old := CopilotSettings modelName.
    [
        CopilotSettings modelName: 'codellama:7b'.
        client := OllamaClient new.
        self assert: (client instVarNamed: 'modelSpec') fullName equals: 'codellama:7b'.
    ] ensure: [ CopilotSettings modelName: old ].
]

{ #category : 'tests' }
OllamaClientTest >> testListModelsUsesApiTags [

    | client mock |
    client := OllamaClient new.
    mock := OAHttpTransportMock new.
    client instVarNamed: 'transport' put: mock.
    client listModels.
    self assert: mock lastPath equals: 'api/tags'.
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponseHandlesComplexDictionary [
	| client response result |
	client := OllamaClient new.
	response := Dictionary new
		at: #model put: 'codellama';
		at: #response put: 'actual content';
		at: #done put: true;
		yourself.
		
	result := client normalizeResponse: response.
	self assert: result equals: 'actual content'
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponseHandlesJsonString [
	| client jsonString result |
	client := OllamaClient new.
	jsonString := '{"response": "parsed content", "done": true}'.
	
	result := client normalizeResponse: jsonString.
	self assert: result equals: 'parsed content'
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponseHandlesMalformedJson [
	| client malformedJson result |
	client := OllamaClient new.
	malformedJson := '{"response": unclosed'.
	
	result := client normalizeResponse: malformedJson.
	self assert: result equals: malformedJson
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponseHandlesNonDictionary [
	| client result |
	client := OllamaClient new.
	
	result := client normalizeResponse: 123.
	self assert: result equals: '123'
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponseHandlesStringContentKey [

    | client dict result |
    client := OllamaClient new.
    dict := Dictionary new
        at: 'content' put: 'bar';
        yourself.
    result := client normalizeResponse: dict.
    self assert: result equals: 'bar'.
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponseHandlesStringResponseKey [

    | client dict result |
    client := OllamaClient new.
    dict := Dictionary new
        at: 'response' put: 'foo';
        yourself.
    result := client normalizeResponse: dict.
    self assert: result equals: 'foo'.
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponsePrefersResponse [

    | client dict result |
    client := OllamaClient new.
    dict := Dictionary new
        at: #response put: 'foo';
        at: #content put: 'bar';
        yourself.
    result := client normalizeResponse: dict.
    self assert: result equals: 'foo'.
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponseUsesContent [

    | client dict result |
    client := OllamaClient new.
    dict := Dictionary new
        at: #content put: 'bar';
        yourself.
    result := client normalizeResponse: dict.
    self assert: result equals: 'bar'.
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponseUsesString [

    | client result |
    client := OllamaClient new.
    result := client normalizeResponse: 'baz'.
    self assert: result equals: 'baz'.
]

{ #category : 'tests' }
OllamaClientTest >> testOptionAtPutAndGet [

    | client |
    client := OllamaClient new.
    client optionAt: #temperature put: 0.5.
    self assert: (client optionAt: #temperature) equals: 0.5.
]

{ #category : 'tests' }
OllamaClientTest >> testOptionAtReturnsNil [

    | client |
    client := OllamaClient new.
    self assert: (client optionAt: #missing) isNil.
]

{ #category : 'tests' }
OllamaClientTest >> testOptionsDefaultEmpty [

    | client |
    client := OllamaClient new.
    self assert: client options isEmpty.
]

{ #category : 'tests' }
OllamaClientTest >> testOptionsSetterNilCreatesEmptyDictionary [

    | client |
    client := OllamaClient new.
    client options: nil.
    self assert: client options isEmpty.
]

{ #category : 'tests' }
OllamaClientTest >> testOptionsSetterStoresDictionary [

    | client dict |
    client := OllamaClient new.
    dict := Dictionary new
        at: #temperature put: 0.8;
        yourself.
    client options: dict.
    self assert: client options identicalTo: dict.
]

{ #category : 'tests' }
OllamaClientTest >> testUseModelNamedWithComplexName [
	| client spec |
	client := OllamaClient new.
	client useModelNamed: 'llama2:13b-chat'.
	
	spec := client instVarNamed: 'modelSpec'.
	self assert: spec family equals: 'llama2'.
	self assert: spec tag equals: '13b-chat'.
	self assert: spec fullName equals: 'llama2:13b-chat'
]

{ #category : 'tests' }
OllamaClientTest >> testUseModelNamedWithSimpleName [
	| client spec |
	client := OllamaClient new.
	client useModelNamed: 'llama2'.
	
	spec := client instVarNamed: 'modelSpec'.
	self assert: spec family equals: 'llama2'.
	self assert: spec tag isNil.
	self assert: spec fullName equals: 'llama2'
]
