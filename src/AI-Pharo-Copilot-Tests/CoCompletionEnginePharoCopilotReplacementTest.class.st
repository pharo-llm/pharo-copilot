Class {
	#name : 'CoCompletionEnginePharoCopilotReplacementTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoCompletionEnginePharoCopilotReplacementTest >> testReplacementSkipsBlankSuggestion [

    | engine editor |
    engine := CoSpyCompletionEnginePharoCopilot new.
    editor := CoTestEditorMock new.
    editor caret: 5.
    engine editor: editor.

    engine replaceTokenInEditorWith: ''.

    self assert: engine basicCalledWith isNil.
    self assert: editor caret equals: 5
]
