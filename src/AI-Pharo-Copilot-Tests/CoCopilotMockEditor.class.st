Class {
	#name : 'CoCopilotMockEditor',
	#superclass : 'Object',
	#instVars : [
		'inserted',
		'startIndex',
		'selectionStart',
		'selectionStop',
		'text',
		'caret'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'initialization' }
CoCopilotMockEditor >> addString: aString [

		inserted := inserted , aString.
	selectionStart := startIndex.
	selectionStop := startIndex + aString size - 1.
	startIndex := startIndex + aString size
]

{ #category : 'accessing' }
CoCopilotMockEditor >> caret [

	^ caret ifNil: [ startIndex ]
]

{ #category : 'accessing' }
CoCopilotMockEditor >> caret: anInteger [

	caret := anInteger.
	self startIndex: anInteger
]

{ #category : 'initialization' }
CoCopilotMockEditor >> initialize [

	super initialize.
	inserted := ''.
	startIndex := 1.
	selectionStart := 1.
	selectionStop := 0.
	text := ''.
	caret := 1
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

{ #category : 'accessing' }
CoCopilotMockEditor >> text [

	^ text ifNil: [ '' ]
]

{ #category : 'accessing' }
CoCopilotMockEditor >> text: aString [

	text := aString
]
