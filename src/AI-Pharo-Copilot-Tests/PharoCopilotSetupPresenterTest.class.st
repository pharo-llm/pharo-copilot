Class {
	#name : 'PharoCopilotSetupPresenterTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
PharoCopilotSetupPresenterTest >> testSetupStartsWithConnectionChoiceWithoutChangingSettings [

	CopilotSettings withDefaultSettingsDo: [
		| presenter snapshot |
		snapshot := CopilotSettings settingsSnapshot.
		presenter := PharoCopilotSetupPresenter new.
		self assert: presenter descriptionLabel text
			equals: 'Choose where to run your completion model.'.
		self assert: CopilotSettings settingsSnapshot equals: snapshot.
		presenter showAccessTokenStep.
		self assert: (presenter descriptionLabel text includesSubstring: 'requires a token').
		self assert: CopilotSettings settingsSnapshot equals: snapshot.
		presenter showConnectionChoiceStep.
		self assert: presenter descriptionLabel text
			equals: 'Choose where to run your completion model.' ]
]

{ #category : 'tests' }
PharoCopilotSetupPresenterTest >> testLocalChoiceAfterCloudFailureChecksModelsWithoutToken [

	CopilotSettings withDefaultSettingsDo: [
		| presenter client snapshot models |
		models := CopilotSettings predefinedSetupModelNames collect: [ :name |
			Dictionary new at: #name put: name; yourself ].
		client := OllamaClientStub new
			withModelsResponse: (Dictionary new at: #models put: models; yourself).
		CopilotSettings ollamaClientFactory: [ client ].
		snapshot := CopilotSettings settingsSnapshot.
		snapshot at: #remoteEnabled put: true;
			at: #remoteTokenFile put: '/missing/cloud-token';
			at: #host put: 'cloud.example.org';
			at: #port put: 8080;
			at: #modelName put: 'cloud-only-model';
			at: #autoInstallModelScriptEnabled put: false.
		CopilotSettings restoreSettingsFromSnapshot: snapshot.
		presenter := CoPCSetupPresenterDouble new.
		presenter showRemoteConnectionFailedStep.
		presenter handleLocalModelSelected.
		self assert: presenter titleLabel label equals: 'Optional research data collection'.
		self assert: client pullCount equals: 0.
		presenter handleResearchTelemetryDeclined.
		presenter handleScreenRecordingDeclined.
		presenter handleOk.
		self deny: CopilotSettings remoteEnabled.
		self assert: CopilotSettings host equals: '127.0.0.1'.
		self assert: CopilotSettings port equals: 11434.
		self assert: (CopilotSettings settingsSnapshot at: #remoteTokenFile) isNil.
		self assert: CopilotSettings autoInstallModelScriptEnabled.
		self assert: CopilotSettings modelName equals: CopilotSettings defaultCompletionModelName.
		self assert: CopilotSettings copilotEnabled.
		self assert: presenter progressBarValue equals: 1.
		self assert: client pullCount equals: 0 ]
]

{ #category : 'tests' }
PharoCopilotSetupPresenterTest >> testLocalChoiceDownloadsMissingModelBeforeEnablingCompletion [

	CopilotSettings withDefaultSettingsDo: [
		| presenter client names installed missingName |
		names := CopilotSettings predefinedSetupModelNames.
		missingName := names first.
		installed := names allButFirst collect: [ :name |
			Dictionary new at: #name put: name; yourself ].
		client := OllamaClientStub new
			withModelsResponse: (Dictionary new at: #models put: installed; yourself);
			withPullBlock: [ :name |
				self assert: name equals: missingName.
				self deny: CopilotSettings copilotEnabled.
				client withModelsResponse: (Dictionary new
					at: #models put: (names collect: [ :each |
						Dictionary new at: #name put: each; yourself ]);
					yourself).
				Dictionary new at: #status put: 'success'; yourself ].
		CopilotSettings ollamaClientFactory: [ client ].
		presenter := CoPCSetupPresenterDouble new.
		presenter handleLocalModelSelected.
		self assert: presenter titleLabel label equals: 'Optional research data collection'.
		self assert: client pullCount equals: 0.
		presenter handleResearchTelemetryDeclined.
		presenter handleScreenRecordingDeclined.
		presenter handleOk.
		self assert: client pullCount equals: 1.
		self assert: CopilotSettings copilotEnabled.
		self assert: presenter progressBarValue equals: 1 ]
]

{ #category : 'tests' }
PharoCopilotSetupPresenterTest >> testSetupButtonLayoutsDoNotUseFixedWidths [

	#(
		consentLayoutWith:
		telemetryButtonRow
		screenRecordingButtonRow
		showResearchTelemetryLearnMoreStepReturningTo:
		showScreenRecordingLearnMoreStepReturningTo:
		showConsentSummaryStep
	) do: [ :selector |
		self deny:
			((PharoCopilotSetupPresenter sourceCodeAt: selector)
				includesSubstring: 'width:') ]
]

{ #category : 'tests' }
PharoCopilotSetupPresenterTest >> testShowWelcomeStepDoesNotRecordScreenRecordingDecisionWhenNotAsked [

	CopilotSettings withDefaultSettingsDo: [
		| presenter |
		presenter := PharoCopilotSetupPresenter new.
		presenter showWelcomeStep.

		self assert: CopilotSettings screenRecordingConsentState equals: #notAsked.
		self deny: CopilotSettings screenRecordingAccepted.
		self deny: CopilotSettings screenRecordingDeclined ]
]

{ #category : 'tests' }
PharoCopilotSetupPresenterTest >> testShowWelcomeStepDoesNotRecordTelemetryDecisionWhenNotAsked [

	CopilotSettings withDefaultSettingsDo: [
		| presenter |
		presenter := PharoCopilotSetupPresenter new.
		presenter showWelcomeStep.

		self assert: CopilotSettings researchTelemetryConsentState equals: #notAsked.
		self deny: CopilotSettings researchTelemetryAccepted.
		self deny: CopilotSettings researchTelemetryDeclined ]
]

{ #category : 'tests' }
PharoCopilotSetupPresenterTest >> testTelemetryLearnMoreUsesReadOnlyTextForLineBreaks [

	| source |
	source := PharoCopilotSetupPresenter
		sourceCodeAt: #showResearchTelemetryLearnMoreStepReturningTo:.

	self assert: CopilotSettings researchTelemetryLearnMoreText lines size > 1.
	self assert: (source includesSubstring: 'newText').
	self assert: (source includesSubstring: 'beNotEditable')
]

{ #category : 'tests' }
PharoCopilotSetupPresenterTest >> testSetupDescriptionsWrapWithinTheWindow [
	| presenter |
	presenter := PharoCopilotSetupPresenter new.
	self assert: presenter descriptionLabel isWrapWord.
	self assert: presenter statusLabel isWrapWord.
	self deny: presenter descriptionLabel isEditable.
	self deny: presenter statusLabel isEditable
]
