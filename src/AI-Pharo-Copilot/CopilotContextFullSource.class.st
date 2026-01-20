Class {
	#name : 'CopilotContextFullSource',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'hooks' }
CopilotContextFullSource >> methodsFor: aClass [

	^ aClass methodDictionary values
]

{ #category : 'hooks' }
CopilotContextFullSource >> renderMethod: aCompiledMethod [ 

	^ aCompiledMethod sourceCode
]
