Class {
	#name : 'RegressionTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
RegressionTest >> testCleanedContentFromDoesNotAlterOriginalString [
	| builder original result |
	builder := CoPharoCopilotResultSetBuilder new.
	original := '```smalltalk', String lf, 'original code', String lf, '```'.
	
	result := builder cleanedContentFrom: original.
	
	"Original should be unchanged"
	self assert: (original includesSubstring: '```smalltalk').
	self assert: result equals: 'original code'
]

{ #category : 'tests' }
RegressionTest >> testEvaluatorDefaultInstanceConsistency [
	| evaluator1 evaluator2 |
	
	"Reset to ensure clean state"
	CoSuggestionEvaluator reset.
	
	evaluator1 := CoSuggestionEvaluator default.
	evaluator2 := CoSuggestionEvaluator default.
	
	"Should return same instance"
	self assert: evaluator1 identicalTo: evaluator2
]

{ #category : 'tests' }
RegressionTest >> testRegistryCurrentInstanceConsistency [
	| registry1 registry2 |
	registry1 := OModelRegistry current.
	registry2 := OModelRegistry current.
	
	"Should return same instance"
	self assert: registry1 identicalTo: registry2
]

{ #category : 'tests' }
RegressionTest >> testSettingsClassVariableIsolation [
	| oldValues newValues |
	
	"Capture current values"
	oldValues := Dictionary new
		at: #enabled put: CopilotSettings copilotEnabled;
		at: #provider put: CopilotSettings copilotProvider;
		at: #model put: CopilotSettings modelName;
		yourself.
	
	[
		"Modify settings"
		CopilotSettings copilotEnabled: false.
		CopilotSettings copilotProvider: #test.
		CopilotSettings modelName: 'test:regression'.
		
		"Capture modified values"
		newValues := Dictionary new
			at: #enabled put: CopilotSettings copilotEnabled;
			at: #provider put: CopilotSettings copilotProvider;
			at: #model put: CopilotSettings modelName;
			yourself.
		
		"Verify changes are isolated and persistent"
		self deny: (newValues at: #enabled) equals: (oldValues at: #enabled).
		self deny: (newValues at: #provider) equals: (oldValues at: #provider).
		self deny: (newValues at: #model) equals: (oldValues at: #model)
	] ensure: [
		"Restore original values"
		CopilotSettings copilotEnabled: (oldValues at: #enabled).
		CopilotSettings copilotProvider: (oldValues at: #provider).
		CopilotSettings modelName: (oldValues at: #model) ]
]
