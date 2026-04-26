Class {
	#name : 'CoPharoCopilotCompletionEngineReplaceTokenTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNilSuggestionIgnoredAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: nil.
	self assert: engine basicCalledWith isNil.
	self assert: editor caret equals: 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNilSuggestionIgnoredAtCaret5 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 5.
	engine editor: editor.
	engine replaceTokenInEditorWith: nil.
	self assert: engine basicCalledWith isNil.
	self assert: editor caret equals: 5
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNilSuggestionIgnoredAtCaret100 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 100.
	engine editor: editor.
	engine replaceTokenInEditorWith: nil.
	self assert: engine basicCalledWith isNil.
	self assert: editor caret equals: 100
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNilSuggestionIgnoredAtCaretLarge [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 99999.
	engine editor: editor.
	engine replaceTokenInEditorWith: nil.
	self assert: engine basicCalledWith isNil.
	self assert: editor caret equals: 99999
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testEmptySuggestionIgnoredAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: ''.
	self assert: engine basicCalledWith isNil.
	self assert: editor caret equals: 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testEmptySuggestionIgnoredAtCaret5 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 5.
	engine editor: editor.
	engine replaceTokenInEditorWith: ''.
	self assert: engine basicCalledWith isNil.
	self assert: editor caret equals: 5
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testEmptySuggestionIgnoredAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: ''.
	self assert: engine basicCalledWith isNil.
	self assert: editor caret equals: 10
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testEmptySuggestionIgnoredAtCaret50 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 50.
	engine editor: editor.
	engine replaceTokenInEditorWith: ''.
	self assert: engine basicCalledWith isNil.
	self assert: editor caret equals: 50
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testEmptySuggestionIgnoredAtCaretZero [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 0.
	engine editor: editor.
	engine replaceTokenInEditorWith: ''.
	self assert: engine basicCalledWith isNil.
	self assert: editor caret equals: 0
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testEmptyFromStreamContentsIgnored [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 7.
	engine editor: editor.
	engine replaceTokenInEditorWith: (String streamContents: [ :s | ]).
	self assert: engine basicCalledWith isNil.
	self assert: editor caret equals: 7
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testEmptyStringNewIgnored [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 3.
	engine editor: editor.
	engine replaceTokenInEditorWith: String new.
	self assert: engine basicCalledWith isNil.
	self assert: editor caret equals: 3
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptySingleCharAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'x'.
	self assert: engine basicCalledWith equals: 'x'.
	self assert: editor caret equals: 1 + 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptySingleCharAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'x'.
	self assert: engine basicCalledWith equals: 'x'.
	self assert: editor caret equals: 10 + 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyTwoCharsAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'yy'.
	self assert: engine basicCalledWith equals: 'yy'.
	self assert: editor caret equals: 1 + 2
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyTwoCharsAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'yy'.
	self assert: engine basicCalledWith equals: 'yy'.
	self assert: editor caret equals: 10 + 2
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyThreeCharsAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'abc'.
	self assert: engine basicCalledWith equals: 'abc'.
	self assert: editor caret equals: 1 + 3
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyThreeCharsAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'abc'.
	self assert: engine basicCalledWith equals: 'abc'.
	self assert: editor caret equals: 10 + 3
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyFourCharsAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'wxyz'.
	self assert: engine basicCalledWith equals: 'wxyz'.
	self assert: editor caret equals: 1 + 4
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyFourCharsAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'wxyz'.
	self assert: engine basicCalledWith equals: 'wxyz'.
	self assert: editor caret equals: 10 + 4
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyFiveCharsAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'hello'.
	self assert: engine basicCalledWith equals: 'hello'.
	self assert: editor caret equals: 1 + 5
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyFiveCharsAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'hello'.
	self assert: engine basicCalledWith equals: 'hello'.
	self assert: editor caret equals: 10 + 5
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptySixCharsAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'foobar'.
	self assert: engine basicCalledWith equals: 'foobar'.
	self assert: editor caret equals: 1 + 6
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptySixCharsAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'foobar'.
	self assert: engine basicCalledWith equals: 'foobar'.
	self assert: editor caret equals: 10 + 6
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptySevenCharsAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'message'.
	self assert: engine basicCalledWith equals: 'message'.
	self assert: editor caret equals: 1 + 7
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptySevenCharsAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'message'.
	self assert: engine basicCalledWith equals: 'message'.
	self assert: editor caret equals: 10 + 7
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyEightCharsAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'computer'.
	self assert: engine basicCalledWith equals: 'computer'.
	self assert: editor caret equals: 1 + 8
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyEightCharsAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'computer'.
	self assert: engine basicCalledWith equals: 'computer'.
	self assert: editor caret equals: 10 + 8
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyNineCharsAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'algorithm'.
	self assert: engine basicCalledWith equals: 'algorithm'.
	self assert: editor caret equals: 1 + 9
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyNineCharsAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'algorithm'.
	self assert: engine basicCalledWith equals: 'algorithm'.
	self assert: editor caret equals: 10 + 9
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyTenCharsAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'completion'.
	self assert: engine basicCalledWith equals: 'completion'.
	self assert: editor caret equals: 1 + 10
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyTenCharsAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'completion'.
	self assert: engine basicCalledWith equals: 'completion'.
	self assert: editor caret equals: 10 + 10
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyElevenCharsAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'suggestion'.
	self assert: engine basicCalledWith equals: 'suggestion'.
	self assert: editor caret equals: 1 + 10
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyElevenCharsAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'suggestion'.
	self assert: engine basicCalledWith equals: 'suggestion'.
	self assert: editor caret equals: 10 + 10
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyTwelveCharsAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'example text'.
	self assert: engine basicCalledWith equals: 'example text'.
	self assert: editor caret equals: 1 + 12
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyTwelveCharsAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'example text'.
	self assert: engine basicCalledWith equals: 'example text'.
	self assert: editor caret equals: 10 + 12
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyThirteenCharsAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'hello world! '.
	self assert: engine basicCalledWith equals: 'hello world! '.
	self assert: editor caret equals: 1 + 13
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyThirteenCharsAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'hello world! '.
	self assert: engine basicCalledWith equals: 'hello world! '.
	self assert: editor caret equals: 10 + 13
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyShortSelectorAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'yourself'.
	self assert: engine basicCalledWith equals: 'yourself'.
	self assert: editor caret equals: 1 + 8
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyShortSelectorAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'yourself'.
	self assert: engine basicCalledWith equals: 'yourself'.
	self assert: editor caret equals: 10 + 8
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptySingleSpaceAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: ' '.
	self assert: engine basicCalledWith equals: ' '.
	self assert: editor caret equals: 1 + 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptySingleSpaceAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: ' '.
	self assert: engine basicCalledWith equals: ' '.
	self assert: editor caret equals: 10 + 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyWhitespaceAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: '   '.
	self assert: engine basicCalledWith equals: '   '.
	self assert: editor caret equals: 1 + 3
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyWhitespaceAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: '   '.
	self assert: engine basicCalledWith equals: '   '.
	self assert: editor caret equals: 10 + 3
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyTabCharAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: String tab.
	self assert: engine basicCalledWith equals: String tab.
	self assert: editor caret equals: 1 + 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyTabCharAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: String tab.
	self assert: engine basicCalledWith equals: String tab.
	self assert: editor caret equals: 10 + 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyNewlineCharAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: String lf.
	self assert: engine basicCalledWith equals: String lf.
	self assert: editor caret equals: 1 + 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyNewlineCharAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: String lf.
	self assert: engine basicCalledWith equals: String lf.
	self assert: editor caret equals: 10 + 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyCrCharAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: String cr.
	self assert: engine basicCalledWith equals: String cr.
	self assert: editor caret equals: 1 + 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyCrCharAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: String cr.
	self assert: engine basicCalledWith equals: String cr.
	self assert: editor caret equals: 10 + 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyAssertSelectorAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'assert: '.
	self assert: engine basicCalledWith equals: 'assert: '.
	self assert: editor caret equals: 1 + 8
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyAssertSelectorAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'assert: '.
	self assert: engine basicCalledWith equals: 'assert: '.
	self assert: editor caret equals: 10 + 8
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyBinaryOpAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: '+ '.
	self assert: engine basicCalledWith equals: '+ '.
	self assert: editor caret equals: 1 + 2
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyBinaryOpAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: '+ '.
	self assert: engine basicCalledWith equals: '+ '.
	self assert: editor caret equals: 10 + 2
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyUnaryMessageAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'yourself'.
	self assert: engine basicCalledWith equals: 'yourself'.
	self assert: editor caret equals: 1 + 8
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyUnaryMessageAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'yourself'.
	self assert: engine basicCalledWith equals: 'yourself'.
	self assert: editor caret equals: 10 + 8
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyCascadeExampleAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: '; yourself'.
	self assert: engine basicCalledWith equals: '; yourself'.
	self assert: editor caret equals: 1 + 10
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyCascadeExampleAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: '; yourself'.
	self assert: engine basicCalledWith equals: '; yourself'.
	self assert: editor caret equals: 10 + 10
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyKeywordMessageAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'at: 1 put: 2'.
	self assert: engine basicCalledWith equals: 'at: 1 put: 2'.
	self assert: editor caret equals: 1 + 12
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyKeywordMessageAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'at: 1 put: 2'.
	self assert: engine basicCalledWith equals: 'at: 1 put: 2'.
	self assert: editor caret equals: 10 + 12
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptySmalltalkArrayAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: '#(1 2 3)'.
	self assert: engine basicCalledWith equals: '#(1 2 3)'.
	self assert: editor caret equals: 1 + 8
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptySmalltalkArrayAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: '#(1 2 3)'.
	self assert: engine basicCalledWith equals: '#(1 2 3)'.
	self assert: editor caret equals: 10 + 8
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyBlockExprAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: '[ :x | x + 1 ]'.
	self assert: engine basicCalledWith equals: '[ :x | x + 1 ]'.
	self assert: editor caret equals: 1 + 14
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyBlockExprAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: '[ :x | x + 1 ]'.
	self assert: engine basicCalledWith equals: '[ :x | x + 1 ]'.
	self assert: editor caret equals: 10 + 14
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptySymbolLiteralAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: '#foo'.
	self assert: engine basicCalledWith equals: '#foo'.
	self assert: editor caret equals: 1 + 4
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptySymbolLiteralAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: '#foo'.
	self assert: engine basicCalledWith equals: '#foo'.
	self assert: editor caret equals: 10 + 4
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyCommentAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: '"a comment"'.
	self assert: engine basicCalledWith equals: '"a comment"'.
	self assert: editor caret equals: 1 + 11
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyCommentAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: '"a comment"'.
	self assert: engine basicCalledWith equals: '"a comment"'.
	self assert: editor caret equals: 10 + 11
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyClassNameAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'OrderedCollection'.
	self assert: engine basicCalledWith equals: 'OrderedCollection'.
	self assert: editor caret equals: 1 + 17
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyClassNameAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'OrderedCollection'.
	self assert: engine basicCalledWith equals: 'OrderedCollection'.
	self assert: editor caret equals: 10 + 17
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyMethodSelectorAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'do:separatedBy:'.
	self assert: engine basicCalledWith equals: 'do:separatedBy:'.
	self assert: editor caret equals: 1 + 15
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyMethodSelectorAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'do:separatedBy:'.
	self assert: engine basicCalledWith equals: 'do:separatedBy:'.
	self assert: editor caret equals: 10 + 15
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyReturnStmtAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: '^ self'.
	self assert: engine basicCalledWith equals: '^ self'.
	self assert: editor caret equals: 1 + 6
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyReturnStmtAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: '^ self'.
	self assert: engine basicCalledWith equals: '^ self'.
	self assert: editor caret equals: 10 + 6
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyAssignmentExprAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'x := 1'.
	self assert: engine basicCalledWith equals: 'x := 1'.
	self assert: editor caret equals: 1 + 6
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyAssignmentExprAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'x := 1'.
	self assert: engine basicCalledWith equals: 'x := 1'.
	self assert: editor caret equals: 10 + 6
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyVariableNameAtCaret1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'aVariable'.
	self assert: engine basicCalledWith equals: 'aVariable'.
	self assert: editor caret equals: 1 + 9
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNonEmptyVariableNameAtCaret10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'aVariable'.
	self assert: engine basicCalledWith equals: 'aVariable'.
	self assert: editor caret equals: 10 + 9
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testSecondCallOverwritesFirst [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'first'.
	engine replaceTokenInEditorWith: 'second'.
	self assert: engine basicCalledWith equals: 'second'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testEmptyAfterNonEmptyKeepsPreviousBasic [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'x'.
	engine replaceTokenInEditorWith: ''.
	self assert: engine basicCalledWith equals: 'x'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNilAfterNonEmptyKeepsPreviousBasic [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'x'.
	engine replaceTokenInEditorWith: nil.
	self assert: engine basicCalledWith equals: 'x'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testNilAfterNonEmptyKeepsCaretAdvanced [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'abc'.
	engine replaceTokenInEditorWith: nil.
	self assert: editor caret equals: 4
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testReplaceWithLongSuggestionAdvancesCaret [
	| engine editor s |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	s := String new: 1000 withAll: $z.
	engine replaceTokenInEditorWith: s.
	self assert: editor caret equals: 1001
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testReplaceVeryLongSuggestionAdvancesCaret [
	| engine editor s |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 100.
	engine editor: editor.
	s := String new: 5000 withAll: $a.
	engine replaceTokenInEditorWith: s.
	self assert: editor caret equals: 5100
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testReplaceRecordsBasicCallOnce [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'abc'.
	self assert: engine basicCalledWith equals: 'abc'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testReplaceEmptyLeavesBasicNil [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: ''.
	self assert: engine basicCalledWith isNil
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testReplaceNilLeavesBasicNil [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: nil.
	self assert: engine basicCalledWith isNil
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testUnicodeSuggestionAdvancesCaret [
	| engine editor s |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	s := 'caf' , (String with: (Character value: 233)).
	engine replaceTokenInEditorWith: s.
	self assert: editor caret equals: 1 + s size
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testSuggestionWithNewlineAdvancesCaret [
	| engine editor s |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 5.
	engine editor: editor.
	s := 'line1' , String lf , 'line2'.
	engine replaceTokenInEditorWith: s.
	self assert: editor caret equals: 5 + s size
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testSuggestionWithTabsAdvancesCaret [
	| engine editor s |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 2.
	engine editor: editor.
	s := String tab , 'indented' , String lf.
	engine replaceTokenInEditorWith: s.
	self assert: editor caret equals: 2 + s size
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testReplaceDoesNotChangeBuilder [
	| engine editor builder |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	builder := engine completionBuilder.
	engine replaceTokenInEditorWith: 'abc'.
	self assert: engine completionBuilder identicalTo: builder
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineReplaceTokenTest >> testSequentialNonEmptyReplacementsAccumulateCaret [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'ab'.
	engine replaceTokenInEditorWith: 'cd'.
	engine replaceTokenInEditorWith: 'ef'.
	self assert: editor caret equals: 1 + 2 + 2 + 2
]
