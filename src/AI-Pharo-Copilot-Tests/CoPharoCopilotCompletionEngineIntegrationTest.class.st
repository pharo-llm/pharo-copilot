Class {
	#name : 'CoPharoCopilotCompletionEngineIntegrationTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testCompleteCycleOnFreshEngineYieldsExpectedState [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 10.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'done'.
	self assert: engine basicCalledWith equals: 'done'.
	self assert: editor caret equals: 14
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
CoPharoCopilotCompletionEngineIntegrationTest >> testReplaceAndRestoreCaretReturnsCaretToOriginal [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 7.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'abc'.
	engine restoreCaretTo: 7.
	self assert: editor caret equals: 7
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testRestoreCaretBeforeReplaceWorks [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 10.
	engine replaceTokenInEditorWith: 'hi'.
	self assert: editor caret equals: 12
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testReplaceTokenWithTrailingSpacesAdvancesBySize [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'abc   '.
	self assert: editor caret equals: 7
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testReplaceTokenWithLeadingSpacesAdvancesBySize [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	engine replaceTokenInEditorWith: '   abc'.
	self assert: editor caret equals: 7
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
CoPharoCopilotCompletionEngineIntegrationTest >> testMultipleRestoreCaretsOnlyLastSticks [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	1 to: 10 do: [ :i | engine restoreCaretTo: i ].
	self assert: editor caret equals: 10
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
CoPharoCopilotCompletionEngineIntegrationTest >> testManyNonEmptyReplacementsCumulative [
	| engine editor total |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	total := 1.
	#('abc' 'de' 'fghij' 'k') do: [ :s | engine replaceTokenInEditorWith: s. total := total + s size ].
	self assert: editor caret equals: total
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
CoPharoCopilotCompletionEngineIntegrationTest >> testTtokenStartPositionAfterIgnoredReplacementUnchanged [
	| engine editor p |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 12.
	engine editor: editor.
	p := engine tokenStartPosition.
	engine replaceTokenInEditorWith: ''.
	self assert: engine tokenStartPosition equals: p
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testTtokenStartPositionAfterNonEmptyReplacementFollowsCaret [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 5.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'abc'.
	self assert: engine tokenStartPosition equals: 8
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testRestoreCaretAfterReplaceResetsTtokenStartPosition [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 3.
	engine editor: editor.
	engine replaceTokenInEditorWith: 'abcd'.
	engine restoreCaretTo: 3.
	self assert: engine tokenStartPosition equals: 3
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testEngineIsKindOfCoCompletionEngine [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine isKindOf: CoCompletionEngine)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testSpyEngineIsKindOfRealEngine [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	self assert: (engine isKindOf: CoPharoCopilotCompletionEngine)
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
CoPharoCopilotCompletionEngineIntegrationTest >> testRealEngineRespondsToBasicReplaceTokenInEditorWith [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine respondsTo: #basicReplaceTokenInEditorWith:)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testRealEngineRespondsToShouldIgnoreReplacement [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine respondsTo: #shouldIgnoreReplacement:)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testRealEngineRespondsToRestoreCaretTo [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine respondsTo: #restoreCaretTo:)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testRealEngineRespondsToTtokenStartPosition [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine respondsTo: #tokenStartPosition)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testEngineBuilderClassMatchesExpected [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: engine completionBuilder class name equals: #CoPharoCopilotResultSetBuilder
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testEngineCanHandleRepeatedMixedCalls [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	editor caret: 1.
	engine editor: editor.
	20 timesRepeat: [
		engine replaceTokenInEditorWith: 'a'.
		engine replaceTokenInEditorWith: ''.
		engine replaceTokenInEditorWith: nil ].
	self assert: editor caret equals: 21
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
CoPharoCopilotCompletionEngineIntegrationTest >> testEngineInitiallyHasNoBasicCall [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	self assert: engine basicCalledWith isNil
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testRestoreCaretToZeroThenReplace [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 0.
	engine replaceTokenInEditorWith: 'x'.
	self assert: editor caret equals: 1
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
CoPharoCopilotCompletionEngineIntegrationTest >> testRestoreCaretKeepsEditorIdentity [
	| engine editor |
	engine := CoSpyCompletionEnginePharoCopilot new.
	editor := CoTestEditorMock new.
	engine editor: editor.
	engine restoreCaretTo: 5.
	self assert: engine editor identicalTo: editor
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testBasicCalledWithAccessorDefaultsToNil [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	self assert: engine basicCalledWith isNil
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
CoPharoCopilotCompletionEngineIntegrationTest >> testSpyDefaultEditorIsInstanceOfTestMock [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	self assert: (engine editor isKindOf: CoTestEditorMock)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineIntegrationTest >> testReplacementsOnSpyDefaultEditorWork [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	engine replaceTokenInEditorWith: 'abc'.
	self assert: engine basicCalledWith equals: 'abc'.
	self assert: engine editor caret equals: 4
]
