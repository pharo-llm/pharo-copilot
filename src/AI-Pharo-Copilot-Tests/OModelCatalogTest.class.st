Class {
	#name : 'OModelCatalogTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
OModelCatalogTest >> testBuiltInModelPragmas [

        | pragmas uniqueFamiliesAndTags uniqueLabels |
        pragmas := Pragma allNamed: #ollamaModel:tag:label: in: OModelCatalog class.

        self deny: pragmas isEmpty.

        uniqueFamiliesAndTags := (pragmas collect: [ :pragma |
                pragma arguments first -> pragma arguments second ]) asSet.
        uniqueLabels := (pragmas collect: [ :pragma | pragma arguments third ]) asSet.

        self assert: uniqueFamiliesAndTags size equals: pragmas size.
        self assert: uniqueLabels size equals: pragmas size
]
