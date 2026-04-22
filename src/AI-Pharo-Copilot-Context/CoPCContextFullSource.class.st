"
I am a context strategy that exposes the full source code of methods.
Use me when completions should be generated from complete method bodies.
"
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
