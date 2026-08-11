Class {
	#name : 'CoEngineBackedContextMock',
	#superclass : 'Object',
	#instVars : [
		'engine',
		'source',
		'position'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
CoEngineBackedContextMock >> engine [

	^ engine
]

{ #category : 'accessing' }
CoEngineBackedContextMock >> engine: anObject [

	engine := anObject
]

{ #category : 'initialization' }
CoEngineBackedContextMock >> initialize [

	super initialize.
	source := ''.
	position := 0
]

{ #category : 'accessing' }
CoEngineBackedContextMock >> position [

	^ position
]

{ #category : 'accessing' }
CoEngineBackedContextMock >> position: anInteger [

	position := anInteger
]

{ #category : 'accessing' }
CoEngineBackedContextMock >> source [

	^ source
]

{ #category : 'accessing' }
CoEngineBackedContextMock >> source: aString [

	source := aString
]
