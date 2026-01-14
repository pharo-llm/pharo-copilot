"
OModelRegistry builds an in-memory index of available OModelSpec instances.
It combines specs declared in the image (via #ollamaModel:tag:label: pragmas) with
models reported by the Ollama server, and lets clients look them up by full name or label.

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
	"Create and rebuild a fresh registry (does not touch the cached #current)."

	| registry |
	registry := self new.
	registry rebuild.
	^ registry
]

{ #category : 'building' }
OModelRegistry class >> current [
	"Answer the cached registry; create and rebuild it if it does not exist yet."

	^ current ifNil: [ self refresh ]
]

{ #category : 'class initialization' }
OModelRegistry class >> fetchModelsResponse [
	"Fetch the server response for the models list, or an empty dictionary if unavailable."

	| client |
	modelsFetcher ifNotNil: [ ^ modelsFetcher value ].

	client := CopilotSettings newOllamaClient.
	(client respondsTo: #listModels) ifFalse: [ ^ Dictionary new ].

	^ client listModels
]

{ #category : 'class initialization' }
OModelRegistry class >> modelsFetcher [
	"Optional override hook to fetch models (useful for tests)."

	^ modelsFetcher
]

{ #category : 'class initialization' }
OModelRegistry class >> modelsFetcher: aBlock [
	"Set an optional override hook to fetch models (useful for tests)."

	modelsFetcher := aBlock
]

{ #category : 'building' }
OModelRegistry class >> refresh [
	"Rebuild and replace the cached registry.
	Important: set #current BEFORE rebuilding to avoid recursion if modelsFetcher calls #current."

	current := self new.
	current rebuild.
	^ current
]

{ #category : 'class initialization' }
OModelRegistry class >> reset [
	"Clear the cached registry (useful for development / scripting)."
	<script>

	current := nil
]

{ #category : 'private' }
OModelRegistry >> addKnownSpecsExceptNullFrom: knownSpecs [
	"Add all pragma-defined specs except the null model (already added first)."

	| nullFullName |
	nullFullName := OllamaClient nullModelFullName.

	knownSpecs valuesDo: [ :spec |
		spec fullName = nullFullName ifFalse: [ self addSpec: spec ] ]
]

{ #category : 'private' }
OModelRegistry >> addNullSpecFromKnownSpecs: knownSpecs [
	"Ensure the null model spec is present and added first."

	| nullFullName nullSpec |
	nullFullName := OllamaClient nullModelFullName.

	nullSpec := knownSpecs
		at: nullFullName
		ifAbsent: [ OModelSpec family: nullFullName tag: nil label: 'Pharo Null Copilot' ].

	self addSpec: nullSpec
]

{ #category : 'private' }
OModelRegistry >> addRemoteModelsUsingKnownSpecs: knownSpecs [
	"Fetch server models and add them, reusing known specs when possible."

	| response models |
	[
		response := self class fetchModelsResponse.
		models := self modelsFromResponse: response.

		models do: [ :modelEntry |
			| modelName spec |
			modelName := self modelNameFromEntry: modelEntry.
			modelName ifNil: [  ] ifNotNil: [
				spec := self specForModelNamed: modelName knownSpecs: knownSpecs.
				self addSpec: spec
			]
		]
	] on: Error do: [ :ex |
		"Ignore if server unreachable / client not configured."
	]
]

{ #category : 'accessing' }
OModelRegistry >> addSpec: aSpec [
	"Add a spec to both indexes (full name and label)."

	aSpec ifNil: [ ^ self ].
	self byFullName at: aSpec fullName put: aSpec.
	self byLabel at: aSpec label put: aSpec
]

{ #category : 'accessing' }
OModelRegistry >> allSpecs [
	"Answer all specs sorted by their label."

	^ (self byFullName values
		asSortedCollection: [ :a :b | a label <= b label ]) asArray
]

{ #category : 'accessing' }
OModelRegistry >> byFullName [
	"Answer the dictionary indexed by full model name."

	^ byFullName ifNil: [ byFullName := Dictionary new ]
]

{ #category : 'accessing' }
OModelRegistry >> byFullName: anObject [

	byFullName := anObject
]

{ #category : 'accessing' }
OModelRegistry >> byLabel [
	"Answer the dictionary indexed by user-visible label."

	^ byLabel ifNil: [ byLabel := Dictionary new ]
]

{ #category : 'accessing' }
OModelRegistry >> byLabel: anObject [

	byLabel := anObject
]

{ #category : 'private' }
OModelRegistry >> collectKnownSpecsFromPragmas [
	"Collect friendly model specs declared in the image via pragmas."

	| knownSpecs |
	knownSpecs := Dictionary new.

	(Pragma allNamed: #ollamaModel:tag:label:) do: [ :pragma |
		| family tag label spec |
		family := pragma arguments first.
		tag := pragma arguments second.
		label := pragma arguments third.

		spec := OModelSpec family: family tag: tag label: label.
		knownSpecs at: spec fullName put: spec
	].

	^ knownSpecs
]

{ #category : 'building' }
OModelRegistry >> domainValuesForSettings [
	"Answer { label -> fullName } pairs, sorted by label (for settings UI)."

	^ (self allSpecs collect: [ :spec | spec label -> spec fullName ]) asArray
]

{ #category : 'private' }
OModelRegistry >> familyFromFullName: fullName [
	"Extract the family part from a full name."

	| tokens |
	tokens := fullName findTokens: ':'.
	tokens ifEmpty: [ ^ fullName ].
	^ tokens first
]

{ #category : 'initialization' }
OModelRegistry >> initialize [
	"Initialize indexes."

	super initialize.
	self resetIndexes
]

{ #category : 'private' }
OModelRegistry >> modelNameFromEntry: modelEntry [
	"Extract a model name from a model entry supporting symbol or string keys."

	modelEntry ifNil: [ ^ nil ].
	^ modelEntry at: #name ifAbsent: [ modelEntry at: 'name' ifAbsent: [ nil ] ]
]

{ #category : 'private' }
OModelRegistry >> modelsFromResponse: response [
	"Extract the models collection from a server response supporting symbol or string keys."

	| models |
	response ifNil: [ ^ #( ) ].

	models := response at: #models ifAbsent: [ response at: 'models' ifAbsent: [ #( ) ] ].
	^ models ifNil: [ #( ) ]
]

{ #category : 'building' }
OModelRegistry >> prettifiedTokenForLabel: aString [
	"Prettify a token: keep digit-leading tokens uppercase, otherwise capitalize."

	aString ifEmpty: [ ^ aString ].

	^ aString first isDigit
		ifTrue: [ aString asUppercase ]
		ifFalse: [ aString capitalized ]
]

{ #category : 'building' }
OModelRegistry >> rebuild [
	"Rebuild the registry from pragmas (known specs) and the server model list."

	| knownSpecs |
	self resetIndexes.

	knownSpecs := self collectKnownSpecsFromPragmas.
	self addNullSpecFromKnownSpecs: knownSpecs.
	self addKnownSpecsExceptNullFrom: knownSpecs.
	self addRemoteModelsUsingKnownSpecs: knownSpecs
]

{ #category : 'initialization' }
OModelRegistry >> resetIndexes [
	"Reset internal indexes to empty dictionaries."

	byFullName := Dictionary new.
	byLabel := Dictionary new
]

{ #category : 'building' }
OModelRegistry >> specByFullName: aString [
	"Lookup a spec by its full name. Answer nil if missing."

	^ self byFullName at: aString ifAbsent: [ nil ]
]

{ #category : 'building' }
OModelRegistry >> specByLabel: aString [
	"Lookup a spec by its label. Answer nil if missing."

	^ self byLabel at: aString ifAbsent: [ nil ]
]

{ #category : 'private' }
OModelRegistry >> specForModelNamed: fullName knownSpecs: knownSpecs [
	"Return an OModelSpec for a server model name, using a known spec if available."

	^ knownSpecs
		at: fullName
		ifAbsent: [ self specFromFullName: fullName ]
]

{ #category : 'private' }
OModelRegistry >> specFromFullName: fullName [
	"Build a spec from a full model name (e.g. 'family:tag'), generating a friendly label."

	| family tag |
	family := self familyFromFullName: fullName.
	tag := self tagFromFullName: fullName.

	^ OModelSpec
		family: family
		tag: tag
		label: (self userFriendlyLabelForModelNamed: fullName)
]

{ #category : 'private' }
OModelRegistry >> tagFromFullName: fullName [
	"Extract the tag part from a full name, preserving ':' inside multi-part tags."

	| tokens |
	tokens := fullName findTokens: ':'.
	(tokens size <= 1) ifTrue: [ ^ nil ].

	^ String streamContents: [ :stream |
		tokens allButFirst withIndexDo: [ :each :index |
			index > 1 ifTrue: [ stream nextPut: $: ].
			stream nextPutAll: each ] ]
]

{ #category : 'building' }
OModelRegistry >> userFriendlyLabelForModelNamed: aString [
	"Convert a model full name into a readable label (tokenized on :-_)."

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
