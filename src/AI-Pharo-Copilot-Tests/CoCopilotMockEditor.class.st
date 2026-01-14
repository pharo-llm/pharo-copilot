Class {
	#name : 'CoCopilotMockEditor',
	#superclass : 'Object',
	#instVars : [
		'inserted'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'initialization' }
CoCopilotMockEditor >> addString: aString [

	inserted := inserted , aString
]

{ #category : 'initialization' }
CoCopilotMockEditor >> initialize [

	super initialize.
	inserted := ''.
]

{ #category : 'initialization' }
CoCopilotMockEditor >> insertedText [

	^ inserted
]
