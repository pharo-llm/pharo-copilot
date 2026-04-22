Class {
	#name : 'BoundaryTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
BoundaryTest >> testLengthStatsBoundaryValues [
	| evaluator context testCases lengthStats bucket |
	evaluator := CoPCSuggestionEvaluator new.
	context := CoPCContext new.
	
	"Test exactly at boundaries: 10, 50"
	testCases := {
		10 -> #short.
		11 -> #medium.
		50 -> #medium.
		51 -> #long
	}.
	
	testCases do: [ :case |
		| entry |
		entry := CoCopilotEntry contents: (String new: case key withAll: $a).
		evaluator recordSuggestionAccepted: entry context: context.
		lengthStats := evaluator sessionStats at: #lengthStats.
		bucket := case value.
		self assert: ((lengthStats at: bucket) at: #accepted) >= 1 ]
]

{ #category : 'tests' }
BoundaryTest >> testNormalizeResponseBoundaryInputs [
	| client |
	client := CoPCOllamaClient new.
	
	"Test empty responses"
	self assert: (client normalizeResponse: '') equals: ''.
	self assert: (client normalizeResponse: '{}') equals: '{}'. 
	
	"Test minimal valid JSON"
	self assert: (client normalizeResponse: '{"response":""}') equals: ''.
	self assert: (client normalizeResponse: '{"content":"x"}') equals: 'x'
]

{ #category : 'tests' }
BoundaryTest >> testPositionBoundaryInContext [
	| context |
	context := CoPCContext new.
	
	"Test position at boundaries"
	context source: 'hello world'.
	
	context position: 0.
	self assert: context position equals: 0.
	
	context position: context source size.
	self assert: context position equals: context source size.
	
	"Test beyond boundaries (should not crash)"
	self shouldnt: [ context position: -1 ] raise: Error.
	self shouldnt: [ context position: context source size + 100 ] raise: Error
]
