Class {
	#name : 'CoGhostTextEditorMock',
	#superclass : 'Object',
	#instVars : [
		'lastGhostText',
		'lastPosition',
		'cleared'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'as yet unclassified' }
CoGhostTextEditorMock >> clearGhostSuggestion [

        cleared := true
]

{ #category : 'as yet unclassified' }
CoGhostTextEditorMock >> cleared [

        ^ cleared = true
]

{ #category : 'as yet unclassified' }
CoGhostTextEditorMock >> lastGhostText [

        ^ lastGhostText
]

{ #category : 'as yet unclassified' }
CoGhostTextEditorMock >> lastPosition [ 

        ^ lastPosition
]

{ #category : 'as yet unclassified' }
CoGhostTextEditorMock >> showGhostSuggestion: aString at: aPosition color: aColor [

        lastGhostText := aString.
        lastPosition := aPosition.
        cleared := false
]

{ #category : 'as yet unclassified' }
CoGhostTextEditorMock >> showGhostSuggestion: aString at: aPosition color: aColor alpha: anAlpha [

        self showGhostSuggestion: aString at: aPosition color: aColor
]
