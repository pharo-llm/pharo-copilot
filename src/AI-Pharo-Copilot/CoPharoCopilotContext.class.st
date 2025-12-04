"
Specialized completion context tailored for the Pharo Copilot engine.

"
Class {
	#name : 'CoPharoCopilotContext',
	#superclass : 'CoCompletionContext',
	#instVars : [
		'ghostRenderer'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'initialization' }
CoPharoCopilotContext >> acceptGhostText [

        self ghostRenderer acceptGhostText
]

{ #category : 'initialization' }
CoPharoCopilotContext >> acceptGhostTextFirstLine [

        self ghostRenderer acceptGhostTextFirstLine
]

{ #category : 'initialization' }
CoPharoCopilotContext >> acceptGhostTextFirstWord [

        self ghostRenderer acceptGhostTextFirstWord
]

{ #category : 'initialization' }
CoPharoCopilotContext >> clearGhostText [ 

        ghostRenderer ifNotNil: [ ghostRenderer clearGhostText ]
]

{ #category : 'initialization' }
CoPharoCopilotContext >> ghostRenderer [ 

        ^ ghostRenderer ifNil: [ ghostRenderer := CoGhostTextRenderer onContext: self ]
]

{ #category : 'initialization' }
CoPharoCopilotContext >> initialize [

	super initialize.
	completionBuilder := CoPharoCopilotResultSetBuilder initializeOnContext:
		                     self
]

{ #category : 'initialization' }
CoPharoCopilotContext >> renderGhostText: aString [

        self ghostRenderer renderSuggestion: aString
]
