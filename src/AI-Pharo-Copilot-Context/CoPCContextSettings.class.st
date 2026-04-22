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

{ #category : 'capabilities' }
CoPCContextSettings class >> mode [
	"Possible values: #fullSource #selectors"

	^ mode ifNil: [ mode := #fullSource ]
]

{ #category : 'capabilities' }
CoPCContextSettings class >> mode: aSymbol [

	mode := (self availableModes includes: aSymbol)
		ifTrue: [ aSymbol ]
		ifFalse: [ #fullSource ]
]
