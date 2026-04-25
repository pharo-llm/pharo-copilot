"
I create context builders for completions based on the current settings.
I resolve the class from a selector and choose the configured context strategy.
"
Class {
	#name : 'CoPCContextFactory',
	#superclass : 'Object',
	#classInstVars : [
		'classBySelectorCache'
	],
	#category : 'AI-Pharo-Copilot-Context',
	#package : 'AI-Pharo-Copilot-Context'
}

{ #category : 'factory' }
CoPCContextFactory class >> classBySelectorCache [

	^ classBySelectorCache ifNil: [ classBySelectorCache := Dictionary new ]
]

{ #category : 'factory' }
CoPCContextFactory class >> classFromSelector: aSelector [

	| cache cached scanned |
	aSelector ifNil: [ ^ nil ].

	cache := self classBySelectorCache.
	cached := cache at: aSelector ifAbsent: [ nil ].
	(cached notNil and: [ cached includesSelector: aSelector ]) ifTrue: [ ^ cached ].
	cached ifNotNil: [ cache removeKey: aSelector ifAbsent: [  ] ].

	scanned := SystemNavigation default allClasses
		detect: [ :each | each includesSelector: aSelector ]
		ifNone: [ nil ].
	scanned ifNotNil: [ cache at: aSelector put: scanned ].
	^ scanned
]

{ #category : 'factory' }
CoPCContextFactory class >> flushCaches [
	"Drop all cached selector->class mappings. Useful when the system changes substantially."

	classBySelectorCache := nil
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
