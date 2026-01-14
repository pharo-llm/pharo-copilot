"
OModelCatalog centralizes the built-in Ollama model declarations used by the Pharo Copilot integration.
Each class-side method declares one model via an <ollamaModel:...> pragma and returns its model id.

"
Class {
	#name : 'OModelCatalog',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot-Ollama',
	#package : 'AI-Pharo-Copilot-Ollama'
}

{ #category : 'private - definitions' }
OModelCatalog class >> pharoCopilotNull [
	"Declare the 'Pharo Null Copilot' model and answer its Ollama model id."

	<ollamaModel: 'pharo-copilot-null' tag: nil label: 'Pharo Null Copilot'>
	^ 'pharo-copilot-null'
]
