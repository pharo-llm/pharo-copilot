"
CoPharoCopilotContext is a completion context specialized for the Pharo Copilot engine.
It initializes the completion builder responsible for producing Copilot completion results
based on this context.
"
Class {
	#name : 'CoPharoCopilotContext',
	#superclass : 'CoCompletionContext',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'initialization' }
CoPharoCopilotContext >> initialize [
	"Initialize the context and set up the completion builder that will generate Copilot results."

	super initialize.
	self initializeCompletionBuilder
]

{ #category : 'initialization' }
CoPharoCopilotContext >> initializeCompletionBuilder [
	"Create and configure the result-set builder to operate on this context."

	completionBuilder := CoPharoCopilotResultSetBuilder
		initializeOnContext: self
]
