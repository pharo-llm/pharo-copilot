Class {
	#name : 'PharoCopilotSetupPresenterTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
PharoCopilotSetupPresenterTest >> testSetupButtonLayoutsDoNotUseFixedWidths [

	#(
		showResearchTelemetryConsentChoiceStep
		showResearchTelemetryLearnMoreStepReturningTo:includeConsentButtons:
		showWelcomeStepAfterConsentDecision
	) do: [ :selector |
		self deny:
			((PharoCopilotSetupPresenter sourceCodeAt: selector)
				includesSubstring: 'width:') ]
]

{ #category : 'tests' }
PharoCopilotSetupPresenterTest >> testTelemetryConsentIntroUsesReadOnlyTextForLineBreaks [

	| source |
	source := PharoCopilotSetupPresenter
		sourceCodeAt: #showResearchTelemetryConsentChoiceStep.

	self assert: CopilotSettings researchTelemetryFirstLaunchText lines size > 1.
	self assert: (source includesSubstring: 'newText').
	self assert: (source includesSubstring: 'beNotEditable').
	self deny: (source includesSubstring: 'label: CopilotSettings researchTelemetryFirstLaunchText')
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
