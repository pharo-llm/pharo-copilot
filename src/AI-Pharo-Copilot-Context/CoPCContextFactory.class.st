"
I create context builders for completions based on the current settings.
I resolve the class from a selector and choose the configured context strategy.
"
Class {
	#name : 'CoPCContextFactory',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot-Context',
	#package : 'AI-Pharo-Copilot-Context'
}

{ #category : 'factory' }
CoPCContextFactory class >> classFromSelector: aSelector [

	^ SystemNavigation default allClasses detect: [ :each | each includesSelector: aSelector ] ifNone: [ nil ]
]

{ #category : 'factory' }
CoPCContextFactory class >> forSelector: aSelector [

	| contextClass strategy |
	contextClass := self classFromSelector: aSelector.
	contextClass ifNil: [ ^ nil ].

	strategy := self strategyFromSettings.
	^ CoPCContextBuilder
		forClass: contextClass
		strategy: strategy
]

{ #category : 'factory' }
CoPCContextFactory class >> strategyFromSettings [

	^ CoPCContextSettings mode
		caseOf: {
			[ #fullSource ] -> [ CoPCContextFullSource new ].
			[ #selectors ] -> [ CoPCContextSelectorsOnly new ].
		}
		otherwise: [ CoPCContextFullSource new ]
]
