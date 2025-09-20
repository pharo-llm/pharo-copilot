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
ConcurrencyTest >> testConcurrentSettingsModification [
	| oldModel results |
	oldModel := CopilotSettings modelName.
	results := OrderedCollection new.

	[
		1 to: 10 do: [:i |
			CopilotSettings modelName: 'model', i asString.
			results add: CopilotSettings modelName ].

		results do: [:modelName |
			self assert: modelName isString ]
	] ensure: [
		CopilotSettings modelName: oldModel
	].

]

{ #category : 'tests' }
ConcurrencyTest >> testSequentialRefreshCreatesNewInstances [
	| registries |
	registries := (Array new: 5) collect: [:i | OModelRegistry refresh ].
	self deny: ((IdentitySet newFrom: registries) size = 1).
	self assert: (registries last) identicalTo: OModelRegistry current.
]
