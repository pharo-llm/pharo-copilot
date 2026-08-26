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
PharoCopilotSetupPresenterTest >> testTelemetryLearnMoreUsesReadOnlyTextForLineBreaks [

	| source |
	source := PharoCopilotSetupPresenter
		sourceCodeAt: #showResearchTelemetryLearnMoreStepReturningTo:.

	self assert: CopilotSettings researchTelemetryLearnMoreText lines size > 1.
	self assert: (source includesSubstring: 'newText').
	self assert: (source includesSubstring: 'beNotEditable')
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
PharoCopilotSetupPresenterTest >> testShowWelcomeStepDoesNotRecordScreenRecordingDecisionWhenNotAsked [

	CopilotSettings withDefaultSettingsDo: [
		| presenter |
		presenter := PharoCopilotSetupPresenter new.
		presenter showWelcomeStep.

		self assert: CopilotSettings screenRecordingConsentState equals: #notAsked.
		self deny: CopilotSettings screenRecordingAccepted.
		self deny: CopilotSettings screenRecordingDeclined ]
]
