Class {
	#name : 'CopilotContextSettings',
	#superclass : 'Object',
	#classInstVars : [
		'mode'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'capabilities' }
CopilotContextSettings class >> availableModes [

	^ #( #fullSource #selectors )
]

{ #category : 'capabilities' }
CopilotContextSettings class >> mode [
	"Possible values: #fullSource #selectors"

	^ mode ifNil: [ mode := #fullSource ]
]

{ #category : 'capabilities' }
CopilotContextSettings class >> mode: aSymbol [

	mode := (self availableModes includes: aSymbol)
		ifTrue: [ aSymbol ]
		ifFalse: [ #fullSource ]
]
