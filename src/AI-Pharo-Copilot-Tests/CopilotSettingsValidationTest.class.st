Class {
	#name : 'CopilotSettingsValidationTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
CopilotSettingsValidationTest >> testFimTemplateWithComplexFormats [
	| old templates formatted |
	old := CopilotSettings fimTemplate.
	
	templates := {
		'<PREFIX>%1<SUFFIX>%2<MIDDLE>'.
		'BEGIN%1END%2FILL'.
		'[PRE]%1[SUF]%2[MID]'.
		'{prefix:%1,suffix:%2}'
	}.
	
	templates do: [ :template |
		[
			CopilotSettings fimTemplate: template.
			self assert: CopilotSettings fimTemplate equals: template.
			
			"Test formatting works"
			formatted := template format: { 'test1'. 'test2' }.
			self assert: (formatted includesSubstring: 'test1').
			self assert: (formatted includesSubstring: 'test2')
		] ensure: [ CopilotSettings fimTemplate: old ] ]
]

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

{ #category : 'accessing' }
CopilotSettingsValidationTest >> testSettingsConsistencyAfterMultipleChanges [
        | oldEnabled oldProvider oldModel oldEnter oldTemplate oldHost oldPort |

        "Save all current values"
        oldEnabled := CopilotSettings copilotEnabled.
        oldProvider := CopilotSettings copilotProvider.
        oldModel := CopilotSettings modelName.
        oldTemplate := CopilotSettings fimTemplate.
        oldHost := CopilotSettings host.
        oldPort := CopilotSettings port.

        [
                "Make multiple rapid changes"
                10 timesRepeat: [
                        CopilotSettings copilotEnabled: true.
                        CopilotSettings copilotProvider: #test.
                        CopilotSettings modelName: 'test:model'.
                        CopilotSettings fimTemplate: 'TEST%1TEST%2TEST'.
                        CopilotSettings host: 'loop.host'.
                        CopilotSettings port: 54321.

                        "Verify consistency"
                        self assert: CopilotSettings copilotEnabled equals: true.
                        self assert: CopilotSettings copilotProvider equals: #test.
                        self assert: CopilotSettings modelName equals: 'test:model'.
                        self assert: CopilotSettings fimTemplate equals: 'TEST%1TEST%2TEST'.
                        self assert: CopilotSettings host equals: 'loop.host'.
                        self assert: CopilotSettings port equals: 54321 ]
        ] ensure: [
                "Restore all values"
                CopilotSettings copilotEnabled: oldEnabled.
                CopilotSettings copilotProvider: oldProvider.
                CopilotSettings modelName: oldModel.
                CopilotSettings fimTemplate: oldTemplate.
                CopilotSettings host: oldHost.
                CopilotSettings port: oldPort ]
]
