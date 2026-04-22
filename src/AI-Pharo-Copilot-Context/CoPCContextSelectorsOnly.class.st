Class {
	#name : 'CoPCContextSelectorsOnly',
	#superclass : 'CoPCContextStrategy',
	#category : 'AI-Pharo-Copilot-Context',
	#package : 'AI-Pharo-Copilot-Context'
}

{ #category : 'hooks' }
CoPCContextSelectorsOnly >> methodsFor: aClass [

	^ aClass selectors asSortedCollection
]

{ #category : 'hooks' }
CoPCContextSelectorsOnly >> renderMethod: aSelector [

	^ aSelector asString
]
