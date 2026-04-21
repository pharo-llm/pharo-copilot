Class {
	#name : 'CopilotContextFactory',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot-Context',
	#package : 'AI-Pharo-Copilot-Context'
}

{ #category : 'factory' }
CopilotContextFactory class >> classFromSelector: aSelector [

	^ SystemNavigation default allClasses detect: [ :each | each includesSelector: aSelector ] ifNone: [ nil ]
]

{ #category : 'factory' }
CopilotContextFactory class >> forSelector: aSelector [

	| contextClass strategy |
	contextClass := self classFromSelector: aSelector.
	contextClass ifNil: [ ^ nil ].

	strategy := self strategyFromSettings.
	^ CopilotContextBuilder
		forClass: contextClass
		strategy: strategy
]

{ #category : 'factory' }
CopilotContextFactory class >> strategyFromSettings [

	^ CopilotContextSettings mode
		caseOf: {
			[ #fullSource ] -> [ CopilotContextFullSource new ].
			[ #selectors ] -> [ CopilotContextSelectorsOnly new ].
		}
		otherwise: [ CopilotContextFullSource new ]
]
