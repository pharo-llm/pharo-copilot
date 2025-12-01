Class {
	#name : 'CoCopilotContextMock',
	#superclass : 'Object',
	#instVars : [
		'source',
		'position',
		'replacedToken'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
CoCopilotContextMock >> position [

        ^ position ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoCopilotContextMock >> position: anInteger [

        position := anInteger
]

{ #category : 'accessing' }
CoCopilotContextMock >> replaceTokenInEditorWith: aString [

        replacedToken := aString
]

{ #category : 'accessing' }
CoCopilotContextMock >> replacedToken [

        ^ replacedToken
]

{ #category : 'accessing' }
CoCopilotContextMock >> source [

        ^ source ifNil: [ '' ]
]

{ #category : 'accessing' }
CoCopilotContextMock >> source: aString [

        source := aString
]
