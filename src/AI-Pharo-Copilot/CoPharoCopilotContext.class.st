"
CoPharoCopilotContext is a completion context specialized for the Pharo Copilot engine.
It initializes the completion builder responsible for producing Copilot completion results
based on this context.
"
Class {
	#name : 'CoPharoCopilotContext',
	#superclass : 'CoCompletionContext',
	#category : 'AI-Pharo-Copilot-Cach',
	#package : 'AI-Pharo-Copilot',
	#tag : 'Cach'
}

{ #category : 'initialization' }
CoPharoCopilotContext >> editor [

	^ self engine editor
]

{ #category : 'initialization' }
CoPharoCopilotContext >> initialize [

	super initialize.
	self initializeCompletionBuilder
]

{ #category : 'initialization' }
CoPharoCopilotContext >> initializeCompletionBuilder [

	completionBuilder := CoPharoCopilotResultSetBuilder initializeOnContext: self
]
