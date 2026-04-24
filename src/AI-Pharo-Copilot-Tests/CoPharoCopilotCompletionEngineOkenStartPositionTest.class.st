Class {
	#name : 'CoPharoCopilotCompletionEngineOkenStartPositionTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt0 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 0.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 0
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt2 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 2.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 2
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt3 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 3.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 3
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt4 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 4.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 4
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt5 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 5.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 5
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt7 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 7.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 7
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 10
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt13 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 13.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 13
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt20 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 20.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 20
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt25 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 25.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 25
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt50 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 50.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 50
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt99 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 99.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 99
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt100 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 100.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 100
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt200 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 200.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 200
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt500 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 500.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 500
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt1000 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1000.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 1000
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt1024 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1024.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 1024
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt4096 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 4096.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 4096
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionEqualsCaretAt10000 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10000.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 10000
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionDefaultEditorCaretIsOne [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionReturnsInteger [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 5.
	engine editor: editor.
	self assert: engine okenStartPosition isInteger
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionIsIdempotent [
	| engine editor a b |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 42.
	engine editor: editor.
	a := engine okenStartPosition.
	b := engine okenStartPosition.
	self assert: a equals: b
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionChangesWithCaret [
	| engine editor p1 p2 |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 5.
	engine editor: editor.
	p1 := engine okenStartPosition.
	editor caret: 20.
	p2 := engine okenStartPosition.
	self deny: p1 equals: p2
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionMatchesCaretAfterMutation [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	editor caret: 10.
	self assert: engine okenStartPosition equals: editor caret
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime11 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 11.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 11
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime23 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 23.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 23
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime37 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 37.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 37
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime47 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 47.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 47
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime59 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 59.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 59
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime71 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 71.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 71
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime83 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 83.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 83
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime97 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 97.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 97
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime109 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 109.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 109
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime127 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 127.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 127
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime149 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 149.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 149
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime167 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 167.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 167
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime181 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 181.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 181
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime199 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 199.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 199
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime211 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 211.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 211
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime227 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 227.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 227
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime241 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 241.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 241
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionAtPrime257 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 257.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 257
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionLargeCaret [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1000000.
	engine editor: editor.
	self assert: engine okenStartPosition equals: 1000000
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineOkenStartPositionTest >> testOkenStartPositionSmallIntMax [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: SmallInteger maxVal.
	engine editor: editor.
	self assert: engine okenStartPosition equals: SmallInteger maxVal
]
