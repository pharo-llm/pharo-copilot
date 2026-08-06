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
	context := CoPCContext new.
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
CoPharoCopilotResultSetBuilderTest >> testCompletionEntriesSkipFallbackWhenAISuggestionExists [

	| builder context entries |
	builder := CopilotTestableBuilder new.
	context := CoCopilotContextMock new.

	entries := builder
		completionEntriesFrom: { 'aiCompletion' }
		inContext: context
		contextInfo: Dictionary new.

	self assert: entries size equals: 1.
	self assert: builder fallbackCallCount equals: 0
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCompletionEntriesUseFallbackWhenNoAISuggestionExists [

	| builder context entries |
	builder := CopilotTestableBuilder new.
	context := CoCopilotContextMock new.

	entries := builder
		completionEntriesFrom: { '' }
		inContext: context
		contextInfo: Dictionary new.

	self assert: entries size equals: 1.
	self assert: builder fallbackCallCount equals: 1
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCompletionLoggingRecordsLogprobsMetadata [

	CopilotSettings withDefaultSettingsDo: [
		| builder client mock logprobs contextInfo suggestions attempts attempt request response payload generated |
		CopilotSettings loggingEnabled: true.
		builder := CoPharoCopilotResultSetBuilder new.
		mock := OAHttpTransportMockExtended new.
		logprobs := {
			Dictionary new
				at: #token put: 'assert';
				at: #logprob put: -0.05;
				at: #top_logprobs put: {
					Dictionary new
						at: #token put: 'assert';
						at: #logprob put: -0.05;
						yourself };
				yourself }.
		mock mockResponse: (Dictionary new
			at: #response put: 'assert: true';
			at: #logprobs put: logprobs;
			at: #eval_count put: 2;
			yourself).

		client := CoPCOllamaClient basicNew.
		client instVarNamed: 'transport' put: mock.
		client instVarNamed: 'modelSpec' put: (CoPCModelSpec family: 'test-model' tag: nil label: 'test-model').
		client instVarNamed: 'stream' put: false.
		client instVarNamed: 'options' put: Dictionary new.
		client instVarNamed: 'fimTemplate' put: CoPCOllamaClient defaultFimGenerationTemplate.

		contextInfo := Dictionary new.
		suggestions := builder
			collectNormalizedSuggestionsFor: client
			prefix: 'self '
			suffix: ''
			context: ''
			contextInfo: contextInfo.

		self assert: suggestions equals: { 'assert: true' }.
		attempts := contextInfo at: #generationAttempts.
		self assert: attempts size equals: 1.
		attempt := attempts first.
		self assert: (attempt at: #suggestion) equals: 'assert: true'.
		request := attempt at: #request.
		self assert: (request at: #logprobs) equals: true.
		self assert: (request at: #top_logprobs) equals: CopilotSettings completionTopLogprobs.
		response := attempt at: #response.
		self assert: (response at: #logprobs) equals: logprobs.
		self assert: (response at: #eval_count) equals: 2.

		payload := CoPharoCopilotLogger
			initialCompletionPayloadForContextInfo: contextInfo
			prefix: 'self '
			suffix: ''
			classContext: ''
			cacheStats: Dictionary new.
		generated := payload at: #generated.
		self assert: (generated at: #suggestions) equals: { 'assert: true' }.
		self assert: (generated at: #attempts) equals: attempts asArray ]
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
	context := CoPCContext new.
	builder := CoPharoCopilotResultSetBuilder initializeOnContext: context.
	self assert: builder completionContext identicalTo: context
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testInteractionHistoryIsFinalContextSection [

	| builder base history result historyIndex sampleIndex |
	builder := CoPharoCopilotResultSetBuilder new.
	base := '<|repo_name|>Sample', String lf,
		'<|file_sep|>Sample', String lf,
		'Class { #name : #Sample }', String lf.
	history := 'Browser navigation history (Calypso):', String lf,
		'Current selection:', String lf,
		'  pane 1: Sample'.

	result := builder appendInteractionHistory: history toContext: base.

	historyIndex := result findString: '<|file_sep|>IDE interaction history' startingAt: 1.
	sampleIndex := result findString: '<|file_sep|>Sample' startingAt: 1.

	self assert: (result beginsWith: base).
	self assert: historyIndex > 0.
	self assert: sampleIndex > 0.
	self assert: historyIndex > sampleIndex.
	self assert: (result includesSubstring: history).
	self assert: (result endsWith: String lf)
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testInteractionHistoryUsesContextSectionWhenBaseIsEmpty [

	| builder result |
	builder := CoPharoCopilotResultSetBuilder new.

	result := builder
		appendInteractionHistory: 'Current selection: Sample'
		toContext: ''.

	self assert: (result beginsWith: '<|file_sep|>IDE interaction history').
	self assert: (result includesSubstring: 'Current selection: Sample').
	self assert: (result endsWith: String lf)
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testLiveEditorTypedAheadDoesNotCountAsStale [

	| builder context editor |
	builder := CoPharoCopilotResultSetBuilder new.
	editor := CoCopilotMockEditor new.
	editor
		text: 'self asStr';
		caret: 'self asStr' size + 1.
	context := CoCopilotContextMock new
		source: 'self as';
		position: 'self as' size;
		editor: editor;
		yourself.

	self deny: (builder
		hasStaleContextFor: context
		expectedPrefix: 'self as'
		suffix: '').
	self assert: (builder
		typedAheadIn: context
		expectedPrefix: 'self as'
		suffix: '') equals: 'Str'
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testSemanticContextAppendsAfterStaticContext [

	| builder context base source result |
	builder := CoPharoCopilotResultSetBuilder new.
	source := 'semanticContextExample', String lf, String tab, 'self as'.
	context := CoCopilotContextMock new
		behavior: Object;
		source: source;
		position: source size;
		yourself.
	base := '<|repo_name|>Object', String lf.

	result := builder
		appendSemanticCompletionContextFor: context
		prefix: source
		toContext: base.

	self assert: (result beginsWith: base).
	self assert: (result includesSubstring: '<|file_sep|>Semantic completion context').
	self assert: (result includesSubstring: 'Completion class: Object')
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testSemanticContextIncludesSelfReceiverType [

	| builder context source semantic |
	builder := CoPharoCopilotResultSetBuilder new.
	source := 'semanticContextExample', String lf, String tab, 'self as'.
	context := CoCopilotContextMock new
		behavior: Object;
		source: source;
		position: source size;
		yourself.

	semantic := builder semanticCompletionContextFor: context prefix: source.

	self assert: (semantic includesSubstring: 'Completion class: Object').
	self assert: (semantic includesSubstring: 'Typed token: as').
	self assert: (semantic includesSubstring: 'Current receiver: self').
	self assert: (semantic includesSubstring: 'Receiver type: Object')
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testSemanticContextUsesLiveBindingValueType [

	| builder context requestor source semantic |
	builder := CoPharoCopilotResultSetBuilder new.
	requestor := CoPCBindingRequestorDouble new.
	requestor bind: 'items' to: OrderedCollection new.
	source := 'items add'.
	context := CoCopilotContextMock new
		doItRequestor: requestor;
		source: source;
		position: source size;
		yourself.

	semantic := builder semanticCompletionContextFor: context prefix: source.

	self assert: (semantic includesSubstring: 'Typed token: add').
	self assert: (semantic includesSubstring: 'Current receiver: items').
	self assert: (semantic includesSubstring: 'Receiver type: OrderedCollection').
	self assert: (semantic includesSubstring: 'items -> OrderedCollection')
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testSemanticSelectorHintsAreLimitedAndFiltered [

	| builder hints |
	builder := CoPharoCopilotResultSetBuilder new.

	hints := builder
		semanticSelectorHintsForTypes: { Object }
		token: 'as'
		limit: 5.

	self assert: hints size <= 5.
	self assert: (hints allSatisfy: [ :each | each beginsWith: 'as' ])
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testVariableNameTypeHeuristicUsesAOrAnPrefix [

	| builder types names |
	builder := CoPharoCopilotResultSetBuilder new.

	types := builder
		semanticTypesForReceiverName: 'aCollection'
		inContext: nil
		behavior: nil.
	names := builder typeNamesStringFor: types.

	self assert: (names includesSubstring: 'Collection')
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testStripAlreadyTypedHandlesPartialOverlap [

	| builder |
	builder := CoPharoCopilotResultSetBuilder new.

	self assert: (builder stripAlreadyTyped: 'Str' fromSuggestion: 'String') equals: 'ing'.
	self assert: (builder stripAlreadyTyped: 'String' fromSuggestion: 'String') equals: ''.
	self assert: (builder stripAlreadyTyped: 'Str' fromSuggestion: 'ing') equals: 'ing'
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testScheduleCompletionRunsImmediatelyWhenDelayIsZero [

	| builder context |
	builder := CopilotDebounceTestBuilder new.
	context := CoCopilotContextMock new
		source: 'self ';
		position: 5;
		yourself.

	builder
		scheduleCompletionFor: context
		prefix: 'self '
		suffix: ''
		contextInfo: Dictionary new
		delayMilliseconds: 0.

	(Delay forMilliseconds: 100) wait.
	self assert: builder processedPrefix equals: 'self '
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
