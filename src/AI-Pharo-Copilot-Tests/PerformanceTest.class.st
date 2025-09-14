Class {
	#name : 'PerformanceTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
PerformanceTest >> testCleanedContentFromPerformanceWithLargeInput [
	| builder largeInput time |
	builder := CoPharoCopilotResultSetBuilder new.
	largeInput := '```pharo', String lf, (String new: 50000 withAll: $c), String lf, '```'.
	
	time := Time millisecondsToRun: [
		builder cleanedContentFrom: largeInput ].
	
	"Should process large input quickly (less than 50ms)"
	self assert: time < 50
]

{ #category : 'tests' }
PerformanceTest >> testContextCreationPerformance [
	| time contexts |
	contexts := OrderedCollection new.
	
	time := Time millisecondsToRun: [
		1000 timesRepeat: [
			contexts add: CoPharoCopilotContext new ] ].
	
	"Should create contexts quickly (less than 100ms for 1000)"
	self assert: time < 100.
	self assert: contexts size equals: 1000
]

{ #category : 'tests' }
PerformanceTest >> testEntryCreationPerformance [
	| time entries |
	entries := OrderedCollection new.
	
	time := Time millisecondsToRun: [
		1000 timesRepeat: [ :i |
			entries add: (CoCopilotEntry contents: 'content', i asString) ] ].
	
	"Should create entries quickly (less than 50ms for 1000)"
	self assert: time < 50.
	self assert: entries size equals: 1000
]

{ #category : 'tests' }
PerformanceTest >> testNormalizeResponsePerformanceWithManyResponses [
	| client responses time |
	client := OllamaClient new.
	responses := (1 to: 1000) collect: [ :i |
		'{"response":"content', i asString, '","done":true}' ].
	
	time := Time millisecondsToRun: [
		responses do: [ :response |
			client normalizeResponse: response ] ].
	
	"Should normalize many responses quickly (less than 200ms for 1000)"
	self assert: time < 200
]

{ #category : 'tests' }
PerformanceTest >> testSuggestionEvaluatorPerformance [
	| evaluator time context |
	evaluator := CoSuggestionEvaluator new.
	context := CoPharoCopilotContext new.
	
	time := Time millisecondsToRun: [
		100 timesRepeat: [ :i |
			| entry |
			entry := CoCopilotEntry contents: 'suggestion', i asString.
			evaluator recordSuggestionAccepted: entry context: context ] ].
	
	"Should record suggestions quickly (less than 100ms for 100)"
	self assert: time < 100
]
