Class {
	#name : 'CopilotMockModelTestCase',
	#superclass : 'TestCase',
	#instVars : [
		'mockContext',
		'settingsBeforeTest'
	],
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
CopilotMockModelTestCase >> setUp [

	settingsBeforeTest := CopilotSettings settingsSnapshot.
    super setUp.
    mockContext := OTestModelSupport beginMockModels.
	"Baseline post-load intentionally disables Copilot in user images. Tests
	start from application defaults instead of inheriting that runtime choice."
	CopilotSettings resetToDefaultSettings.
]

{ #category : 'running' }
CopilotMockModelTestCase >> tearDown [

	[ CopilotSettings restoreSettingsFromSnapshot: settingsBeforeTest ] ensure: [
		[ super tearDown ] ensure: [
			OTestModelSupport endMockModels: mockContext.
			mockContext := nil ] ].
]
