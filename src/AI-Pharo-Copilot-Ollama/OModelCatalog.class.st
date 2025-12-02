"
Catalog of built-in Ollama model definitions.
"
Class {
	#name : 'OModelCatalog',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot-Ollama',
	#package : 'AI-Pharo-Copilot-Ollama'
}

{ #category : 'private - definitions' }
OModelCatalog class >> pharoCopilotNull [

	<ollamaModel: 'pharo-copilot-null' tag: nil label: 'Pharo Null Copilot'>
	
]

{ #category : 'private - definitions' }
OModelCatalog class >> pharoqwencoder154003b [
        <ollamaModel: 'omarabedelkader/pharo-qwen-coder-15400' tag: '3b' label: 'Base Model (solid performance)'>
]

{ #category : 'private - definitions' }
OModelCatalog class >> pharoqwencoder154007b [
        <ollamaModel: 'omarabedelkader/pharo-qwen-coder-15400' tag: '7b' label: 'Large Model (high-quality outputs)'>
]
