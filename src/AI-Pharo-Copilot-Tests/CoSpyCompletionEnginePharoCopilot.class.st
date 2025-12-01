Class {
	#name : 'CoSpyCompletionEnginePharoCopilot',
	#superclass : 'CoCompletionEnginePharoCopilot',
	#instVars : [
		'editorMock',
		'basicCalledWith'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'initialization' }
CoSpyCompletionEnginePharoCopilot >> basicCalledWith [

    ^ basicCalledWith
]

{ #category : 'initialization' }
CoSpyCompletionEnginePharoCopilot >> basicReplaceTokenInEditorWith: newString [

    basicCalledWith := newString
]

{ #category : 'initialization' }
CoSpyCompletionEnginePharoCopilot >> editor [

    ^ editorMock

]

{ #category : 'initialization' }
CoSpyCompletionEnginePharoCopilot >> editor: anEditorMock [

    editorMock := anEditorMock
]

{ #category : 'initialization' }
CoSpyCompletionEnginePharoCopilot >> initialize [

    super initialize.
    editorMock := CoTestEditorMock new.
]
