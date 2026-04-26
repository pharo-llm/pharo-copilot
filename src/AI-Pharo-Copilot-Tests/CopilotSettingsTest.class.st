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
CopilotSettingsTest >> testCompletionSuggestionsCountNormalization [

	CopilotSettings withDefaultSettingsDo: [
		CopilotSettings completionSuggestionsCount: 0.
		self assert: CopilotSettings completionSuggestionsCount equals: 1.
		CopilotSettings completionSuggestionsCount: 42.
		self assert: CopilotSettings completionSuggestionsCount equals: 10.
		CopilotSettings completionSuggestionsCount: 4.
		self assert: CopilotSettings completionSuggestionsCount equals: 4.
		]
]

{ #category : 'tests' }
CopilotSettingsTest >> testCompletionSuggestionsCountSnapshotRestore [

	CopilotSettings withDefaultSettingsDo: [
		| snapshot |
		CopilotSettings completionSuggestionsCount: 5.
		snapshot := CopilotSettings settingsSnapshot.
		CopilotSettings completionSuggestionsCount: 1.
		CopilotSettings restoreSettingsFromSnapshot: snapshot.
		self assert: CopilotSettings completionSuggestionsCount equals: 5.
	]
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
CopilotSettingsTest >> testDisablingLoggingPreventsFileCreation [

	CopilotSettings withDefaultSettingsDo: [
			| tempDir tempLogFile tempEvalFile originalLogRef originalDirRef originalEvalRef evaluator |
			tempDir := FileLocator temp / ('copilot-logger-test-' , UUID new asString).
			tempLogFile := tempDir / CoPharoCopilotLogger logFileName.
			tempEvalFile := tempDir / CoPharoCopilotLogger evaluationLogFileName.
			originalLogRef := CoPharoCopilotLogger rawLogFileReference.
			originalDirRef := CoPharoCopilotLogger rawLogsDirectoryReference.
			originalEvalRef := CoPharoCopilotLogger rawEvaluationLogFileReference.
			[
				CopilotSettings loggingEnabled: false.
				CoPharoCopilotLogger rawLogsDirectoryReference: tempDir.
				CoPharoCopilotLogger rawLogFileReference: tempLogFile.
				CoPharoCopilotLogger rawEvaluationLogFileReference: tempEvalFile.
				tempLogFile exists ifTrue: [ tempLogFile ensureDelete ].
				tempEvalFile exists ifTrue: [ tempEvalFile ensureDelete ].
				CoPharoCopilotLogger ensureLogFileInitialized.
				CoPharoCopilotLogger ensureEvaluationLogFileInitialized.
				CoPharoCopilotLogger logFrontEndEvent: 'Logging disabled test' details: Dictionary new.
				evaluator := CoPCSuggestionEvaluator new.
				evaluator savePersistentStats.
				self deny: tempLogFile exists.
				self deny: tempEvalFile exists ] ensure: [
					tempLogFile exists ifTrue: [ tempLogFile ensureDelete ].
					tempEvalFile exists ifTrue: [ tempEvalFile ensureDelete ].
					tempDir exists ifTrue: [ tempDir ensureDelete ].
					CoPharoCopilotLogger rawLogFileReference: originalLogRef.
					CoPharoCopilotLogger rawLogsDirectoryReference: originalDirRef.
					CoPharoCopilotLogger rawEvaluationLogFileReference: originalEvalRef ] ]
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
CopilotSettingsTest >> testInstallModelPromptMessageExplainsPluginBehavior [

	| message |
	message := CopilotSettings installModelPromptMessageForModelNamed: 'demo-model:latest'.
	self assert: (message includesSubstring: 'uses your current editing context').
	self assert: (message includesSubstring: 'No source code is sent to external cloud services').
	self assert: (message includesSubstring: 'Do you consent to installing it now?')
]

{ #category : 'tests' }
CopilotSettingsTest >> testLoggingEnabledDefaultsToTrue [

    CopilotSettings withDefaultSettingsDo: [
        self assert: CopilotSettings loggingEnabled equals: true.
    ].
]

{ #category : 'tests' }
CopilotSettingsTest >> testMetadataStringForKeyDefaultWhenMissing [
    | value |
    CopilotSettings clearCachedModelMetadata.
    value := CopilotSettings metadataStringForKey: #unknown default: 'Missing'.
    self assert: value equals: 'Missing'.
]

{ #category : 'tests' }
CopilotSettingsTest >> testMinimumPrefixLengthAllowsZero [

	CopilotSettings withDefaultSettingsDo: [
		CopilotSettings minimumPrefixLength: 0.
		self assert: CopilotSettings minimumPrefixLength equals: 0.
	]
]

{ #category : 'tests' }
CopilotSettingsTest >> testMinimumPrefixLengthNormalization [

	CopilotSettings withDefaultSettingsDo: [
		CopilotSettings minimumPrefixLength: -5.
		self assert: CopilotSettings minimumPrefixLength equals: 0.
		CopilotSettings minimumPrefixLength: 42.
		self assert: CopilotSettings minimumPrefixLength equals: 20.
		CopilotSettings minimumPrefixLength: 7.
		self assert: CopilotSettings minimumPrefixLength equals: 7.
		CopilotSettings minimumPrefixLength: nil.
		self assert: CopilotSettings minimumPrefixLength equals: 2.
	]
]

{ #category : 'tests' }
CopilotSettingsTest >> testMissingDefaultFimTemplateSignalsError [

    | originalLogsDir tempFs logsDir |
    originalLogsDir := CoPharoCopilotLogger rawLogsDirectoryReference.
    self withTemporaryTemplatesDirectoryDo: [ :ignoredDirectory |
        tempFs := FileSystem memory.
        logsDir := tempFs / 'pharo-copilot' / 'logs'.
        logsDir ensureCreateDirectory.
        [
            CoPharoCopilotLogger rawLogsDirectoryReference: logsDir.
            self should: [ CopilotSettings defaultFimTemplate ] raise: Error
        ] ensure: [ CoPharoCopilotLogger rawLogsDirectoryReference: originalLogsDir ]
    ]
]

{ #category : 'tests' }
CopilotSettingsTest >> testModelNameAccessor [
    CopilotSettings withDefaultSettingsDo: [
        | old |
        old := CopilotSettings modelName.
        self assert: old equals: CoPCOllamaClient defaultModelFullName.
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
CopilotSettingsTest >> testNullModelGeneratesMetadataFiles [

    CopilotSettings withDefaultSettingsDo: [
        | tempDir originalDirRef originalFactory metadata modelDir detailsFile systemFile templateFile modelfileFile modelFile parsedDetails |
        tempDir := FileLocator temp / ('copilot-null-metadata-' , UUID new asString).
        originalDirRef := CoPharoCopilotLogger rawLogsDirectoryReference.
        originalFactory := CopilotSettings ollamaClientFactory.
        [
            tempDir exists ifTrue: [ tempDir ensureDelete ].
            CoPharoCopilotLogger rawLogsDirectoryReference: tempDir.
            CopilotSettings loggingEnabled: true.
            CopilotSettings clearCachedModelMetadata.
            CopilotSettings modelName: CopilotSettings nullModelFullName.
            CopilotSettings ollamaClientFactory: [ self fail: 'Null model should not request Ollama metadata.' ].
            metadata := CopilotSettings modelMetadata.
            self assert: metadata equals: CopilotSettings nullModelMetadata.
            modelDir := tempDir / (CopilotSettings sanitizedFileComponentFor: CopilotSettings nullModelFullName default: 'unknown-model').
            self assert: modelDir exists.
            detailsFile := modelDir / 'details.txt'.
            systemFile := modelDir / 'system.txt'.
            templateFile := modelDir / 'template.txt'.
            modelfileFile := modelDir / 'modelfile.txt'.
            modelFile := modelDir / 'model.txt'.
            { detailsFile. systemFile. templateFile. modelfileFile. modelFile } do: [ :each | self assert: each exists ].
            parsedDetails := STONJSON fromString: detailsFile contents.
            self assert: parsedDetails equals: (metadata at: #details).
            self assert: systemFile contents equals: (metadata at: #system).
            self assert: templateFile contents equals: (metadata at: #template).
            self assert: modelfileFile contents equals: (metadata at: #modelfile).
            self assert: modelFile contents equals: (metadata at: #model).
        ] ensure: [
            CopilotSettings ollamaClientFactory: originalFactory.
            CoPharoCopilotLogger rawLogsDirectoryReference: originalDirRef.
            CopilotSettings clearCachedModelMetadata.
            modelDir notNil ifTrue: [
                [ modelDir children do: [ :child | child ensureDelete ] ] on: Error do: [ :ignored | ].
                modelDir exists ifTrue: [ modelDir ensureDelete ] ].
            tempDir exists ifTrue: [
                [ tempDir children do: [ :child | child ensureDelete ] ] on: Error do: [ :ignored | ].
                tempDir ensureDelete ].
        ]
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
CopilotSettingsTest >> testRecordInstallModelConsentIsStoredInSnapshot [

	CopilotSettings withDefaultSettingsDo: [
		| snapshot consentRecord |
		CopilotSettings
			recordInstallModelUserConsentForModelNamed: 'demo-model:latest'
			accepted: true.
		snapshot := CopilotSettings serializableSettingsSnapshot.
		consentRecord := snapshot at: #installModelUserConsent.
		self assert: (consentRecord at: #model) equals: 'demo-model:latest'.
		self assert: (consentRecord at: #accepted) equals: true.
		self assert: (consentRecord includesKey: #timestamp)
	]
]

{ #category : 'tests' }
CopilotSettingsTest >> testRecordPrivacyPolicyConsentWritesEvaluationJsonEntr [


	CopilotSettings withDefaultSettingsDo: [
		| tempDir tempEvalFile originalDirRef originalEvalRef jsonLine parsed |
		tempDir := FileLocator temp / ('copilot-privacy-consent-test-' , UUID new asString).
		tempEvalFile := tempDir / CoPharoCopilotLogger evaluationLogFileName.
		originalDirRef := CoPharoCopilotLogger rawLogsDirectoryReference.
		originalEvalRef := CoPharoCopilotLogger rawEvaluationLogFileReference.
		[
			CoPharoCopilotLogger rawLogsDirectoryReference: tempDir.
			CoPharoCopilotLogger rawEvaluationLogFileReference: tempEvalFile.
			tempEvalFile exists ifTrue: [ tempEvalFile ensureDelete ].

			CopilotSettings recordPrivacyPolicyUserConsentAccepted: true.

			jsonLine := tempEvalFile readStreamDo: [ :stream | stream nextLine ].
			parsed := STONJSON fromString: jsonLine.
			self assert: (parsed at: #event) equals: 'privacy-policy-consent'.
			self assert: ((parsed at: #data) at: #accepted) equals: true.
			self assert: ((parsed at: #data) includesKey: #timestamp)
		] ensure: [
			tempEvalFile exists ifTrue: [ tempEvalFile ensureDelete ].
			tempDir exists ifTrue: [ tempDir ensureDelete ].
			CoPharoCopilotLogger rawLogsDirectoryReference: originalDirRef.
			CoPharoCopilotLogger rawEvaluationLogFileReference: originalEvalRef ] ]
]

{ #category : 'tests' }
CopilotSettingsTest >> testRequestTimeoutSecondsNormalization [
    CopilotSettings withDefaultSettingsDo: [
        CopilotSettings requestTimeoutSeconds: 100.
        self assert: CopilotSettings requestTimeoutSeconds equals: 100.
        CopilotSettings requestTimeoutSeconds: 200.
        self assert: CopilotSettings requestTimeoutSeconds equals: 200.
        CopilotSettings requestTimeoutSeconds: 15.
        self assert: CopilotSettings requestTimeoutSeconds equals: 15.
    ]
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
CopilotSettingsTest >> testTimingSettingsNormalization [

	CopilotSettings withDefaultSettingsDo: [
			CopilotSettings completionDebounceMilliseconds: 0.
			self assert: CopilotSettings completionDebounceMilliseconds equals: 50.
			CopilotSettings completionIdleMilliseconds: -10.
			self assert: CopilotSettings completionIdleMilliseconds equals: 300.
			CopilotSettings completionDebounceMilliseconds: 70000.
			self assert: CopilotSettings completionDebounceMilliseconds equals: 60000.
			CopilotSettings completionIdleMilliseconds: 2.
			self assert: CopilotSettings completionIdleMilliseconds equals: 2 ]
]

{ #category : 'tests' }
CopilotSettingsTest >> testTimingSettingsSnapshotRestore [
    CopilotSettings withDefaultSettingsDo: [
        | snapshot |
        CopilotSettings completionDebounceMilliseconds: 300.
        CopilotSettings completionIdleMilliseconds: 2400.
        CopilotSettings requestTimeoutSeconds: 9.
        snapshot := CopilotSettings settingsSnapshot.
        CopilotSettings completionDebounceMilliseconds: 1200.
        CopilotSettings completionIdleMilliseconds: 4000.
        CopilotSettings requestTimeoutSeconds: 30.
        CopilotSettings restoreSettingsFromSnapshot: snapshot.
        self assert: CopilotSettings completionDebounceMilliseconds equals: 300.
        self assert: CopilotSettings completionIdleMilliseconds equals: 2400.
        self assert: CopilotSettings requestTimeoutSeconds equals: 9.
    ]
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
