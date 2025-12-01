Class {
	#name : 'CoTestEditorMock',
	#superclass : 'Object',
	#instVars : [
		'caret'
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
CoTestEditorMock >> selectAt: anInteger [

    caret := anInteger
]
