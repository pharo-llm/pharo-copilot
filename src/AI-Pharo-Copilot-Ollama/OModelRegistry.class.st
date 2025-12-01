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
		'current',
		'modelsFetcher'
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
OModelRegistry class >> fetchModelsResponse [

    | client |
 modelsFetcher ifNotNil: [ ^ modelsFetcher value ].
    client := CopilotSettings newOllamaClient.
    (client respondsTo: #listModels) ifFalse: [ ^ Dictionary new ].
    ^ client listModels
]

{ #category : 'accessing' }
OModelRegistry class >> modelsFetcher [
    ^ modelsFetcher
]

{ #category : 'accessing' }
OModelRegistry class >> modelsFetcher: aBlock [
    modelsFetcher := aBlock
]

{ #category : 'accessing' }
OModelRegistry class >> refresh [

  current := self new.
  current rebuild.
  ^ current
]

{ #category : 'accessing' }
OModelRegistry class >> reset [
<script>
    current := nil
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

	| knownSpecs nullModelName nullSpec resp models name spec |
	byFullName := Dictionary new.
	byLabel := Dictionary new.
	knownSpecs := Dictionary new.

	(Pragma allNamed: #ollamaModel:tag:label:) do: [ :p |
					| fam tag label spec full |
					fam := p arguments first.
					tag := p arguments second.
					label := p arguments third.
					spec := OModelSpec family: fam tag: tag label: label.
					full := spec fullName.
					knownSpecs at: full put: spec ]. "Collect friendly labels defined via pragmas"
	nullModelName := OllamaClient nullModelFullName.
	nullSpec := knownSpecs
						at: nullModelName
						ifAbsent: [ OModelSpec family: nullModelName tag: nil label: 'Pharo Null Copilot' ].
		nullSpec ifNotNil: [ self addSpec: nullSpec ].
[ 
				resp := self class fetchModelsResponse.
				models := resp at: #models ifAbsent: [ resp at: 'models' ifAbsent: [ #(  ) ] ].
				models isEmpty ifFalse: [
						knownSpecs valuesDo: [ :each | each fullName = nullModelName ifFalse: [ self addSpec: each ] ].
						models do: [ :m |
								name := m at: #name ifAbsent: [ m at: 'name' ifAbsent: [ nil ] ].
								name ifNotNil: [
										spec := knownSpecs at: name ifAbsent: [
											| tokens tag |
											tokens := name findTokens: ':'.
											tokens ifEmpty: [ tokens := { name } ].
											tag := tokens size > 1
												   ifTrue: [
												                   String streamContents: [ :stream |
												                           tokens allButFirst withIndexDo: [ :token :index |
												                                   index > 1 ifTrue: [ stream nextPut: $: ].
												                                   stream nextPutAll: token ] ] ]
												   ifFalse: [ nil ].
										OModelSpec family: tokens first tag: tag label: (self userFriendlyLabelForModelNamed: name) ].
									self addSpec: spec ] ] ] ]
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
