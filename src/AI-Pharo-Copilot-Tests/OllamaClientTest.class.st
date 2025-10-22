Class {
	#name : 'OllamaClientTest',
	#superclass : 'CopilotMockModelTestCase',
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
OllamaClientTest >> testGenerateForPrefixSuffixCustomFileEmptyFallsBackToInlineTemplate [
        | client mock prefix suffix payload oldOption oldTemplate oldFile tempFile inlineTemplate |
        client := OllamaClient new.
        mock := OAHttpTransportMock new.
        client instVarNamed: 'transport' put: mock.
        prefix := 'left'.
        suffix := 'right'.
        oldOption := CopilotSettings fimTemplateOption.
        oldTemplate := CopilotSettings fimTemplate.
        oldFile := CopilotSettings customFimTemplateFile.
        tempFile := FileLocator temp / 'copilot-custom-fim-template-empty.tmpl'.
        inlineTemplate := 'INLINE<PRE>%1<SUF>%2<MID>'.
        [
                tempFile exists ifTrue: [ tempFile ensureDelete ].
                CopilotSettings fimTemplate: inlineTemplate.
                CopilotSettings fimTemplateOption: #inline.
                CopilotSettings customFimTemplateFile: tempFile.
                CopilotSettings fimTemplateOption: #customFile.
                self assert: tempFile exists.
                tempFile writeStreamDo: [ :stream | ].
                client generateForPrefix: prefix suffix: suffix.
                payload := mock lastBody.
                self assert: (payload at: #prompt) equals: 'INLINE<PRE>left<SUF>right<MID>'.
        ] ensure: [
                tempFile exists ifTrue: [ tempFile ensureDelete ].
                CopilotSettings fimTemplate: oldTemplate.
                CopilotSettings customFimTemplateFile: oldFile.
                CopilotSettings fimTemplateOption: oldOption
        ]
]

{ #category : 'tests' }
OllamaClientTest >> testGenerateForPrefixSuffixUsesCustomTemplate [

        | client mock prefix suffix payload old template |
        client := OllamaClient new.
        mock := OAHttpTransportMock new.
        client instVarNamed: 'transport' put: mock.
        prefix := '1'.
        suffix := '2'.
        old := CopilotSettings fimTemplate.
        template := '<<PRE>>%1<<SUF>>%2<<MID>>'.
        [
                CopilotSettings fimTemplate: template.
                client generateForPrefix: prefix suffix: suffix.
                payload := mock lastBody.
                self assert: (payload at: #prompt) equals: '<<PRE>>1<<SUF>>2<<MID>>'
        ] ensure: [ CopilotSettings fimTemplate: old ]
]

{ #category : 'tests' }
OllamaClientTest >> testGenerateForPrefixSuffixUsesCustomTemplateFilePathSetter [
        | client mock prefix suffix payload oldOption oldTemplate oldFile tempFile customTemplate |
        client := OllamaClient new.
        mock := OAHttpTransportMock new.
        client instVarNamed: 'transport' put: mock.
        prefix := 'sun'.
        suffix := 'moon'.
        oldOption := CopilotSettings fimTemplateOption.
        oldTemplate := CopilotSettings fimTemplate.
        oldFile := CopilotSettings customFimTemplateFile.
        tempFile := FileLocator temp / 'copilot-custom-fim-template-path.tmpl'.
        customTemplate := 'PATH<PRE>%1<SUF>%2<MID>'.
        [
                tempFile exists ifTrue: [ tempFile ensureDelete ].
                CopilotSettings fimTemplate: 'INLINE<PRE>%1<SUF>%2<MID>'.
                CopilotSettings fimTemplateOption: #inline.
                tempFile parent ensureCreateDirectory.
                tempFile ensureCreateFile.
                tempFile writeStreamDo: [ :stream | stream nextPutAll: customTemplate ].
                CopilotSettings customFimTemplateFilePath: tempFile fullName.
                CopilotSettings fimTemplateOption: #customFile.
                client generateForPrefix: prefix suffix: suffix.
                payload := mock lastBody.
                self assert: (payload at: #prompt) equals: 'PATH<PRE>sun<SUF>moon<MID>'.
        ] ensure: [
                tempFile exists ifTrue: [ tempFile ensureDelete ].
                CopilotSettings fimTemplate: oldTemplate.
                CopilotSettings customFimTemplateFile: oldFile.
                CopilotSettings fimTemplateOption: oldOption
        ]
]

{ #category : 'tests' }
OllamaClientTest >> testGenerateForPrefixSuffixUsesCustomTemplateSource [ 
        | client mock prefix suffix payload oldOption oldTemplate oldFile tempFile customTemplate |
        client := OllamaClient new.
        mock := OAHttpTransportMock new.
        client instVarNamed: 'transport' put: mock.
        prefix := 'alpha'.
        suffix := 'omega'.
        oldOption := CopilotSettings fimTemplateOption.
        oldTemplate := CopilotSettings fimTemplate.
        oldFile := CopilotSettings customFimTemplateFile.
        tempFile := FileLocator temp / 'copilot-custom-fim-template-source.tmpl'.
        customTemplate := 'FILE<PRE>%1<SUF>%2<MID>'.
        [
                tempFile exists ifTrue: [ tempFile ensureDelete ].
                CopilotSettings fimTemplate: 'INLINE<PRE>%1<SUF>%2<MID>'.
                CopilotSettings fimTemplateOption: #inline.
                CopilotSettings customFimTemplateFile: tempFile.
                tempFile parent ensureCreateDirectory.
                tempFile ensureCreateFile.
                tempFile writeStreamDo: [ :stream | stream nextPutAll: customTemplate ].
                CopilotSettings fimTemplateOption: #customFile.
                client generateForPrefix: prefix suffix: suffix.
                payload := mock lastBody.
                self assert: (payload at: #prompt) equals: 'FILE<PRE>alpha<SUF>omega<MID>'.
        ] ensure: [
                tempFile exists ifTrue: [ tempFile ensureDelete ].
                CopilotSettings fimTemplate: oldTemplate.
                CopilotSettings customFimTemplateFile: oldFile.
                CopilotSettings fimTemplateOption: oldOption
        ]
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
OllamaClientTest >> testGenerateReturnsNullModelMessageWhenNullSelected [

        | client mock oldModel response |
        oldModel := CopilotSettings modelName.
        [
                CopilotSettings modelName: CopilotSettings nullModelFullName.
                client := OllamaClient new.
                mock := OAHttpTransportMockExtended new.
                client instVarNamed: 'transport' put: mock.
                response := client generate: 'anything'.
                self assert: response equals: OllamaClient nullModelResponseString.
                self assert: mock callCount equals: 0
        ] ensure: [ CopilotSettings modelName: oldModel ]
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
		CopilotSettings modelName: OTestModelSupport mockModelName.
		client := OllamaClient new.
		self assert: (client instVarNamed: 'modelSpec') fullName equals: OTestModelSupport mockModelName ] ensure: [ CopilotSettings modelName: old ]
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
OllamaClientTest >> testShowModelUsesApiShow [

	| client mock response |
	client := OllamaClient new.
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
