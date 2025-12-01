Class {
	#name : 'CoPharoCopilotContextTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoPharoCopilotContextTest >> testInitializeSetsCompletionBuilder [

	| context builder |
	context := CoPharoCopilotContext new.
	builder := context completionBuilder.
	self assert: builder class equals: CoPharoCopilotResultSetBuilder.
	self assert: builder completionContext identicalTo: context
]
