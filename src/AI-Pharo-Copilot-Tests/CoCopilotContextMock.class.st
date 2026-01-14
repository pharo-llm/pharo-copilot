Class {
	#name : 'CoCopilotContextMock',
	#superclass : 'Object',
	#instVars : [
		'source',
		'position',
		'editor',
		'replacedToken',
		'replaceCount',
		'lastReplacement',
		'behavior',
		'method'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
CoCopilotContextMock >> behavior [
		 ^ behavior
]

{ #category : 'accessing' }
CoCopilotContextMock >> behavior: aBehavior [ 

	behavior := aBehavior
]

{ #category : 'accessing' }
CoCopilotContextMock >> editor [
 ^ editor
]

{ #category : 'accessing' }
CoCopilotContextMock >> editor: anEditor [


		editor := anEditor
]

{ #category : 'initialization' }
CoCopilotContextMock >> initialize [

	super initialize.
	source := ''.
	position := 0.
	replaceCount := 0.
]

{ #category : 'accessing' }
CoCopilotContextMock >> lastReplacement [

	 ^ lastReplacement
]

{ #category : 'accessing' }
CoCopilotContextMock >> method [ 

	^ method
]

{ #category : 'accessing' }
CoCopilotContextMock >> method: aCompiledMethod [

		 method := aCompiledMethod
]

{ #category : 'accessing' }
CoCopilotContextMock >> position [

        ^ position ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoCopilotContextMock >> position: anInteger [

        position := anInteger
]

{ #category : 'accessing' }
CoCopilotContextMock >> replaceCount [ 

	^ replaceCount
]

{ #category : 'accessing' }
CoCopilotContextMock >> replaceTokenInEditorWith: aString [

	replaceCount := replaceCount + 1.
	lastReplacement := aString
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
