Class {
	#name : 'EdgeCaseTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
EdgeCaseTest >> testCoCopilotEntryWithEmptyContent [
	| entry |
	entry := CoCopilotEntry contents: ''.
	
	self assert: entry contents equals: ''.
	self assert: entry displayString equals: ''
]

{ #category : 'tests' }
EdgeCaseTest >> testCoCopilotEntryWithExactly120Characters [
	| content entry |
	content := String new: 120 withAll: $x.
	entry := CoCopilotEntry contents: content.
	
	"Should not truncate at exactly 120 chars"
	self assert: entry displayString equals: content
]

{ #category : 'tests' }
EdgeCaseTest >> testCoPharoCopilotContextWithEmptySource [
	| context |
	context := CoPharoCopilotContext new.
	context source: ''.
	context position: 0.
	
	self assert: context source isEmpty.
	self assert: context position equals: 0
]

{ #category : 'tests' }
EdgeCaseTest >> testOllamaClientWithNilOptions [
	| client |
	client := OllamaClient new.
	client options: nil.
	
	self assert: client options isEmpty.
	self assert: (client optionAt: #temperature) isNil
]

{ #category : 'tests' }
EdgeCaseTest >> testSuggestionEvaluatorWithZeroTotal [
	| evaluator |
	evaluator := CoSuggestionEvaluator new.
	
	"Should handle division by zero gracefully"
	self assert: evaluator acceptanceRate equals: 0.
	self assert: evaluator rejectionRate equals: 0
]
