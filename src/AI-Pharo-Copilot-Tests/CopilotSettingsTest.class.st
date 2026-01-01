Class {
	#name : 'CopilotSettingsTest',
	#superclass : 'CopilotMockModelTestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CopilotSettingsTest >> testAutoInstallRunsWhenPharoCoderMissing [

    | stub modelName missingResponse availableResponse |
    modelName := 'missing-test-model:latest'.
    missingResponse := Dictionary new at: #models put: #(); yourself.
    availableResponse := Dictionary new
        at: #models put: { Dictionary new
            at: #name put: modelName;
            yourself };
        yourself.
    CopilotSettings withDefaultSettingsDo: [
        stub := OllamaClientStub new.
        stub withModelsResponses: { missingResponse. availableResponse }.
        CopilotSettings ollamaClientFactory: [ stub ].
        CopilotSettings modelName: modelName.
        CopilotSettings autoInstallModelScriptEnabled: true.
        self assert: CopilotSettings ensureSelectedModelAvailable.
        self assert: stub pullCount equals: 1.
        self assert: stub lastPulledModel equals: modelName.
    ]
]

{ #category : 'tests' }
CopilotSettingsTest >> testAutoInstallToggleDisablesScript [

    | stub modelName missingResponse |
    modelName := 'missing-test-model:latest'.
    missingResponse := Dictionary new at: #models put: #(); yourself.
    CopilotSettings withDefaultSettingsDo: [
        stub := OllamaClientStub new.
        stub withModelsResponse: missingResponse.
        CopilotSettings ollamaClientFactory: [ stub ].
        CopilotSettings modelName: modelName.
        CopilotSettings autoInstallModelScriptEnabled: false.
        self deny: CopilotSettings ensureSelectedModelAvailable.
        self assert: stub pullCount equals: 0.
        self assert: stub lastPulledModel isNil.
    ]
]

{ #category : 'tests' }
CopilotSettingsTest >> testAvailableModelName [

	| domain |
	domain := CopilotSettings availableModelNames.
	self assert: domain size > 0.
	self assert: (domain anySatisfy: [ :assoc | assoc key = OTestModelSupport mockModelLabel and: [ assoc value = OTestModelSupport mockModelName ] ]).
]

{ #category : 'tests' }
CopilotSettingsTest >> testAvailableProvidersContainsOnlyValidSymbols [
	| providers |
	providers := CopilotSettings availableProviders.
	
	self assert: providers isCollection.
	providers do: [ :provider |
		self assert: provider isSymbol ]
]

{ #category : 'tests' }
CopilotSettingsTest >> testAvailableProvidersIncludesOllama [
    self assert: (CopilotSettings availableProviders includes: #ollama).
]

{ #category : 'tests' }
CopilotSettingsTest >> testClearCachedModelMetadataForcesNextFetch [
    | stub oldFactory first second |
    stub := OllamaClientStub new withResponse: (Dictionary new
        at: #template put: 'TEMPLATE';
        yourself).
    oldFactory := CopilotSettings ollamaClientFactory.
    [
        CopilotSettings ollamaClientFactory: [ stub ].
        CopilotSettings clearCachedModelMetadata.
        first := CopilotSettings modelTemplate.
        CopilotSettings clearCachedModelMetadata.
        second := CopilotSettings modelTemplate.
        self assert: first equals: 'TEMPLATE'.
        self assert: second equals: 'TEMPLATE'.
        self assert: stub callCount equals: 2.
    ] ensure: [
        CopilotSettings ollamaClientFactory: oldFactory.
        CopilotSettings clearCachedModelMetadata.
    ].
]

{ #category : 'tests' }
CopilotSettingsTest >> testCopilotEnabledAccessor [
    | old |
    old := CopilotSettings copilotEnabled.
    self assert: old equals: true.
    CopilotSettings copilotEnabled: false.
    self assert: CopilotSettings copilotEnabled equals: false.
    CopilotSettings copilotEnabled: true.
    self assert: CopilotSettings copilotEnabled equals: true.
    CopilotSettings copilotEnabled: old.
]

{ #category : 'tests' }
CopilotSettingsTest >> testCopilotProviderAccessor [
    | old |
    old := CopilotSettings copilotProvider.
    self assert: old equals: #ollama.
    CopilotSettings copilotProvider: #foo.
    self assert: CopilotSettings copilotProvider equals: #foo.
    CopilotSettings copilotProvider: old.
]

{ #category : 'tests' }
CopilotSettingsTest >> testEnsureSelectedModelAvailableShortCircuitsForNullModel [

    CopilotSettings withDefaultSettingsDo: [
        CopilotSettings ollamaClientFactory: [ self fail ].
        CopilotSettings modelName: CopilotSettings nullModelFullName.
        self assert: CopilotSettings ensureSelectedModelAvailable.
    ]
]

{ #category : 'tests' }
CopilotSettingsTest >> testFimTemplateUsesMetadataTemplateWhenAvailable [

    | stub oldFactory expected actual |
    expected := '<SPECIAL_PREFIX>%1<SPECIAL_SUFFIX>%2<END>'.
    stub := OllamaClientStub new withResponse: (Dictionary new
        at: #template put: expected;
        yourself).
    oldFactory := CopilotSettings ollamaClientFactory.
    [
        CopilotSettings ollamaClientFactory: [ stub ].
        CopilotSettings clearCachedModelMetadata.
        actual := CopilotSettings fimTemplate.
        self assert: actual equals: expected.
        self assert: stub callCount equals: 1.
        self assert: stub lastRequestedModel equals: CopilotSettings modelName.
    ] ensure: [
        CopilotSettings ollamaClientFactory: oldFactory.
        CopilotSettings clearCachedModelMetadata.
    ].
]

{ #category : 'tests' }
CopilotSettingsTest >> testHostAccessor [
    | old |
    old := CopilotSettings host.
    [
        CopilotSettings host: 'localhost'.
        self assert: CopilotSettings host equals: 'localhost'
    ] ensure: [ CopilotSettings host: old ].
]

{ #category : 'tests' }
CopilotSettingsTest >> testMetadataStringForKeyDefaultWhenMissing [
    | value |
    CopilotSettings clearCachedModelMetadata.
    value := CopilotSettings metadataStringForKey: #unknown default: 'Missing'.
    self assert: value equals: 'Missing'.
]

{ #category : 'tests' }
CopilotSettingsTest >> testModelNameAccessor [
    CopilotSettings withDefaultSettingsDo: [
        | old |
        old := CopilotSettings modelName.
        self assert: old equals: OllamaClient defaultModelFullName.
        CopilotSettings modelName: 'foo'.
        self assert: CopilotSettings modelName equals: 'foo'.
        CopilotSettings modelName: old
    ]
]

{ #category : 'tests' }
CopilotSettingsTest >> testModelNameReturnsString [
	| modelName |
	modelName := CopilotSettings modelName.
	
	self assert: modelName isString.
	self deny: modelName isEmpty
]

{ #category : 'tests' }
CopilotSettingsTest >> testModelParametersReadOnly [
    | stub oldFactory oldModel |
    stub := OllamaClientStub new withResponse: (Dictionary new
        at: #parameters put: 'READ ONLY';
        yourself).
    oldFactory := CopilotSettings ollamaClientFactory.
    oldModel := CopilotSettings modelName.
    [
        CopilotSettings ollamaClientFactory: [ stub ].
        CopilotSettings clearCachedModelMetadata.
        CopilotSettings modelName: oldModel.
        self assert: CopilotSettings modelParameters equals: 'READ ONLY'.
        CopilotSettings modelParameters: 'IGNORED'.
        self assert: CopilotSettings modelParameters equals: 'READ ONLY'.
    ] ensure: [
        CopilotSettings modelName: oldModel.
        CopilotSettings ollamaClientFactory: oldFactory.
        CopilotSettings clearCachedModelMetadata.
    ].
]

{ #category : 'tests' }
CopilotSettingsTest >> testModelTemplateCachesResponse [
    | stub oldFactory first second |
    stub := OllamaClientStub new withResponse: (Dictionary new
        at: #template put: 'FIRST TEMPLATE';
        yourself).
    oldFactory := CopilotSettings ollamaClientFactory.
    [
        CopilotSettings ollamaClientFactory: [ stub ].
        CopilotSettings clearCachedModelMetadata.
        first := CopilotSettings modelTemplate.
        stub withResponse: (Dictionary new
            at: #template put: 'SECOND TEMPLATE';
            yourself).
        second := CopilotSettings modelTemplate.
        self assert: first equals: 'FIRST TEMPLATE'.
        self assert: second equals: 'FIRST TEMPLATE'.
        self assert: stub callCount equals: 1.
    ] ensure: [
        CopilotSettings ollamaClientFactory: oldFactory.
        CopilotSettings clearCachedModelMetadata.
    ].
]

{ #category : 'tests' }
CopilotSettingsTest >> testModelTemplateClearedWhenModelChanges [
    | stub oldFactory oldModel templateForOriginal templateForNew |
    stub := OllamaClientStub new withResponseBlock: [ :model |
        Dictionary new
            at: #template put: model , ' template';
            yourself ].
    oldFactory := CopilotSettings ollamaClientFactory.
    oldModel := CopilotSettings modelName.
    [
        CopilotSettings ollamaClientFactory: [ stub ].
        CopilotSettings clearCachedModelMetadata.
        templateForOriginal := CopilotSettings modelTemplate.
        CopilotSettings modelName: 'temporary-test-model'.
        templateForNew := CopilotSettings modelTemplate.
        self assert: templateForOriginal equals: oldModel , ' template'.
        self assert: templateForNew equals: 'temporary-test-model template'.
        self assert: stub callCount equals: 2.
    ] ensure: [
        CopilotSettings modelName: oldModel.
        CopilotSettings ollamaClientFactory: oldFactory.
        CopilotSettings clearCachedModelMetadata.
    ].
]

{ #category : 'tests' }
CopilotSettingsTest >> testModelTemplateDefaultsWhenResponseHasNoTemplate [
    | stub oldFactory template |
    stub := OllamaClientStub new withResponse: Dictionary new.
    oldFactory := CopilotSettings ollamaClientFactory.
    [
        CopilotSettings ollamaClientFactory: [ stub ].
        CopilotSettings clearCachedModelMetadata.
        template := CopilotSettings modelTemplate.
        self assert: template equals: 'Not provided by model.'.
        self assert: stub callCount equals: 1.
    ] ensure: [
        CopilotSettings ollamaClientFactory: oldFactory.
        CopilotSettings clearCachedModelMetadata.
    ].
]

{ #category : 'tests' }
CopilotSettingsTest >> testModelTemplateDefaultsWhenTemplateEmptyString [
    | stub oldFactory template |
    stub := OllamaClientStub new withResponse: (Dictionary new
        at: #template put: '';
        yourself).
    oldFactory := CopilotSettings ollamaClientFactory.
    [
        CopilotSettings ollamaClientFactory: [ stub ].
        CopilotSettings clearCachedModelMetadata.
        template := CopilotSettings modelTemplate.
        self assert: template equals: 'Not provided by model.'.
        self assert: stub callCount equals: 1.
    ] ensure: [
        CopilotSettings ollamaClientFactory: oldFactory.
        CopilotSettings clearCachedModelMetadata.
    ].
]

{ #category : 'tests' }
CopilotSettingsTest >> testModelTemplateFetchedFromOllama [
    | stub oldFactory template |
    stub := OllamaClientStub new withResponse: (Dictionary new
        at: #template put: 'SERVER TEMPLATE';
        yourself).
    oldFactory := CopilotSettings ollamaClientFactory.
    [
        CopilotSettings ollamaClientFactory: [ stub ].
        CopilotSettings clearCachedModelMetadata.
        template := CopilotSettings modelTemplate.
        self assert: template equals: 'SERVER TEMPLATE'.
        self assert: stub callCount equals: 1.
        self assert: stub lastRequestedModel equals: CopilotSettings modelName.
    ] ensure: [
        CopilotSettings ollamaClientFactory: oldFactory.
        CopilotSettings clearCachedModelMetadata.
    ].
]

{ #category : 'tests' }
CopilotSettingsTest >> testModelTemplateHandlesNonStringValues [
    | stub oldFactory template |
    stub := OllamaClientStub new withResponse: (Dictionary new
        at: #template put: 42;
        yourself).
    oldFactory := CopilotSettings ollamaClientFactory.
    [
        CopilotSettings ollamaClientFactory: [ stub ].
        CopilotSettings clearCachedModelMetadata.
        template := CopilotSettings modelTemplate.
        self assert: template equals: '42'.
        self assert: stub callCount equals: 1.
    ] ensure: [
        CopilotSettings ollamaClientFactory: oldFactory.
        CopilotSettings clearCachedModelMetadata.
    ].
]

{ #category : 'tests' }
CopilotSettingsTest >> testNewOllamaClientUsesConfiguredFactory [
    | oldFactory marker |
    oldFactory := CopilotSettings ollamaClientFactory.
    marker := Object new.
    [
        CopilotSettings ollamaClientFactory: [ marker ].
        self assert: CopilotSettings newOllamaClient identicalTo: marker.
    ] ensure: [
        CopilotSettings ollamaClientFactory: oldFactory.
        CopilotSettings clearCachedModelMetadata.
    ].
]

{ #category : 'tests' }
CopilotSettingsTest >> testPortAccessor [
    | old |
    old := CopilotSettings port.
    [
        CopilotSettings port: 12345.
        self assert: CopilotSettings port equals: 12345.
    ] ensure: [ CopilotSettings port: old ].
]

{ #category : 'tests' }
CopilotSettingsTest >> testPortStringInputParsesToNumber [
    | old |
    old := CopilotSettings port.
    [
        CopilotSettings port: '54321'.
        self assert: CopilotSettings port equals: 54321.
    ] ensure: [
        CopilotSettings port: old.
    ].
]

{ #category : 'tests' }
CopilotSettingsTest >> testShouldShowDetailedSettingsReflectsCopilotEnabled [ 
    | old |
    old := CopilotSettings copilotEnabled.
    [
        CopilotSettings copilotEnabled: false.
        self deny: CopilotSettings shouldShowDetailedSettings.
        CopilotSettings copilotEnabled: true.
        self assert: CopilotSettings shouldShowDetailedSettings.
    ] ensure: [
        CopilotSettings copilotEnabled: old.
    ].
]

{ #category : 'tests' }
CopilotSettingsTest >> withTemporaryTemplatesDirectoryDo: aBlock [ 

    | tempFs templatesDir previous |
    tempFs := FileSystem memory.
    templatesDir := tempFs / 'pharo-copilot' / 'templates'.
    templatesDir ensureCreateDirectory.
    previous := CopilotSettings templatesDirectory.
    [
        CopilotSettings templatesDirectory: templatesDir.
        aBlock value: templatesDir
    ] ensure: [ CopilotSettings templatesDirectory: previous ]
]
