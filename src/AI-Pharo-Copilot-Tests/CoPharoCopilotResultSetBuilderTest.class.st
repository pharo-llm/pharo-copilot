Class {
	#name : 'CoPharoCopilotResultSetBuilderTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testApplyContentDoesNothingOnSnapshotMismatch [
	| b ctx ed |
	b := CopilotTestableBuilder new.
	ed := CoCopilotMockEditor new.
	ctx := CoCopilotContextMock new
		source: 'self ';
		position: 5;
		editor: ed;
		yourself.

	"Mismatch expectedPrefix => should not insert/replace."
	b applyContent: 'assert: ' toContext: ctx expectedPrefix: 'WRONG' suffix: '' contextInfo: Dictionary new.

	self assert: ed insertedText equals: ''.
	self assert: ctx replaceCount equals: 0
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testApplyContentInsertsAtCaretWhenEditorSupportsAddString [
	| b ctx ed |
	b := CopilotTestableBuilder new.
	ed := CoCopilotMockEditor new.
	ctx := CoCopilotContextMock new
		source: 'self ';
		position: 5;
		editor: ed;
		yourself.

	"Expected prefix/suffix must match snapshot."
	b applyContent: 'assert: ' toContext: ctx expectedPrefix: 'self ' suffix: '' contextInfo: Dictionary new.

	self assert: ed insertedText equals: 'assert: '.
	self assert: ctx replaceCount equals: 0
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testBuildCompletionDoesNotSnapshotWhenInsideWord [

	| b ctx |
	b := CopilotTestableBuilder new.
	ctx := CoCopilotContextMock new
		source: 'assert';
		position: 3;  "inside word"
		yourself.
	b completionContext: ctx.

	b buildCompletion.

	self deny: b snapshotWasCalled.
	self assert: b scheduledDelay isNil
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testBuildCompletionSchedulesWhenAtBoundary [
	| b ctx |
	b := CopilotTestableBuilder new.
	b debounceMilliseconds: 250.
	b idleMilliseconds: 2000.

	ctx := CoCopilotContextMock new
		source: 'self ';
		position: 5; "after space => boundary"
		yourself.
	b completionContext: ctx.

	b buildCompletion.

	self assert: b snapshotWasCalled.
	self assert: b scheduledDelay equals: 250.
	self assert: b scheduledPrefix equals: 'self '.
	self assert: b scheduledSuffix equals: ''
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testClassContextIsCached [

	| b ctx first second |
	b := CopilotCacheTestBuilder new.
	ctx := CoCopilotContextMock new behavior: Object; yourself.

	first := b classContextFor: ctx.
	second := b classContextFor: ctx.

	"First call should build instance+class side => 2 calls.
	Second call should be cached => still 2."
	self assert: b methodSourcesCallCount equals: 2.
	self assert: first equals: second
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCleanedContentFromEmptyResponse [
	| builder context |
	context := CoPharoCopilotContext new.
	context
		source: 'foo bar';
		position: 3.

	builder := CoPharoCopilotResultSetBuilder initializeOnContext: context.

	self assert: (builder cleanedContentFrom: '') equals: ''.

]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCleanedContentFromHandlesComplexCodeBlock [
	| builder raw cleaned |
	builder := CoPharoCopilotResultSetBuilder new.
	raw := 'Here is the code:', String lf, '```pharo', String lf, 
	       'method1', String lf, 'method2', String lf, '```', String lf, 
	       'More explanation here.'.
	cleaned := builder cleanedContentFrom: raw.
	self assert: cleaned equals: 'method1', String lf, 'method2'
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCleanedContentFromHandlesEmptyCodeBlock [
	| builder raw cleaned |
	builder := CoPharoCopilotResultSetBuilder new.
	raw := '```', String lf, '```'.
	cleaned := builder cleanedContentFrom: raw.
	self assert: cleaned equals: ''
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCleanedContentFromHandlesInlineFenceWithoutLineBreaks [
        | builder raw cleaned |
        builder := CoPharoCopilotResultSetBuilder new.
        raw := '```code``` trailing text'.
        cleaned := builder cleanedContentFrom: raw.

        self assert: cleaned equals: 'code``` trailing text'
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCleanedContentFromHandlesMultipleDoubleNewlines [
	| builder raw cleaned |
	builder := CoPharoCopilotResultSetBuilder new.
	raw := 'line1', String lf, 'line2', String lf, String lf, 
	       'This is explanation', String lf, String lf, 'More explanation'.
	cleaned := builder cleanedContentFrom: raw.
	self assert: cleaned equals: 'line1', String lf, 'line2'
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCleanedContentFromHandlesNilInput [
        | builder |
        builder := CoPharoCopilotResultSetBuilder new.

        self assert: (builder cleanedContentFrom: nil) equals: ''
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCleanedContentFromHandlesNoCodeBlock [
	| builder raw cleaned |
	builder := CoPharoCopilotResultSetBuilder new.
	raw := 'simple code without blocks'.
	cleaned := builder cleanedContentFrom: raw.
	self assert: cleaned equals: 'simple code without blocks'
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCleanedContentFromTrimsWhitespace [
	| builder raw cleaned |
	builder := CoPharoCopilotResultSetBuilder new.
	raw := '   ', String lf, 'code here', String lf, '   '.
	cleaned := builder cleanedContentFrom: raw.
	self assert: cleaned equals: 'code here'
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCleanedContentFromWithTextInput [
        | builder raw cleaned |
        builder := CoPharoCopilotResultSetBuilder new.
        raw := Text fromString: '```pharo', String lf, '^ 1', String lf, '```'.
        cleaned := builder cleanedContentFrom: raw.

        self assert: cleaned equals: '^ 1'
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testContextSnapshotIncludesPrefixAndSuffix [

        | builder context snapshot |
        builder := CoPharoCopilotResultSetBuilder new.
        context := CoCopilotContextMock new.
        context
                source: 'hello world';
                position: 5.

        snapshot := builder contextSnapshotFor: context.

        self assert: (snapshot at: #prefix) equals: 'hello'.
        self assert: (snapshot at: #suffix) equals: ' world'.
        self assert: (snapshot at: #position) equals: 5
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testDebounceOnlyProcessesLatest [
	| b ctx |
	b := CopilotDebounceTestBuilder new.
	ctx := CoCopilotContextMock new source: 'x '; position: 2; yourself.

	"Schedule A then immediately schedule B with same delay; only B should run."
	b scheduleCompletionFor: ctx prefix: 'A' suffix: '' contextInfo: Dictionary new delayMilliseconds: 30.
	b scheduleCompletionFor: ctx prefix: 'B' suffix: '' contextInfo: Dictionary new delayMilliseconds: 30.

	"Wait long enough"
	self assert: (b waitProcessedForMilliseconds: 200).
	self assert: b processedPrefix equals: 'B'
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testDelayIsFastAfterSpace [

	| b source pos |
	b := CoPharoCopilotResultSetBuilder new.
	b debounceMilliseconds: 250.
	b idleMilliseconds: 2000.

	source := 'self '.
	pos := source size. "caret after space"
	self assert: (b requestDelayForSource: source position: pos) equals: 250
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testDelayIsIdleWhenNoBoundaryTyped [

	| b source pos |
	b := CoPharoCopilotResultSetBuilder new.
	b debounceMilliseconds: 250.
	b idleMilliseconds: 2000.

	source := 'self'.
	pos := source size. "caret after 'f' (letter), not boundary"
	self assert: (b requestDelayForSource: source position: pos) equals: 2000
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testInitializeOnContextSetsCompletionContext [

	| builder context |
	context := CoPharoCopilotContext new.
	builder := CoPharoCopilotResultSetBuilder initializeOnContext: context.
	self assert: builder completionContext identicalTo: context
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testLoggingIsOffByDefault [

	"Reset to nil so default initializer runs"
	(CopilotSettings classPool includesKey: #loggingEnabled) ifTrue: [
		CopilotSettings classPool at: #loggingEnabled put: nil ].

	self deny: CopilotSettings loggingEnabled
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testShouldNotTriggerInsideWord [

	| b ctx |
	b := CoPharoCopilotResultSetBuilder new.
	ctx := CoCopilotContextMock new
		source: 'assert';
		position: 3;  "as|sert -> before='s' after='s' => inside word"
		yourself.

	self deny: (b shouldRequestCompletionForContext: ctx)
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testShouldTriggerAtWordEnd [
	| b ctx |
	b := CoPharoCopilotResultSetBuilder new.
	ctx := CoCopilotContextMock new
		source: 'assert';
		position: 6;  "assert| -> after=nil"
		yourself.

	self assert: (b shouldRequestCompletionForContext: ctx)
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testSkipsApplyingWhenContextChanged [

        | builder context contextInfo |
        builder := CoPharoCopilotResultSetBuilder new.
        context := CoCopilotContextMock new.
        context
                source: 'prefixBodyChanged';
                position: 6.
        contextInfo := Dictionary new
                                at: #cursorPosition put: 6;
                                yourself.

        builder
                applyContent: 'suggestion'
                toContext: context
                expectedPrefix: 'prefix'
                suffix: 'Body'
                contextInfo: contextInfo.

        self assert: context replacedToken isNil
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testUsesSuggestionWhenContextMatches [

        | builder context contextInfo |
        builder := CoPharoCopilotResultSetBuilder new.
        context := CoCopilotContextMock new.
        context
                source: 'sample code';
                position: 6.
        contextInfo := Dictionary new
                                at: #cursorPosition put: 6;
                                yourself.

        builder
                applyContent: 'suggestion'
                toContext: context
                expectedPrefix: 'sample'
                suffix: ' code'
                contextInfo: contextInfo.

        self assert: context replacedToken equals: 'suggestion'
]
