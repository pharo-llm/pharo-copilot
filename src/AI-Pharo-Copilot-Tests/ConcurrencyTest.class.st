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

	| n start done results |
	n := 5.
	start := Semaphore new.
	done := Semaphore new.
	results := Array new: n. "Spawn workers that all wait on the same gate."
	1 to: n do: [ :i |
			[
				start wait. "release all at once"
				results at: i put: OModelRegistry refresh.
				done signal ] fork ]. "Let them all run concurrently."
	n timesRepeat: [ start signal ]. "Wait for everyone to finish."
	n timesRepeat: [ done wait ]. "All returned objects must be the very same instance."
	self assert: (IdentitySet newFrom: results) size = 1.
	self assert: (results first )identicalTo: OModelRegistry current.
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
