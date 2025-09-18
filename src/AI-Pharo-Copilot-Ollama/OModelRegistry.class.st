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

	^ current ifNil: [ self refresh ]
]

{ #category : 'accessing' }
OModelRegistry class >> refresh [

  current := self new.
  current rebuild.
  ^ current
]

{ #category : 'accessing' }
OModelRegistry >> addSpec: aSpec [
	self byFullName at: aSpec fullName put: aSpec.
	self byLabel    at: aSpec label    put: aSpec.
]

{ #category : 'accessing' }
OModelRegistry >> allSpecs [

	 ^ (self byFullName values asSortedCollection: [ :first :second |
                first label <= second label ]) asArray
]

{ #category : 'accessing' }
OModelRegistry >> byFullName [
	^ byFullName ifNil: [ byFullName := Dictionary new ]
]

{ #category : 'accessing' }
OModelRegistry >> byFullName: anObject [

	byFullName := anObject
]

{ #category : 'accessing' }
OModelRegistry >> byLabel [
	^ byLabel ifNil: [ byLabel := Dictionary new ]
]

{ #category : 'accessing' }
OModelRegistry >> byLabel: anObject [

	byLabel := anObject
]

{ #category : 'building' }
OModelRegistry >> domainValuesForSettings [
	"-> { 'Code Llama 7B' -> 'codellama:7b'. ... } sorted by label"

	^ (self allSpecs collect: [ :spec | spec label -> spec fullName ]) asArray
]

{ #category : 'building' }
OModelRegistry >> initialize [
	super initialize.
	byFullName := Dictionary new.
	byLabel := Dictionary new.
]

{ #category : 'building' }
OModelRegistry >> prettifiedTokenForLabel: aString [

  aString ifEmpty: [ ^ aString ].
  ^ aString first isDigit
    ifTrue: [ aString asUppercase ]
    ifFalse: [ aString capitalized ]
]

{ #category : 'building' }
OModelRegistry >> rebuild [

	byFullName := Dictionary new.
	byLabel := Dictionary new.

	(Pragma allNamed: #ollamaModel:tag:label:) do: [ :p |
			| fam tag label spec full |
			fam := p arguments first.
			tag := p arguments second.
			label := p arguments third.
			spec := OModelSpec family: fam tag: tag label: label.
			full := spec fullName.
			byFullName at: full put: spec.
			byLabel at: label put: spec ]. "Add any models reported by a running Ollama server"
	[
		| resp models name tokens spec full |
		resp := OllamaClient new listModels.
		models := resp at: #models ifAbsent: [ resp at: 'models' ifAbsent: [ #(  ) ] ].
		models do: [ :m |
				name := m at: #name ifAbsent: [ m at: 'name' ifAbsent: [ nil ] ].
				name ifNotNil: [
						tokens := name findTokens: ':'.
						tokens ifEmpty: [ tokens := { name } ].
						spec := OModelSpec
							        family: tokens first
							        tag: (tokens size > 1
									         ifTrue: [ tokens second ]
									         ifFalse: [ nil ])
							        label: (self userFriendlyLabelForModelNamed: name).
						full := spec fullName.
						byFullName at: full ifAbsentPut: [ spec ].
						byLabel at: spec label ifAbsentPut: [ spec ] ] ] ]
		on: Error
		do: [ :ex | "ignore if server unreachable" ]
]

{ #category : 'building' }
OModelRegistry >> specByFullName: aString [

  ^ byFullName at: aString ifAbsent: [ nil ]
]

{ #category : 'building' }
OModelRegistry >> specByLabel: aString [ 

  ^ byLabel at: aString ifAbsent: [ nil ]
]

{ #category : 'building' }
OModelRegistry >> userFriendlyLabelForModelNamed: aString [

  | tokens |
  aString ifNil: [ ^ '' ].
  tokens := aString findTokens: ':-_'.
  tokens ifEmpty: [ ^ aString ].
  ^ String streamContents: [ :stream |
        (tokens collect: [ :token | self prettifiedTokenForLabel: token ])
          withIndexDo: [ :token :index |
                index > 1 ifTrue: [ stream space ].
                stream nextPutAll: token ] ]
]
