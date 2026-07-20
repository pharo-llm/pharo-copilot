Class {
	#name : 'OllamaClientTest',
	#superclass : 'CopilotMockModelTestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
OllamaClientTest >> testGenerateBuildsCorrectPayload [
    | client mock payload |
    client := CoPCOllamaClient new.
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
OllamaClientTest >> testGenerateForPrefixPlacesInteractionHistoryBeforeFimPrompt [

	| client mock payload prompt context historyIndex fimIndex middleIndex oldFactory stub |
	oldFactory := CopilotSettings ollamaClientFactory.
	[
		stub := OllamaClientStub new
			withResponse: (Dictionary new
				at: #template put: CoPCOllamaClient defaultFimGenerationTemplate;
				yourself).
		CopilotSettings ollamaClientFactory: [ stub ].
		CopilotSettings clearCachedModelMetadata.

		client := CoPCOllamaClient new.
		mock := OAHttpTransportMockExtended new.
		mock mockResponse: (Dictionary new at: #response put: 'completion'; yourself).
		client instVarNamed: 'transport' put: mock.

		context := '<|repo_name|>Sample', String lf,
			'<|file_sep|>Sample', String lf,
			'Class { #name : #Sample }', String lf,
			'<|file_sep|>IDE interaction history', String lf,
			'Current selection: Sample', String lf.

		client generateForPrefix: 'self ' suffix: ' yourself' context: context.

		payload := mock lastBody.
		prompt := payload at: #prompt.
		historyIndex := prompt findString: '<|file_sep|>IDE interaction history' startingAt: 1.
		fimIndex := prompt findString: '<|fim_prefix|>' startingAt: 1.
		middleIndex := prompt findString: '<|fim_middle|>' startingAt: 1.

		self assert: (payload at: #raw) equals: true.
		self deny: (payload includesKey: #context).
		self assert: historyIndex > 0.
		self assert: fimIndex > 0.
		self assert: middleIndex > 0.
		self assert: historyIndex < fimIndex.
		self assert: fimIndex < middleIndex
	] ensure: [
		CopilotSettings ollamaClientFactory: oldFactory.
		CopilotSettings clearCachedModelMetadata ]
]

{ #category : 'tests' }
OllamaClientTest >> testGenerateForPrefixReusesFimTemplateWithinClient [

	| client mock oldFactory stub |
	oldFactory := CopilotSettings ollamaClientFactory.
	[
		stub := OllamaClientStub new
			withResponse: (Dictionary new
				at: #template put: CoPCOllamaClient defaultFimGenerationTemplate;
				yourself).
		CopilotSettings ollamaClientFactory: [ stub ].
		CopilotSettings clearCachedModelMetadata.

		client := CoPCOllamaClient new.
		mock := OAHttpTransportMockExtended new.
		mock mockResponse: (Dictionary new at: #response put: 'completion'; yourself).
		client instVarNamed: 'transport' put: mock.

		client generateForPrefix: 'self ' suffix: '' context: ''.
		CopilotSettings clearCachedModelMetadata.
		client generateForPrefix: 'self ' suffix: '' context: ''.

		self assert: stub callCount equals: 1
	] ensure: [
		CopilotSettings ollamaClientFactory: oldFactory.
		CopilotSettings clearCachedModelMetadata ]
]

{ #category : 'tests' }
OllamaClientTest >> testGenerateIncludesFormatWhenSet [
	| client mock payload |
	client := CoPCOllamaClient new.
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
        client := CoPCOllamaClient new.
        client optionAt: #temperature put: 0.7.
        mock := OAHttpTransportMockExtended new.
        client instVarNamed: 'transport' put: mock.

        client generate: 'test'.

        payload := mock lastBody.
        self assert: ((payload at: #options) at: #temperature) equals: 0.7
]

{ #category : 'tests' }
OllamaClientTest >> testGenerateReturnsNullModelMessageWhenNullSelected [

        | client mock oldModel response |
        oldModel := CopilotSettings modelName.
        [
                CopilotSettings modelName: CopilotSettings nullModelFullName.
                client := CoPCOllamaClient new.
                mock := OAHttpTransportMockExtended new.
                client instVarNamed: 'transport' put: mock.
                response := client generate: 'anything'.
                self assert: response equals: CoPCOllamaClient nullModelResponseString.
                self assert: mock callCount equals: 0
        ] ensure: [ CopilotSettings modelName: oldModel ]
]

{ #category : 'tests' }
OllamaClientTest >> testGenerateUsesCorrectEndpoint [
	| client mock |
	client := CoPCOllamaClient new.
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
		CopilotSettings modelName: OTestModelSupport mockModelName.
		client := CoPCOllamaClient new.
		self assert: (client instVarNamed: 'modelSpec') fullName equals: OTestModelSupport mockModelName ] ensure: [ CopilotSettings modelName: old ]
]

{ #category : 'tests' }
OllamaClientTest >> testListModelsUsesApiTags [

    | client mock |
    client := CoPCOllamaClient new.
    mock := OAHttpTransportMock new.
    client instVarNamed: 'transport' put: mock.
    client listModels.
    self assert: mock lastPath equals: 'api/tags'.
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponseHandlesComplexDictionary [

	| client response result |
	client := CoPCOllamaClient new.
	response := Dictionary new
		            at: #model put:  OTestModelSupport mockModelName;
		            at: #response put: 'actual content';
		            at: #done put: true;
		            yourself.

	result := client normalizeResponse: response.
	self assert: result equals: 'actual content'
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponseHandlesJsonString [
	| client jsonString result |
	client := CoPCOllamaClient new.
	jsonString := '{"response": "parsed content", "done": true}'.
	
	result := client normalizeResponse: jsonString.
	self assert: result equals: 'parsed content'
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponseHandlesMalformedJson [
	| client malformedJson result |
	client := CoPCOllamaClient new.
	malformedJson := '{"response": unclosed'.
	
	result := client normalizeResponse: malformedJson.
	self assert: result equals: malformedJson
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponseHandlesNonDictionary [
	| client result |
	client := CoPCOllamaClient new.
	
	result := client normalizeResponse: 123.
	self assert: result equals: '123'
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponseHandlesStringContentKey [

    | client dict result |
    client := CoPCOllamaClient new.
    dict := Dictionary new
        at: 'content' put: 'bar';
        yourself.
    result := client normalizeResponse: dict.
    self assert: result equals: 'bar'.
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponseHandlesStringResponseKey [

    | client dict result |
    client := CoPCOllamaClient new.
    dict := Dictionary new
        at: 'response' put: 'foo';
        yourself.
    result := client normalizeResponse: dict.
    self assert: result equals: 'foo'.
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponsePrefersResponse [

    | client dict result |
    client := CoPCOllamaClient new.
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
    client := CoPCOllamaClient new.
    dict := Dictionary new
        at: #content put: 'bar';
        yourself.
    result := client normalizeResponse: dict.
    self assert: result equals: 'bar'.
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponseUsesString [

    | client result |
    client := CoPCOllamaClient new.
    result := client normalizeResponse: 'baz'.
    self assert: result equals: 'baz'.
]

{ #category : 'tests' }
OllamaClientTest >> testOptionAtPutAndGet [

    | client |
    client := CoPCOllamaClient new.
    client optionAt: #temperature put: 0.5.
    self assert: (client optionAt: #temperature) equals: 0.5.
]

{ #category : 'tests' }
OllamaClientTest >> testOptionAtReturnsNil [

    | client |
    client := CoPCOllamaClient new.
    self assert: (client optionAt: #missing) isNil.
]

{ #category : 'tests' }
OllamaClientTest >> testOptionsSetterNilCreatesEmptyDictionary [

    | client |
    client := CoPCOllamaClient new.
    client options: nil.
    self assert: client options isEmpty.
]

{ #category : 'tests' }
OllamaClientTest >> testOptionsSetterStoresDictionary [

    | client dict |
    client := CoPCOllamaClient new.
    dict := Dictionary new
        at: #temperature put: 0.8;
        yourself.
    client options: dict.
    self assert: client options identicalTo: dict.
]

{ #category : 'tests' }
OllamaClientTest >> testPullModelWithProgressRaisesOnErrorEvent [

	| client mock |
	client := CoPCOllamaClient new.
	mock := OAHttpTransportMockExtended new.
	mock streamingLines: { '{"error":"model not found"}' }.
	client instVarNamed: 'transport' put: mock.

	self
		should: [
			client
				pullModelNamed: OTestModelSupport mockModelName
				timeoutSeconds: 42
				progress: [ :event | event ] ]
		raise: Error
]

{ #category : 'tests' }
OllamaClientTest >> testPullModelWithProgressReturnsFalseWithoutSuccess [

	| client mock result events |
	client := CoPCOllamaClient new.
	mock := OAHttpTransportMockExtended new.
	mock streamingLines: { '{"status":"pulling manifest"}' }.
	client instVarNamed: 'transport' put: mock.
	events := OrderedCollection new.

	result := client
		pullModelNamed: OTestModelSupport mockModelName
		timeoutSeconds: 42
		progress: [ :event | events add: event ].

	self deny: result.
	self assert: events size equals: 1.
	self assert: mock lastPath equals: 'api/pull'.
	self assert: (mock lastBody at: #name) equals: OTestModelSupport mockModelName.
	self assert: (mock lastBody at: #stream) equals: true.
	self assert: mock lastTimeoutSeconds equals: 42
]

{ #category : 'tests' }
OllamaClientTest >> testPullModelWithProgressReturnsTrueOnSuccess [

	| client mock result events |
	client := CoPCOllamaClient new.
	mock := OAHttpTransportMockExtended new.
	mock streamingLines: {
		'{"status":"pulling manifest"}'.
		'{"status":"success"}' }.
	client instVarNamed: 'transport' put: mock.
	events := OrderedCollection new.

	result := client
		pullModelNamed: OTestModelSupport mockModelName
		timeoutSeconds: 42
		progress: [ :event | events add: event ].

	self assert: result.
	self assert: events size equals: 2
]

{ #category : 'tests' }
OllamaClientTest >> testShowModelUsesApiShow [

	| client mock response |
	client := CoPCOllamaClient new.
	mock := OAHttpTransportMockExtended new.
	response := Dictionary new
		            at: #template put: 'value';
		            yourself.
	mock mockResponse: response.
	client instVarNamed: 'transport' put: mock.

	self assert: (client showModelNamed: OTestModelSupport mockModelName) identicalTo: response.
	self assert: mock lastPath equals: 'api/show'.
	self assert: (mock lastBody at: #model) equals: OTestModelSupport mockModelName
]

{ #category : 'tests' }
OllamaClientTest >> testUseModelNamedWithComplexName [
	| client spec |
	client := CoPCOllamaClient new.
	client useModelNamed: 'llama2:13b-chat'.
	
	spec := client instVarNamed: 'modelSpec'.
	self assert: spec family equals: 'llama2'.
	self assert: spec tag equals: '13b-chat'.
	self assert: spec fullName equals: 'llama2:13b-chat'
]

{ #category : 'tests' }
OllamaClientTest >> testUseModelNamedWithSimpleName [
	| client spec |
	client := CoPCOllamaClient new.
	client useModelNamed: 'llama2'.
	
	spec := client instVarNamed: 'modelSpec'.
	self assert: spec family equals: 'llama2'.
	self assert: spec tag isNil.
	self assert: spec fullName equals: 'llama2'
]
