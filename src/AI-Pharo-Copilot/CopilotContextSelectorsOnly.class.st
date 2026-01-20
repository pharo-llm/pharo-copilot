Class {
	#name : 'CopilotContextSelectorsOnly',
	#superclass : 'CopilotContextStrategy',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'hooks' }
CopilotContextSelectorsOnly >> methodsFor: aClass [

	^ aClass selectors asSortedCollection
]

{ #category : 'hooks' }
CopilotContextSelectorsOnly >> renderMethod: aSelector [

	^ aSelector asString
]
