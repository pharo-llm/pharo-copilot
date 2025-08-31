"
Registry that builds and looks up available model specs.
"
Class {
	#name : 'OModelRegistry',
	#superclass : 'Object',
	#instVars : [
		'byFullName',
		'byLabel'
	],
	#classInstVars : [
		'current'
	],
	#category : 'AI-Pharo-Copilot-Ollama',
	#package : 'AI-Pharo-Copilot-Ollama'
}

{ #category : 'building' }
OModelRegistry class >> build [

	| reg anOModelRegistry |
	anOModelRegistry := self new.
	reg := anOModelRegistry.
	reg rebuild.
	^ reg
]

{ #category : 'accessing' }
OModelRegistry class >> current [ 

  ^ current ifNil: [ current := self build ]
]

{ #category : 'building' }
OModelRegistry >> allSpecs [

  ^ byFullName values asArray sort: [:a :b | a label < b label ]
]

{ #category : 'accessing' }
OModelRegistry >> byFullName [

	^ byFullName
]

{ #category : 'accessing' }
OModelRegistry >> byFullName: anObject [

	byFullName := anObject
]

{ #category : 'accessing' }
OModelRegistry >> byLabel [

	^ byLabel
]

{ #category : 'accessing' }
OModelRegistry >> byLabel: anObject [

	byLabel := anObject
]

{ #category : 'building' }
OModelRegistry >> domainValuesForSettings [ 
  "-> { 'Code Llama 7B' -> 'codellama:7b'. ... } sorted by label"
  ^ (self allSpecs collect: [:s | s label -> s fullName ])
]

{ #category : 'building' }
OModelRegistry >> rebuild [

  byFullName := Dictionary new.
  byLabel := Dictionary new.

  (Pragma allNamed: #ollamaModel:tag:label:) do: [:p |
    | fam tag label spec full |
    fam := p arguments first.
    tag := p arguments second.
    label := p arguments third.
    spec := OModelSpec family: fam tag: tag label: label.
    full := spec fullName.
    byFullName at: full put: spec.
    byLabel at: label put: spec ].

]

{ #category : 'building' }
OModelRegistry >> specByFullName: aString [

  ^ byFullName at: aString ifAbsent: [ nil ]
]

{ #category : 'building' }
OModelRegistry >> specByLabel: aString [ 

  ^ byLabel at: aString ifAbsent: [ nil ]
]
