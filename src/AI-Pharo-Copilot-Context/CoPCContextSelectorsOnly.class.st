"
I am a context strategy that exposes only method selectors.
Use me when completions should rely on a lightweight class overview instead of full source.
"
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
