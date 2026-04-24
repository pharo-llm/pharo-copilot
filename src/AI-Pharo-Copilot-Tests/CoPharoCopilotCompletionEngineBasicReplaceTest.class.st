Class {
	#name : 'CoPharoCopilotCompletionEngineBasicReplaceTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase00 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: 'abc'.
	self assert: engine basicCalledWith equals: 'abc'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase01 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: 'x'.
	self assert: engine basicCalledWith equals: 'x'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase02 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: 'hello'.
	self assert: engine basicCalledWith equals: 'hello'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase03 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: 'world'.
	self assert: engine basicCalledWith equals: 'world'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase04 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: 'yourself'.
	self assert: engine basicCalledWith equals: 'yourself'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase05 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: 'self'.
	self assert: engine basicCalledWith equals: 'self'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase06 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: 'nil'.
	self assert: engine basicCalledWith equals: 'nil'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase07 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: '42'.
	self assert: engine basicCalledWith equals: '42'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase08 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: ' '.
	self assert: engine basicCalledWith equals: ' '
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase09 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: String tab.
	self assert: engine basicCalledWith equals: String tab
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase10 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: String lf.
	self assert: engine basicCalledWith equals: String lf
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase11 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: ''.
	self assert: engine basicCalledWith equals: ''
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase12 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: nil.
	self assert: engine basicCalledWith equals: nil
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase13 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: 'long suggestion text'.
	self assert: engine basicCalledWith equals: 'long suggestion text'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase14 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: 'with spaces'.
	self assert: engine basicCalledWith equals: 'with spaces'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase15 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: '"quoted"'.
	self assert: engine basicCalledWith equals: '"quoted"'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase16 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: ''''.
	self assert: engine basicCalledWith equals: ''''
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase17 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: 'unicode: é'.
	self assert: engine basicCalledWith equals: 'unicode: é'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase18 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: '#symbol'.
	self assert: engine basicCalledWith equals: '#symbol'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase19 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: '^ result'.
	self assert: engine basicCalledWith equals: '^ result'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase20 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: 'assert: '.
	self assert: engine basicCalledWith equals: 'assert: '
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase21 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: 'a', 'b'.
	self assert: engine basicCalledWith equals: 'a', 'b'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase22 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: (String new: 100 withAll: $z).
	self assert: engine basicCalledWith equals: (String new: 100 withAll: $z)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase23 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: 'multi', String lf, 'line'.
	self assert: engine basicCalledWith equals: 'multi', String lf, 'line'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase24 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: 'x := 1'.
	self assert: engine basicCalledWith equals: 'x := 1'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase25 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: '@'.
	self assert: engine basicCalledWith equals: '@'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase26 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: '|'.
	self assert: engine basicCalledWith equals: '|'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase27 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: '~'.
	self assert: engine basicCalledWith equals: '~'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase28 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: 'numeric 3.14'.
	self assert: engine basicCalledWith equals: 'numeric 3.14'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBasicReplaceTest >> testBasicReplaceSpyRecordsCase29 [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine basicReplaceTokenInEditorWith: 'block [ :a | a ]'.
	self assert: engine basicCalledWith equals: 'block [ :a | a ]'
]
