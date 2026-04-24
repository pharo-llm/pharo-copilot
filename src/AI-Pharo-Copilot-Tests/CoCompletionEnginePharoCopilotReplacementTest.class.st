Class {
	#name : 'CoCompletionEnginePharoCopilotReplacementTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoCompletionEnginePharoCopilotReplacementTest >> testReplacementRecordsValue [

    | engine editor |
    engine := CoSpyCompletionEnginePharoCopilot new.
    editor := CoTestEditorMock new.
    editor caret: 7.
    engine editor: editor.

    engine replaceTokenInEditorWith: 'suggestion text'.

    self assert: engine basicCalledWith equals: 'suggestion text'
]

{ #category : 'tests' }
CoCompletionEnginePharoCopilotReplacementTest >> testReplacementMovesCaretToEndOfSuggestion [

    | engine editor suggestion |
    suggestion := 'suggestion text'.
    engine := CoSpyCompletionEnginePharoCopilot new.
    editor := CoTestEditorMock new.
    editor caret: 7.
    engine editor: editor.

    engine replaceTokenInEditorWith: suggestion.

    self assert: engine basicCalledWith equals: suggestion.
    self assert: editor caret equals: 7 + suggestion size
]

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
