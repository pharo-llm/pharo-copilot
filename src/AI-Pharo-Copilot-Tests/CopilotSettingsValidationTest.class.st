Class {
	#name : 'CopilotSettingsValidationTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'accessing' }
CopilotSettingsValidationTest >> testModelNameWithInvalidValues [
	| old longName |
	old := CopilotSettings modelName.
	
	[
		"Empty string should not crash"
		CopilotSettings modelName: ''.
		self assert: CopilotSettings modelName equals: ''.
		
		longName := String new: 1000 withAll: $m.
		CopilotSettings modelName: longName.
		self assert: CopilotSettings modelName equals: longName.
		
		"Model name with special characters"
		CopilotSettings modelName: 'model-name_123:tag@latest'.
		self assert: CopilotSettings modelName equals: 'model-name_123:tag@latest'
	] ensure: [ CopilotSettings modelName: old ]
]

{ #category : 'accessing' }
CopilotSettingsValidationTest >> testProviderWithInvalidSymbols [
	| old |
	old := CopilotSettings copilotProvider.
	
	[
		"Test with unknown provider"
		CopilotSettings copilotProvider: #unknown.
		self assert: CopilotSettings copilotProvider equals: #unknown.
		
		"Test with string instead of symbol (should work)"
		CopilotSettings copilotProvider: 'stringProvider'.
		self assert: CopilotSettings copilotProvider equals: 'stringProvider'
	] ensure: [ CopilotSettings copilotProvider: old ]
]
