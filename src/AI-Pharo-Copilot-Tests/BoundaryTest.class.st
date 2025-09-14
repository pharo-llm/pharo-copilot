Class {
	#name : 'BoundaryTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
BoundaryTest >> testDisplayStringBoundaryConditions [
	| entry |
	
	"Test exactly at boundary"
	entry := CoCopilotEntry contents: (String new: 120 withAll: $x).
	self assert: entry displayString size equals: 120.
	
	"Test just over boundary"
	entry := CoCopilotEntry contents: (String new: 121 withAll: $x).
	self assert: entry displayString size equals: 118.  "117 + 1 for ellipsis"
	self assert: (entry displayString endsWith: '…').
	
	"Test way over boundary"
	entry := CoCopilotEntry contents: (String new: 1000 withAll: $x).
	self assert: entry displayString size equals: 118.
	self assert: (entry displayString endsWith: '…')
]

{ #category : 'tests' }
BoundaryTest >> testFimTemplateBoundaryValues [
	| old result longTemplate |
	old := CopilotSettings fimTemplate.

	[
		"Test with minimal template"
		CopilotSettings fimTemplate: '{1}{2}'.
		result := (CopilotSettings fimTemplate) format: { 'A'. 'B' }.
		self assert: result equals: 'AB'.

		"Test with very long template"
		longTemplate := (String new: 1000 withAll: $x) , '{1}' ,
						(String new: 1000 withAll: $y) , '{2}'.
		CopilotSettings fimTemplate: longTemplate.
		result := (CopilotSettings fimTemplate) format: { 'PREFIX'. 'SUFFIX' }.
		self assert: (result includesSubstring: 'PREFIX').
		self assert: (result includesSubstring: 'SUFFIX')
	] ensure: [ CopilotSettings fimTemplate: old ].

]

{ #category : 'tests' }
BoundaryTest >> testLengthStatsBoundaryValues [
	| evaluator context testCases lengthStats bucket |
	evaluator := CoSuggestionEvaluator new.
	context := CoPharoCopilotContext new.
	
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
	client := OllamaClient new.
	
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
	context := CoPharoCopilotContext new.
	
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
