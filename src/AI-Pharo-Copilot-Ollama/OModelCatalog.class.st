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
OModelCatalog class >> qwen25Coder1p5BLatest [
        <ollamaModel: 'qwen2.5-coder' tag: '0.5b' label: 'Qwen2.5 Coder 0.5B'>
]
