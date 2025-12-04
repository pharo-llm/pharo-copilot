Class {
	#name : 'CoGhostTextContextMock',
	#superclass : 'Object',
	#instVars : [
		'source',
		'position',
		'replacement',
		'editor',
		'ghostRenderer'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
CoGhostTextContextMock >> editor [

        ^ editor
]

{ #category : 'accessing' }
CoGhostTextContextMock >> editor: anEditor [

        editor := anEditor
]

{ #category : 'accessing' }
CoGhostTextContextMock >> ghostRenderer [

        ^ ghostRenderer ifNil: [ ghostRenderer := CoGhostTextRenderer onContext: self ]
]

{ #category : 'accessing' }
CoGhostTextContextMock >> initialize [

        super initialize.
        source := ''.
        position := 0.
        editor := CoGhostTextEditorMock new.
]

{ #category : 'accessing' }
CoGhostTextContextMock >> position [

        ^ position
]

{ #category : 'accessing' }
CoGhostTextContextMock >> position: anInteger [

        position := anInteger
]

{ #category : 'accessing' }
CoGhostTextContextMock >> renderGhostText: aString [

        self ghostRenderer renderSuggestion: aString
]

{ #category : 'accessing' }
CoGhostTextContextMock >> replaceTokenInEditorWith: aString [

        replacement := aString
]

{ #category : 'accessing' }
CoGhostTextContextMock >> replacement [

        ^ replacement
]

{ #category : 'accessing' }
CoGhostTextContextMock >> source [

        ^ source
]

{ #category : 'accessing' }
CoGhostTextContextMock >> source: aString [

        source := aString
]
