Class {
	#name : 'CopilotContextStrategy',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'hooks' }
CopilotContextStrategy >> methodsFor: aClass [

	self subclassResponsibility
]

{ #category : 'hooks' }
CopilotContextStrategy >> renderMethod: aCompiledMethod [

	self subclassResponsibility
]
