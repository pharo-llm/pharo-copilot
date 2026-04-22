Class {
	#name : 'CoPCContextFullSource',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot-Context',
	#package : 'AI-Pharo-Copilot-Context'
}

{ #category : 'hooks' }
CoPCContextFullSource >> methodsFor: aClass [

	^ aClass methodDictionary values
]

{ #category : 'hooks' }
CoPCContextFullSource >> renderMethod: aCompiledMethod [ 

	^ aCompiledMethod sourceCode
]
