Class {
	#name : 'CoCopilotMockEditor',
	#superclass : 'Object',
	#instVars : [
		'inserted',
		'startIndex',
		'selectionStart',
		'selectionStop'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'initialization' }
CoCopilotMockEditor >> addString: aString [

	inserted := inserted , aString.
	"Emulate Pharo's RubTextEditor, which selects the just-inserted text."
	selectionStart := startIndex.
	selectionStop := startIndex + aString size - 1.
	startIndex := startIndex + aString size
]

{ #category : 'initialization' }
CoCopilotMockEditor >> initialize [

	super initialize.
	inserted := ''.
	startIndex := 1.
	selectionStart := 1.
	selectionStop := 0
]

{ #category : 'initialization' }
CoCopilotMockEditor >> insertedText [

	^ inserted
]

{ #category : 'initialization' }
CoCopilotMockEditor >> selectAt: anInteger [

	startIndex := anInteger.
	selectionStart := anInteger.
	selectionStop := anInteger - 1
]

{ #category : 'initialization' }
CoCopilotMockEditor >> selectInvisiblyFrom: startInteger to: stopInteger [

	selectionStart := startInteger.
	selectionStop := stopInteger.
	startIndex := startInteger
]

{ #category : 'initialization' }
CoCopilotMockEditor >> selectionIsCollapsed [

	^ selectionStop < selectionStart
]

{ #category : 'initialization' }
CoCopilotMockEditor >> selectionStart [

	^ selectionStart
]

{ #category : 'initialization' }
CoCopilotMockEditor >> selectionStop [

	^ selectionStop
]

{ #category : 'initialization' }
CoCopilotMockEditor >> startIndex [

	^ startIndex
]

{ #category : 'initialization' }
CoCopilotMockEditor >> startIndex: anInteger [

	startIndex := anInteger.
	selectionStart := anInteger.
	selectionStop := anInteger - 1
]
