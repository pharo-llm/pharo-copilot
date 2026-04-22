"
I define the protocol for building class context representations for completions.
Subclasses decide which methods to expose and how each method is rendered.
"
Class {
	#name : 'CoPCContextStrategy',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot-Context',
	#package : 'AI-Pharo-Copilot-Context'
}

{ #category : 'hooks' }
CoPCContextStrategy >> methodsFor: aClass [

	self subclassResponsibility
]

{ #category : 'hooks' }
CoPCContextStrategy >> renderMethod: aCompiledMethod [

	self subclassResponsibility
]
