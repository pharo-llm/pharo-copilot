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
