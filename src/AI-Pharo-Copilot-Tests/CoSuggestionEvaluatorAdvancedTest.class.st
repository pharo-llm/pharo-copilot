Class {
	#name : 'CoSuggestionEvaluatorAdvancedTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoSuggestionEvaluatorAdvancedTest >> testComplexEvaluationScenario [

	| evaluator context suggestions lengthStats |
	evaluator := CoSuggestionEvaluator new.
	context := CoPharoCopilotContext new. 
	suggestions := {
		               (CoCopilotEntry contents: 'short').
		               (CoCopilotEntry contents: (String new: 30 withAll: $m)).
		               (CoCopilotEntry contents: (String new: 100 withAll: $l)) }. 
	evaluator recordSuggestionAccepted: suggestions first context: context.
	evaluator recordSuggestionRejected: suggestions second context: context reason: 'Not relevant'.
	evaluator recordSuggestionAccepted: suggestions third context: context. 
	self assert: (evaluator sessionStats at: #totalSuggestions) equals: 3.
	self assert: (evaluator sessionStats at: #totalAccepted) equals: 2.
	self assert: evaluator acceptanceRate equals: 67.
	lengthStats := evaluator sessionStats at: #lengthStats.
	self assert: ((lengthStats at: #short) at: #accepted) equals: 1.
	self assert: ((lengthStats at: #medium) at: #rejected) equals: 1.
	self assert: ((lengthStats at: #long) at: #accepted) equals: 1
]

{ #category : 'tests' }
CoSuggestionEvaluatorAdvancedTest >> testConcurrentEvaluationOperations [
	| evaluator contexts |
	evaluator := CoSuggestionEvaluator new.
	
	"Create multiple contexts simulating different editing contexts"
	contexts := (1 to: 5) collect: [ :i |
		| ctx |
		ctx := CoPharoCopilotContext new.
		ctx source: 'context', i asString, 'source code here'.
		ctx ].
	
	"Simulate rapid suggestions from different contexts"
	contexts do: [ :ctx |
		evaluator recordSuggestionAccepted: (CoCopilotEntry contents: 'suggestion for ', ctx source) context: ctx ].
		
	self assert: (evaluator sessionStats at: #totalSuggestions) equals: 5.
	self assert: evaluator acceptedEntries size equals: 5
]

{ #category : 'tests' }
CoSuggestionEvaluatorAdvancedTest >> testDetermineContextTypeWithComplexCode [
	| evaluator testCases |
	evaluator := CoSuggestionEvaluator new.
	
	testCases := {
		'Class { #name : ''MyClass'', #superclass : ''Object'' }' -> #classDef.
		'method: arg { #category : ''accessing'' } ^ self instVar' -> #method.
		'var := (obj doSomething) ifTrue: [ #yes ] ifFalse: [ #no ]' -> #assignment.
		'collection do: [ :item | item process. item save ]' -> #iteration.
		'result := computation. ^ result transformed' -> #return.
		'very simple line' -> #other
	}.
	
	testCases do: [ :case |
		| context result |
		context := CoPharoCopilotContext new.
		context source: case key.
		result := evaluator determineContextType: context.
		self assert: result equals: case value ]
]

{ #category : 'tests' }
CoSuggestionEvaluatorAdvancedTest >> testEvaluatorMemoryUsage [
	| evaluator initialSize |
	evaluator := CoSuggestionEvaluator new.
	initialSize := evaluator acceptedEntries size + evaluator rejectedEntries size.
	
	"Add many entries"
	1 to: 1000 do: [ :i |
		| entry context |
		entry := CoCopilotEntry contents: 'suggestion ', i asString.
		context := CoPharoCopilotContext new.
		evaluator recordSuggestionAccepted: entry context: context ].
	
	self assert: evaluator acceptedEntries size equals: 1000.
	self assert: (evaluator sessionStats at: #totalSuggestions) equals: 1000
]

{ #category : 'tests' }
CoSuggestionEvaluatorAdvancedTest >> testGenerateReportWithVariedData [

	| evaluator context report |
	evaluator := CoSuggestionEvaluator new.
	context := CoPharoCopilotContext new. "Create varied evaluation data"
	evaluator recordSuggestionAccepted: (CoCopilotEntry contents: 'good suggestion') context: context.
	evaluator recordSuggestionRejected: (CoCopilotEntry contents: 'bad suggestion') context: context reason: 'Wrong code'.

	report := evaluator generateReport.

	self assert: report isString.
	self assert: (report includesSubstring: 'Total suggestions: 2').
	self assert: (report includesSubstring: 'Accepted: 1').
	self assert: (report includesSubstring: 'MODEL PERFORMANCE').
	self assert: (report includesSubstring: 'CONTEXT ANALYSIS').
	self assert: (report includesSubstring: 'RECOMMENDATIONS')
]
