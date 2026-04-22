Class {
	#name : 'CoEvaluationEntryTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoEvaluationEntryTest >> testActionAccessor [
	| entry |
	entry := CoPCEvaluationEntry new.
	
	entry action: #accepted.
	self assert: entry action equals: #accepted.
	
	entry action: #rejected.
	self assert: entry action equals: #rejected.
	
	entry action: #ignored.
	self assert: entry action equals: #ignored
]

{ #category : 'tests' }
CoEvaluationEntryTest >> testContextAccessor [
	| entry context |
	entry := CoPCEvaluationEntry new.
	context := CoPCContext new.
	
	entry context: context.
	self assert: entry context identicalTo: context
]

{ #category : 'tests' }
CoEvaluationEntryTest >> testMetadataAccessor [

	| entry metadata |
	entry := CoPCEvaluationEntry new. "Should start with empty dictionary"
	self assert: ((entry metadata) isKindOf: Dictionary).
	self assert: entry metadata isEmpty.

	metadata := Dictionary new
		            at: #key put: 'value';
		            yourself.
	entry metadata: metadata.
	self assert: entry metadata identicalTo: metadata
]

{ #category : 'tests' }
CoEvaluationEntryTest >> testRejectionReasonAccessor [ 
	| entry |
	entry := CoPCEvaluationEntry new.
	
	entry rejectionReason: 'Syntax error'.
	self assert: entry rejectionReason equals: 'Syntax error'
]

{ #category : 'tests' }
CoEvaluationEntryTest >> testSuggestionAccessor [
	| entry suggestion |
	entry := CoPCEvaluationEntry new.
	suggestion := CoCopilotEntry contents: 'test'.
	
	entry suggestion: suggestion.
	self assert: entry suggestion identicalTo: suggestion
]

{ #category : 'tests' }
CoEvaluationEntryTest >> testTimestampAccessor [
	| entry timestamp |
	entry := CoPCEvaluationEntry new.
	timestamp := DateAndTime now.
	
	entry timestamp: timestamp.
	self assert: entry timestamp identicalTo: timestamp
]
