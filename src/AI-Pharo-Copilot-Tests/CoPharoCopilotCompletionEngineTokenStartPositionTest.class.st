Class {
	#name : 'CoPharoCopilotCompletionEngineTtokenStartPositionTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt0 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 0.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 0
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt2 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 2.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 2
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt3 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 3.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 3
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt4 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 4.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 4
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt5 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 5.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 5
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt7 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 7.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 7
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 10
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt13 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 13.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 13
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt20 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 20.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 20
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt25 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 25.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 25
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt50 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 50.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 50
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt99 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 99.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 99
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt100 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 100.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 100
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt200 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 200.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 200
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt500 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 500.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 500
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt1000 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1000.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 1000
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt1024 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1024.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 1024
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt4096 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 4096.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 4096
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionEqualsCaretAt10000 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10000.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 10000
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionDefaultEditorCaretIsOne [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionReturnsInteger [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 5.
	engine editor: editor.
	self assert: engine tokenStartPosition isInteger
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionIsIdempotent [
	| engine editor a b |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 42.
	engine editor: editor.
	a := engine tokenStartPosition.
	b := engine tokenStartPosition.
	self assert: a equals: b
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionChangesWithCaret [
	| engine editor p1 p2 |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 5.
	engine editor: editor.
	p1 := engine tokenStartPosition.
	editor caret: 20.
	p2 := engine tokenStartPosition.
	self deny: p1 equals: p2
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionMatchesCaretAfterMutation [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	editor caret: 10.
	self assert: engine tokenStartPosition equals: editor caret
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime11 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 11.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 11
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime23 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 23.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 23
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime37 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 37.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 37
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime47 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 47.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 47
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime59 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 59.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 59
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime71 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 71.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 71
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime83 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 83.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 83
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime97 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 97.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 97
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime109 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 109.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 109
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime127 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 127.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 127
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime149 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 149.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 149
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime167 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 167.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 167
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime181 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 181.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 181
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime199 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 199.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 199
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime211 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 211.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 211
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime227 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 227.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 227
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime241 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 241.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 241
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionAtPrime257 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 257.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 257
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionLargeCaret [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1000000.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: 1000000
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineTtokenStartPositionTest >> testTtokenStartPositionSmallIntMax [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: SmallInteger maxVal.
	engine editor: editor.
	self assert: engine tokenStartPosition equals: SmallInteger maxVal
]
