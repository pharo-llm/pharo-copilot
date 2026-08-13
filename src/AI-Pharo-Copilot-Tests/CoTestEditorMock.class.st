Class {
	#name : 'CoTestEditorMock',
	#superclass : 'Object',
	#instVars : [
		'caret',
		'morph'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
CoTestEditorMock >> caret [

    ^ caret ifNil: [ 1 ]
]

{ #category : 'accessing' }
CoTestEditorMock >> caret: anInteger [

    caret := anInteger
]

{ #category : 'accessing' }
CoTestEditorMock >> morph [

	^ morph
]

{ #category : 'accessing' }
CoTestEditorMock >> morph: anObject [

	morph := anObject
]

{ #category : 'accessing' }
CoTestEditorMock >> selectAt: anInteger [

    caret := anInteger
]
