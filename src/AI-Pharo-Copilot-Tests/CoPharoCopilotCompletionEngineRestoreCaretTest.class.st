Class {
	#name : 'CoPharoCopilotCompletionEngineRestoreCaretTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 1.
	self assert: editor caret equals: 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition2 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 2.
	self assert: editor caret equals: 2
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition3 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 3.
	self assert: editor caret equals: 3
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition5 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 5.
	self assert: editor caret equals: 5
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition7 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 7.
	self assert: editor caret equals: 7
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 10.
	self assert: editor caret equals: 10
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition15 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 15.
	self assert: editor caret equals: 15
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition20 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 20.
	self assert: editor caret equals: 20
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition25 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 25.
	self assert: editor caret equals: 25
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition50 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 50.
	self assert: editor caret equals: 50
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition100 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 100.
	self assert: editor caret equals: 100
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition200 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 200.
	self assert: editor caret equals: 200
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition500 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 500.
	self assert: editor caret equals: 500
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition999 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 999.
	self assert: editor caret equals: 999
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition1000 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 1000.
	self assert: editor caret equals: 1000
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition1024 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 1024.
	self assert: editor caret equals: 1024
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition1500 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 1500.
	self assert: editor caret equals: 1500
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition2048 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 2048.
	self assert: editor caret equals: 2048
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition5000 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 5000.
	self assert: editor caret equals: 5000
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPosition10000 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 10000.
	self assert: editor caret equals: 10000
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToZero [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 0.
	self assert: editor caret equals: 0
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToNegative [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: -1.
	self assert: editor caret equals: -1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToMaxSmallInt [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: SmallInteger maxVal.
	self assert: editor caret equals: SmallInteger maxVal
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretOverwritesPreviousCaret [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 42.
	engine editor: editor.
	engine restoreCaretTo: 7.
	self assert: editor caret equals: 7
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretMultipleTimes [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 1.
	engine restoreCaretTo: 5.
	engine restoreCaretTo: 9.
	self assert: editor caret equals: 9
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretDoesNotModifyInsertedText [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoCopilotMockEditor new.
	engine editor: editor.
	engine restoreCaretTo: 10.
	self assert: editor insertedText equals: ''
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretSetsStartIndex [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoCopilotMockEditor new.
	engine editor: editor.
	engine restoreCaretTo: 15.
	self assert: editor startIndex equals: 15
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretCollapsesSelection [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoCopilotMockEditor new.
	engine editor: editor.
	engine restoreCaretTo: 5.
	self assert: editor selectionIsCollapsed
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretSetsSelectionStartAndStop [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoCopilotMockEditor new.
	engine editor: editor.
	engine restoreCaretTo: 8.
	self assert: editor selectionStart equals: 8.
	self assert: editor selectionStop equals: 7
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretWithMockEditorAt1 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoCopilotMockEditor new.
	engine editor: editor.
	engine restoreCaretTo: 1.
	self assert: editor startIndex equals: 1
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretWithMockEditorAt10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoCopilotMockEditor new.
	engine editor: editor.
	engine restoreCaretTo: 10.
	self assert: editor startIndex equals: 10
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretWithMockEditorAt100 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoCopilotMockEditor new.
	engine editor: editor.
	engine restoreCaretTo: 100.
	self assert: editor startIndex equals: 100
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretWithMockEditorAt1000 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoCopilotMockEditor new.
	engine editor: editor.
	engine restoreCaretTo: 1000.
	self assert: editor startIndex equals: 1000
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretReturnsEngineSuperBehaviorIgnored [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 3.
	self assert: editor caret equals: 3
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime01 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 11.
	self assert: editor caret equals: 11
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime02 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 13.
	self assert: editor caret equals: 13
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime03 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 17.
	self assert: editor caret equals: 17
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime04 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 19.
	self assert: editor caret equals: 19
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime05 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 23.
	self assert: editor caret equals: 23
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime06 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 29.
	self assert: editor caret equals: 29
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime07 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 31.
	self assert: editor caret equals: 31
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime08 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 37.
	self assert: editor caret equals: 37
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime09 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 41.
	self assert: editor caret equals: 41
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime10 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 43.
	self assert: editor caret equals: 43
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime11 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 47.
	self assert: editor caret equals: 47
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime12 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 53.
	self assert: editor caret equals: 53
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime13 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 59.
	self assert: editor caret equals: 59
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime14 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 61.
	self assert: editor caret equals: 61
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime15 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 67.
	self assert: editor caret equals: 67
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime16 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 71.
	self assert: editor caret equals: 71
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime17 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 73.
	self assert: editor caret equals: 73
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime18 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 79.
	self assert: editor caret equals: 79
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime19 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 83.
	self assert: editor caret equals: 83
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineRestoreCaretTest >> testRestoreCaretToPrime20 [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 89.
	self assert: editor caret equals: 89
]
