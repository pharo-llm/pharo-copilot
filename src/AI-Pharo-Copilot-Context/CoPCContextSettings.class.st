"
I store the configuration for class-context generation used by Pharo Copilot.
I validate and expose the available context modes.
"
Class {
	#name : 'CoPCContextSettings',
	#superclass : 'Object',
	#classInstVars : [
		'mode'
	],
	#category : 'AI-Pharo-Copilot-Context',
	#package : 'AI-Pharo-Copilot-Context'
}

{ #category : 'capabilities' }
CoPCContextSettings class >> availableModes [

	^ #( #fullSource #selectors )
]

{ #category : 'class initialization' }
CoPCContextSettings class >> initialize [

	super initialize.
	self initializeDefaults
]

{ #category : 'class initialization' }
CoPCContextSettings class >> initializeDefaults [

	mode := #fullSource
]

{ #category : 'capabilities' }
CoPCContextSettings class >> mode [

	^ mode
]

{ #category : 'capabilities' }
CoPCContextSettings class >> mode: aSymbol [

	mode := (self availableModes includes: aSymbol)
		ifTrue: [ aSymbol ]
		ifFalse: [ #fullSource ].
		CopilotSettings autoSaveSettings
]
