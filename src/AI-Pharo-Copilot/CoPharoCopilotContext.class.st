"
Specialized completion context tailored for the Pharo Copilot engine.

"
Class {
	#name : 'CoPharoCopilotContext',
	#superclass : 'CoCompletionContext',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'initialization' }
CoPharoCopilotContext >> initialize [

	super initialize.
	completionBuilder := CoPharoCopilotResultSetBuilder initializeOnContext:
		                     self
]
