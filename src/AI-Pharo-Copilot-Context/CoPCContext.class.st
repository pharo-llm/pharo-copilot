"
CoPharoCopilotContext is a completion context specialized for the Pharo Copilot engine.
It initializes the completion builder responsible for producing Copilot completion results
based on this context.
"
Class {
	#name : 'CoPCContext',
	#superclass : 'CoCompletionContext',
	#category : 'AI-Pharo-Copilot-Context',
	#package : 'AI-Pharo-Copilot-Context'
}

{ #category : 'initialization' }
CoPCContext >> editor [

	^ self engine editor
]

{ #category : 'initialization' }
CoPCContext >> initialize [

	super initialize.
	self initializeCompletionBuilder
]

{ #category : 'initialization' }
CoPCContext >> initializeCompletionBuilder [

	completionBuilder := CoPharoCopilotResultSetBuilder initializeOnContext: self
]
