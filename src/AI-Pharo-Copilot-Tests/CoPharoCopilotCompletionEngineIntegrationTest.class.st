Class {
	#name : 'CoPharoCopilotCompletionEngineIntegrationTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testBasicCalledWithAccessorDefaultsToNil [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	self assert: engine basicCalledWith isNil
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testBasicReplaceAfterIgnoredReplacementIsStillNil [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: nil.
	engine replaceTokenInEditorWith: ''.
	self assert: engine basicCalledWith isNil
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testBuilderIdentityAcrossReplaceCycles [
	| engine editor b1 b2 |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	b1 := engine completionBuilder.
	engine replaceTokenInEditorWith: 'x'.
	engine replaceTokenInEditorWith: 'yy'.
	engine replaceTokenInEditorWith: ''.
	b2 := engine completionBuilder.
	self assert: b1 identicalTo: b2
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testEditorAccessorReturnsAssignedEditor [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	self assert: engine editor identicalTo: editor
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testEmptyReplaceDoesNotInvokeBasicEvenIfNonEmptyFirst [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 0.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'first'.
	engine replaceTokenInEditorWith: ''.
	self assert: engine basicCalledWith equals: 'first'
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testEngineBuilderClassMatchesExpected [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: engine completionBuilder class name equals: #CoPharoCopilotResultSetBuilder
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testEngineInitiallyHasNoBasicCall [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	self assert: engine basicCalledWith isNil
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testEngineIsKindOfCoCompletionEngine [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine isKindOf: CoCompletionEngine)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testEngineSuccessiveIgnoreCallsIdempotent [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 100.
	engine editor: editor.
	engine replaceTokenInEditorWith: ''.
	engine replaceTokenInEditorWith: ''.
	engine replaceTokenInEditorWith: ''.
	self assert: editor caret equals: 100.
	self assert: engine basicCalledWith isNil
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testIgnoredReplacementLeavesBasicNilAndCaret [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 3.
	engine editor: editor.
	engine replaceTokenInEditorWith: ''.
	self assert: engine basicCalledWith isNil.
	self assert: editor caret equals: 3
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testManyIgnoredReplacementsLeaveCaretUnchanged [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 42.
	engine editor: editor.
	50 timesRepeat: [ engine replaceTokenInEditorWith: '' ].
	50 timesRepeat: [ engine replaceTokenInEditorWith: nil ].
	self assert: editor caret equals: 42
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testRealEngineRespondsToBasicReplaceTokenInEditorWith [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine respondsTo: #basicReplaceTokenInEditorWith:)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testRealEngineRespondsToCompletionBuilder [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine respondsTo: #completionBuilder)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testRealEngineRespondsToReplaceTokenInEditorWith [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine respondsTo: #replaceTokenInEditorWith:)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testRealEngineRespondsToShouldIgnoreReplacement [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine respondsTo: #shouldIgnoreReplacement:)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testReplaceTokenDoesNotTouchBuilderBuilder [
	| engine editor b |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	b := engine completionBuilder.
	engine replaceTokenInEditorWith: 'x'.
	self assert: engine completionBuilder identicalTo: b
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testShouldIgnoreAndReplaceConsistency [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 5.
	engine editor: editor.
	(engine shouldIgnoreReplacement: nil) ifTrue: [ engine replaceTokenInEditorWith: nil ].
	(engine shouldIgnoreReplacement: '') ifTrue: [ engine replaceTokenInEditorWith: '' ].
	self assert: editor caret equals: 5.
	self assert: engine basicCalledWith isNil
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testSpyDefaultEditorIsInstanceOfTestMock [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	self assert: (engine editor isKindOf: CoTestEditorMock)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testSpyEngineIsKindOfRealEngine [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	self assert: (engine isKindOf: CoPharoCopilotCompletionEngine)
]
