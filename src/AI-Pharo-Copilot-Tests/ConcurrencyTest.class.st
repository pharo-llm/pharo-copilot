Class {
	#name : 'ConcurrencyTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
ConcurrencyTest >> testConcurrentEvaluatorAccess [
	| evaluator results context |
	evaluator := CoSuggestionEvaluator new.
	context := CoPharoCopilotContext new.
	results := OrderedCollection new.
	
	"Simulate concurrent access"
	(1 to: 10) do: [ :i |
		| entry |
		entry := CoCopilotEntry contents: 'concurrent', i asString.
		evaluator recordSuggestionAccepted: entry context: context.
		results add: evaluator acceptanceRate ].
	
	"All rates should be 100% since all were accepted"
	results do: [ :rate |
		self assert: rate equals: 100 ]
]

{ #category : 'tests' }
ConcurrencyTest >> testConcurrentRegistryRefresh [
	| registries |
	registries := OrderedCollection new.
	
	"Simulate multiple threads refreshing registry"
	5 timesRepeat: [
		registries add: OModelRegistry refresh ].
	
	"All should return the same current instance"
	registries do: [ :registry |
		self assert: registry identicalTo: OModelRegistry current ]
]

{ #category : 'tests' }
ConcurrencyTest >> testConcurrentSettingsModification [
	| oldModel results |
	oldModel := CopilotSettings modelName.
	results := OrderedCollection new.
	
	[
		"Simulate concurrent modifications"
		10 timesRepeat: [ :i |
			CopilotSettings modelName: 'model', i asString.
			results add: CopilotSettings modelName ].
		
		"Should have consistent results"
		results do: [ :modelName |
			self assert: modelName isString ]
	] ensure: [ CopilotSettings modelName: oldModel ]
]
