Class {
	#name : 'OModelCatalogTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
OModelCatalogTest >> testBuiltInModelPragmas [
	| pragmas |
	pragmas := Pragma allNamed: #ollamaModel:tag:label: in: OModelCatalog class.
	
	self assert: pragmas size >= 4.
	
	"Test specific models exist"
	self assert: (pragmas anySatisfy: [ :p | 
		p arguments = #('codellama' '7b' 'Code Llama 7B') ]).
	self assert: (pragmas anySatisfy: [ :p | 
		p arguments = #('codellama' '13b' 'Code Llama 13B') ])
]

{ #category : 'tests' }
OModelCatalogTest >> testCodeLlamaModelsHaveCorrectStructure [
	| pragmas |
	pragmas := Pragma allNamed: #ollamaModel:tag:label: in: OModelCatalog class.
	
	pragmas do: [ :pragma |
		self assert: pragma arguments size equals: 3.
		self assert: pragma arguments first isString.
		self assert: pragma arguments second isString.
		self assert: pragma arguments third isString ]
]
