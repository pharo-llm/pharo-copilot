Class {
	#name : 'CoSuggestionEvaluatorTest',
	#superclass : 'TestCase',
	#instVars : [
		'evaluator'
	],
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'running' }
CoSuggestionEvaluatorTest >> setUp [
	super setUp.
	evaluator := CoSuggestionEvaluator new
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testAcceptanceRateCalculation [
	| context entry |
	context := CoPharoCopilotContext new.
	
	"Record some accepted and rejected entries"
	entry := CoCopilotEntry contents: 'test1'.
	evaluator recordSuggestionAccepted: entry context: context.
	
	entry := CoCopilotEntry contents: 'test2'.
	evaluator recordSuggestionAccepted: entry context: context.
	
	"Should be 100% acceptance rate"
	self assert: evaluator acceptanceRate equals: 100.
	
	"Add a rejection"
	evaluator recordSuggestionIgnored: (CoCopilotEntry contents: 'test3') context: context.
	
	"Should be 67% acceptance rate (2/3)"
	self assert: evaluator acceptanceRate equals: 67
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testAcceptanceRateWithNoSuggestions [
	self assert: evaluator acceptanceRate equals: 0
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testDetermineContextTypeAssignment [
	| context |
	context := CoPharoCopilotContext new.
	context source: 'variable := value'.
	
	self assert: (evaluator determineContextType: context) equals: #assignment
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testDetermineContextTypeClassDefinition [
	| context |
	context := CoPharoCopilotContext new.
	context source: 'Class { #name : ''MyClass'' }'.
	
	self assert: (evaluator determineContextType: context) equals: #classDef
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testDetermineContextTypeConditional [

	| context |
	context := CoPharoCopilotContext new.
	context source: 'condition ifTrue: [ action ]'.

	self assert: (evaluator determineContextType: context) equals: #condition
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testDetermineContextTypeIteration [
	| context |
	context := CoPharoCopilotContext new.
	context source: 'collection do: [ :each | process ]'.
	
	self assert: (evaluator determineContextType: context) equals: #iteration
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testDetermineContextTypeMethod [
	| context |
	context := CoPharoCopilotContext new.
	context source: 'methodName { #category : ''accessing'' }'.
	
	self assert: (evaluator determineContextType: context) equals: #method
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testDetermineContextTypeOther [
	| context |
	context := CoPharoCopilotContext new.
	context source: 'some random code'.
	
	self assert: (evaluator determineContextType: context) equals: #other
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testDetermineContextTypeReturn [
	| context |
	context := CoPharoCopilotContext new.
	context source: '^ result'.
	
	self assert: (evaluator determineContextType: context) equals: #return
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testInitialStatsStructure [

	| stats |
	stats := evaluator sessionStats.

	self assert: (stats at: #totalSuggestions) equals: 0.
	self assert: (stats at: #totalAccepted) equals: 0.
	self assert: (stats at: #totalRejected) equals: 0.
	self assert: ((stats at: #sessionStartTime) isKindOf: DateAndTime).
	self assert: ((stats at: #modelStats) isKindOf: Dictionary).
	self assert: ((stats at: #contextStats) isKindOf: Dictionary).
	self assert: ((stats at: #lengthStats) isKindOf: Dictionary)
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testRecordSuggestionAccepted [
	| context entry |
	context := CoPharoCopilotContext new.
	entry := CoCopilotEntry contents: 'test suggestion'.
	
	evaluator recordSuggestionAccepted: entry context: context.
	
	self assert: evaluator acceptedEntries size equals: 1.
	self assert: evaluator acceptedEntries first suggestion identicalTo: entry.
	self assert: evaluator acceptedEntries first action equals: #accepted.
	self assert: (evaluator sessionStats at: #totalAccepted) equals: 1
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testRecordSuggestionIgnored [
	| context entry |
	context := CoPharoCopilotContext new.
	entry := CoCopilotEntry contents: 'ignored suggestion'.
	
	evaluator recordSuggestionIgnored: entry context: context.
	
	"Ignored suggestions don't go into accepted or rejected collections"
	self assert: evaluator acceptedEntries isEmpty.
	self assert: evaluator rejectedEntries isEmpty.
	
	"But they do update the total count"
	self assert: (evaluator sessionStats at: #totalSuggestions) equals: 1
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testRejectionRateCalculation [
	| context |
	context := CoPharoCopilotContext new.
	
	"Initially 0%"
	self assert: evaluator rejectionRate equals: 0.
	
	"Add some entries"
	evaluator recordSuggestionAccepted: (CoCopilotEntry contents: 'accepted') context: context.
	evaluator recordSuggestionIgnored: (CoCopilotEntry contents: 'ignored') context: context.
	
	"Still 0% rejected"
	self assert: evaluator rejectionRate equals: 0
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testUpdateLengthStatsLongSuggestion [
	| entry |
	entry := CoEvaluationEntry new.
	entry suggestion: (CoCopilotEntry contents: (String new: 100 withAll: $a)).
	entry action: #accepted.
	
	evaluator updateStats: entry.
	
	self assert: (((evaluator sessionStats at: #lengthStats) at: #long) at: #accepted) equals: 1
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testUpdateLengthStatsMediumSuggestion [
	| entry |
	entry := CoEvaluationEntry new.
	entry suggestion: (CoCopilotEntry contents: (String new: 30 withAll: $a)).
	entry action: #accepted.
	
	evaluator updateStats: entry.
	
	self assert: (((evaluator sessionStats at: #lengthStats) at: #medium) at: #accepted) equals: 1
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testUpdateLengthStatsShortSuggestion [
	| entry |
	entry := CoEvaluationEntry new.
	entry suggestion: (CoCopilotEntry contents: 'short').
	entry action: #accepted.
	
	evaluator updateStats: entry.
	
	self assert: (((evaluator sessionStats at: #lengthStats) at: #short) at: #accepted) equals: 1
]
