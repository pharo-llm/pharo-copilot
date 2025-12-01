Class {
	#name : 'RegressionTest',
	#superclass : 'CopilotMockModelTestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
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
RegressionTest >> testDefaultModelConsistency [
        | defaultModel oldModel client1 client2 |
        defaultModel := OllamaClient defaultModelFullName.
        oldModel := CopilotSettings modelName.
        [
                CopilotSettings modelName: defaultModel.
                client1 := OllamaClient new.
                client2 := OllamaClient new.
                self assert: (client1 instVarNamed: 'modelSpec') fullName equals: defaultModel.
                self assert: (client2 instVarNamed: 'modelSpec') fullName equals: defaultModel.
                self
                        assert: (client1 instVarNamed: 'modelSpec') fullName
                        equals: (client2 instVarNamed: 'modelSpec') fullName
        ] ensure: [ CopilotSettings modelName: oldModel ]
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
	       oldValues := Dictionary new
                at: #enabled put: CopilotSettings copilotEnabled;
                at: #provider put: CopilotSettings copilotProvider;
                at: #model put: CopilotSettings modelName;
                at: #host put: CopilotSettings host;
                at: #port put: CopilotSettings port;
                yourself.

        [
                "Modify settings"
                CopilotSettings copilotEnabled: false.
                CopilotSettings copilotProvider: #test.
                CopilotSettings modelName: 'test:regression'.
                CopilotSettings host: 'regression.host'.
                CopilotSettings port: (oldValues at: #port) + 10.

                "Capture modified values"
                newValues := Dictionary new
                        at: #enabled put: CopilotSettings copilotEnabled;
                        at: #provider put: CopilotSettings copilotProvider;
                        at: #model put: CopilotSettings modelName;
                        at: #host put: CopilotSettings host;
                        at: #port put: CopilotSettings port;
                        yourself.

                "Verify changes are isolated and persistent"
                self deny: (newValues at: #enabled) equals: (oldValues at: #enabled).
                self deny: (newValues at: #provider) equals: (oldValues at: #provider).
                self deny: (newValues at: #model) equals: (oldValues at: #model).
                self deny: (newValues at: #host) equals: (oldValues at: #host).
                self deny: (newValues at: #port) equals: (oldValues at: #port)
        ] ensure: [
                "Restore original values"
                CopilotSettings copilotEnabled: (oldValues at: #enabled).
                CopilotSettings copilotProvider: (oldValues at: #provider).
                CopilotSettings modelName: (oldValues at: #model).
                CopilotSettings host: (oldValues at: #host).
                CopilotSettings port: (oldValues at: #port) ]
]
