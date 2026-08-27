Class {
	#name : 'CoPharoCopilotResultSetBuilderTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCompletionRouterClassifiesSelectorVariableAndStatement [

	| builder router selectorContext variableContext statementContext statementSource |
	builder := CoPharoCopilotResultSetBuilder new.
	router := CoPCCompletionRouter new.
	selectorContext := CoCopilotContextMock new
		source: 'self as';
		position: 'self as' size;
		yourself.
	variableContext := CoCopilotContextMock new
		source: 'localVar';
		position: 'localVar' size;
		yourself.
	statementSource := 'self doSomething.'.
	statementContext := CoCopilotContextMock new
		source: statementSource;
		position: statementSource size;
		yourself.

	self
		assert: (router classifyContext: selectorContext prefix: selectorContext source builder: builder)
		equals: #selector.
	self
		assert: (router classifyContext: variableContext prefix: variableContext source builder: builder)
		equals: #variable.
	self
		assert: (router classifyContext: statementContext prefix: statementSource builder: builder)
		equals: #statement
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCompletionGenerationPolicyUsesSmallBudgetsForShortRoutes [

	| policy |
	policy := CoPCCompletionGenerationPolicy new.

	self assert: (policy numPredictFor: #selector) equals: 8.
	self assert: (policy numPredictFor: #variable) equals: 8.
	self assert: (policy numPredictFor: #statement) equals: 24.
	self assert: (policy numPredictFor: #unknown) equals: 24
]

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
CoPharoCopilotResultSetBuilderTest >> testBuildCompletionDoesNotBuildClassContextSynchronously [

	| b ctx |
	b := CopilotTestableBuilder new.
	ctx := CoCopilotContextMock new
		behavior: Object;
		source: 'temporaryName';
		position: 'temporaryName' size;
		yourself.
	b completionContext: ctx.

	b buildCompletion.

	self assert: b scheduledPrefix equals: 'temporaryName'.
	self assert: b classContextCallCount equals: 0
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testBuildCompletionOpensFastCachedCompletionWithLocalFallbackWithoutClassContext [

	| b ctx entries |
	b := CopilotTestableBuilder new.
	ctx := CoCopilotContextMock new
		source: 'temporaryName';
		position: 'temporaryName' size;
		yourself.
	b completionContext: ctx.
	b completionCache
		at: 'temporaryName'
		suffix: ''
		context: (b fastCacheContextFor: ctx prefix: 'temporaryName')
		put: { 'CompletedValue' }.

	b buildCompletion.

	entries := b openedEntries.
	self assert: entries size equals: 1.
	self assert: entries first contents equals: 'CompletedValue'.
	self assert: b scheduledDelay isNil.
	self assert: b classContextCallCount equals: 0.
	self assert: b fallbackCallCount equals: 0.
	self assert: b semanticAstCallCount equals: 0
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testFastCacheIgnoresNearMatchForImmediateCompletion [

	| b ctx contextInfo cached |
	b := CopilotTestableBuilder new.
	ctx := CoCopilotContextMock new
		source: 'self si';
		position: 'self si' size;
		yourself.
	b completionCache
		at: 'self s'
		suffix: ''
		context: (b fastCacheContextFor: ctx prefix: 'self s')
		put: { 'inspect' }.

	contextInfo := Dictionary new.
	cached := b
		fastCachedSuggestionsFor: ctx
		prefix: 'self si'
		suffix: ''
		contextInfo: contextInfo.

	self assert: cached isNil.
	self deny: (contextInfo at: #cacheHit)
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testBuildCompletionOpensFastCacheBeforeSemanticRerank [

	| b ctx entries |
	b := CopilotTestableBuilder new.
	ctx := CoCopilotContextMock new
		behavior: Object;
		source: 'self as';
		position: 'self as' size;
		yourself.
	b completionContext: ctx.
	b completionCache
		at: 'self as'
		suffix: ''
		context: (b fastCacheContextFor: ctx prefix: 'self as')
		put: { 'DefinitelyNotASelector' }.

	b buildCompletion.

	entries := b openedEntries.
	self assert: b fallbackCallCount equals: 0.
	self assert: entries first contents equals: 'DefinitelyNotASelector'.
	self assert: b scheduledDelay isNil
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testBuildCompletionUsesLocalFastPathForSemanticSelectorTail [

	| b ctx entries |
	b := CopilotTestableBuilder new.
	ctx := CoCopilotContextMock new
		behavior: Object;
		source: 'self as';
		position: 'self as' size;
		yourself.
	b completionContext: ctx.

	b buildCompletion.

	entries := b openedEntries.
	self assert: b fallbackCallCount equals: 1.
	self assert: entries size equals: 1.
	self assert: entries first contents equals: 'fallbackCompletion'.
	self assert: b scheduledDelay isNil
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testBuildCompletionUsesStandaloneFallbackInScriptingContext [

	| b ctx result |
	b := CopilotTestableBuilder new.
	ctx := CoCopilotContextMock new
		isScripting: true;
		source: 'Ord';
		position: 3;
		yourself.
	b completionContext: ctx.

	result := b buildCompletion.

	self assert: result equals: #fallbackResultSet.
	self assert: b fallbackCallCount equals: 1.
	self assert: b scheduledDelay isNil
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testBuildCompletionUsesEmptyResultSetWhenStandaloneFallbackFails [

	| b ctx result |
	b := CopilotNilFallbackTestBuilder new.
	ctx := CoCopilotContextMock new
		isScripting: true;
		source: 'Ord';
		position: 3;
		yourself.
	b completionContext: ctx.

	result := b buildCompletion.

	self deny: result isNil.
	self assert: (result isKindOf: CoResultSet).
	self assert: b fallbackCallCount equals: 1.
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
CoPharoCopilotResultSetBuilderTest >> testClassContextPlacesRecentCodeChangesBeforeStaticContext [

	| builder context source result headerIndex changesIndex staticIndex previousHistoryEnabled |
	previousHistoryEnabled := CoPCContextNavigationHistory enabled.
	[
		CoPCContextNavigationHistory enabled: false.
		builder := CopilotCacheTestBuilder new.
		builder recentCodeChangesForPrompt: 'EpMethodModification: Object>>printString [Kernel]'.
		source := 'self as'.
		context := CoCopilotContextMock new
			behavior: Object;
			source: source;
			position: source size;
			yourself.

		result := builder classContextFor: context prefix: source.

		headerIndex := result findString: '<|repo_name|>Object' startingAt: 1.
		changesIndex := result findString: '<|file_sep|>Recent code changes' startingAt: 1.
		staticIndex := result findString: '<|file_sep|>Object' startingAt: 1.

		self assert: headerIndex equals: 1.
		self assert: changesIndex > headerIndex.
		self assert: staticIndex > changesIndex.
		self assert: (result includesSubstring: 'EpMethodModification: Object>>printString [Kernel]') ]
		ensure: [ CoPCContextNavigationHistory enabled: previousHistoryEnabled ]
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
CoPharoCopilotResultSetBuilderTest >> testCompletionEntriesAppendFallbackWhenAISuggestionExists [

	| builder context entries |
	builder := CopilotTestableBuilder new.
	context := CoCopilotContextMock new.

	entries := builder
		completionEntriesFrom: { 'aiCompletion' }
		inContext: context
		contextInfo: Dictionary new.

	self assert: entries size equals: 2.
	self assert: entries first contents equals: 'aiCompletion'.
	self assert: entries second contents equals: 'fallbackCompletion'.
	self assert: builder fallbackCallCount equals: 1
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCompletionEntriesSuppressInvalidSemanticSelectorBehindFallback [

	| builder context contextInfo entries |
	builder := CopilotTestableBuilder new.
	context := CoCopilotContextMock new
		behavior: Object;
		source: 'self as';
		position: 'self as' size;
		yourself.
	contextInfo := Dictionary new
		at: #prefix put: 'self as';
		yourself.

	entries := builder
		completionEntriesFrom: { 'DefinitelyNotASelector' }
		inContext: context
		contextInfo: contextInfo.

	self assert: builder fallbackCallCount equals: 1.
	self assert: entries size equals: 1.
	self assert: entries first contents equals: 'fallbackCompletion'.
	self assert: ((contextInfo at: #semanticGate) at: #status) equals: #low
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCompletionEntriesDoNotFetchFallbackWhenSemanticSelectorIsValid [

	| builder context contextInfo entries |
	builder := CopilotTestableBuilder new.
	context := CoCopilotContextMock new
		behavior: Object;
		source: 'self as';
		position: 'self as' size;
		yourself.
	contextInfo := Dictionary new
		at: #prefix put: 'self as';
		yourself.

	entries := builder
		completionEntriesFrom: { 'String' }
		inContext: context
		contextInfo: contextInfo.

	self assert: builder fallbackCallCount equals: 0.
	self assert: entries size equals: 1.
	self assert: entries first contents equals: 'String'.
	self assert: ((contextInfo at: #semanticGate) at: #status) equals: #high
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
CoPharoCopilotResultSetBuilderTest >> testFuseModelTailMatchingSemanticSelectorKeepsModelFirst [

	| builder context contextInfo result gate |
	builder := CoPharoCopilotResultSetBuilder new.
	context := CoCopilotContextMock new
		behavior: Object;
		source: 'self as';
		position: 'self as' size;
		yourself.
	contextInfo := Dictionary new
		at: #prefix put: 'self as';
		yourself.

	result := builder
		fuseModelSuggestions: { 'String' }
		semanticEntries: {
			CoCopilotEntry contents: 'asString'.
			CoCopilotEntry contents: 'asArray' }
		context: context
		contextInfo: contextInfo.

	self assert: result equals: { 'String'. 'asArray' }.
	self assert: (contextInfo at: #semanticFusionApplied).
	gate := contextInfo at: #semanticGate.
	self assert: (gate at: #status) equals: #high.
	self assert: (gate at: #heuristicTop) equals: 'asString'
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testFuseInvalidModelSuggestionFallsBehindSemanticCandidates [

	| builder context contextInfo result gate |
	builder := CoPharoCopilotResultSetBuilder new.
	context := CoCopilotContextMock new
		behavior: Object;
		source: 'self as';
		position: 'self as' size;
		yourself.
	contextInfo := Dictionary new
		at: #prefix put: 'self as';
		yourself.

	result := builder
		fuseModelSuggestions: { 'DefinitelyNotASelector' }
		semanticEntries: {
			CoCopilotEntry contents: 'asString'.
			CoCopilotEntry contents: 'asArray' }
		context: context
		contextInfo: contextInfo.

	self assert: result equals: { 'asString'. 'asArray'. 'DefinitelyNotASelector' }.
	self assert: (contextInfo at: #semanticFusionApplied).
	gate := contextInfo at: #semanticGate.
	self assert: (gate at: #status) equals: #semanticFirst
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCompletionLoggingRecordsLogprobsMetadata [

	CopilotSettings withDefaultSettingsDo: [
		| builder client mock logprobs contextInfo suggestions attempts attempt request response payload generated |
		CopilotSettings recordResearchTelemetryConsentAccepted: true.
		CopilotSettings loggingEnabled: true.
		CopilotSettings completionLogprobsEnabled: true.
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
		self assert: (attempt at: #averageLogprob) equals: -0.05.
		self deny: (attempt at: #lowConfidence).

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
CoPharoCopilotResultSetBuilderTest >> testCompletionContextInfoRecordsEditorEnvironment [

	CopilotSettings withDefaultSettingsDo: [
		| builder context editor morph window contextInfo environment |
		CopilotSettings recordResearchTelemetryConsentAccepted: true.
		CopilotSettings loggingEnabled: true.
		builder := CoPharoCopilotResultSetBuilder new.
		window := CoPCEnvironmentWindowMock new
			label: 'Debugger on Example>>#broken';
			yourself.
		morph := CoPCEnvironmentMorphMock new
			window: window;
			yourself.
		editor := CoTestEditorMock new
			morph: morph;
			yourself.
		context := CoCopilotContextMock new
			isScripting: true;
			source: 'Ord';
			position: 3;
			editor: editor;
			yourself.

		contextInfo := builder contextInfoFor: context prefix: 'Ord' suffix: ''.
		environment := contextInfo at: #completionEnvironment.

		self assert: (environment at: #kind) equals: #debugger.
		self assert: (environment at: #isScripting).
		self assert: (environment at: #editorClass) equals: 'CoTestEditorMock'.
		self assert: (environment at: #morphClass) equals: 'CoPCEnvironmentMorphMock'.
		self assert: (environment at: #windowClass) equals: 'CoPCEnvironmentWindowMock'.
		self assert: (environment at: #windowTitle) equals: 'Debugger on Example>>#broken' ]
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCompletionContextInfoTreatsTestFailureWindowAsDebugger [

	CopilotSettings withDefaultSettingsDo: [
		| builder context editor morph window contextInfo environment |
		CopilotSettings recordResearchTelemetryConsentAccepted: true.
		CopilotSettings loggingEnabled: true.
		builder := CoPharoCopilotResultSetBuilder new.
		window := CoPCEnvironmentWindowMock new
			label: 'TestFailure: Given Collections do not match!';
			yourself.
		morph := CoPCEnvironmentMorphMock new
			window: window;
			yourself.
		editor := CoTestEditorMock new
			morph: morph;
			yourself.
		context := CoCopilotContextMock new
			source: 'self assertCollection: shortestPath';
			position: 35;
			editor: editor;
			yourself.

		contextInfo := builder contextInfoFor: context prefix: 'self assertCollection: shortestPath' suffix: ''.
		environment := contextInfo at: #completionEnvironment.

		self assert: (environment at: #kind) equals: #debugger ]
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCompletionContextInfoRecordsInspectorEnvironmentFromEngineRequestor [

	CopilotSettings withDefaultSettingsDo: [
		| builder context requestor engine contextInfo environment |
		CopilotSettings recordResearchTelemetryConsentAccepted: true.
		CopilotSettings loggingEnabled: true.
		builder := CoPharoCopilotResultSetBuilder new.
		requestor := CoPCInspectorRequestorDouble new.
		engine := CoSpyCompletionEnginePharoCopilot new
			doItRequestor: requestor;
			yourself.
		context := CoCopilotContextMock new
			engine: engine;
			source: 'self ';
			position: 'self ' size;
			yourself.

		contextInfo := builder contextInfoFor: context prefix: 'self ' suffix: ''.
		environment := contextInfo at: #completionEnvironment.

		self assert: (environment at: #kind) equals: #inspector.
		self assert: (environment at: #requestorClass) equals: 'CoPCInspectorRequestorDouble' ]
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCompletionPayloadIncludesEnvironment [

	| contextInfo environment payload |
	environment := Dictionary new
		at: #kind put: #playground;
		at: #windowTitle put: 'Playground';
		yourself.
	contextInfo := Dictionary new
		at: #timestamp put: '2026-08-13T12:00:00+02:00';
		at: #completionEnvironment put: environment;
		yourself.

	payload := CoPharoCopilotLogger
		initialCompletionPayloadForContextInfo: contextInfo
		prefix: 'Object new'
		suffix: ''
		classContext: ''
		cacheStats: Dictionary new.

	self assert: (payload at: #completionEnvironment) equals: environment
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testSemanticContextUsesEngineDoItRequestorBinding [

	| builder context requestor engine source semantic |
	builder := CoPharoCopilotResultSetBuilder new.
	requestor := CoPCInspectorRequestorDouble new.
	requestor bind: 'self' to: OrderedCollection new.
	engine := CoSpyCompletionEnginePharoCopilot new
		doItRequestor: requestor;
		yourself.
	source := 'self add'.
	context := CoCopilotContextMock new
		engine: engine;
		source: source;
		position: source size;
		yourself.

	semantic := builder semanticCompletionContextFor: context prefix: source.

	self assert: (semantic includesSubstring: 'Current receiver: self').
	self assert: (semantic includesSubstring: 'Receiver type: OrderedCollection').
	self assert: (semantic includesSubstring: 'self -> OrderedCollection')
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testCompletionLoggingRejectsLowConfidenceLogprobSuggestion [

	CopilotSettings withDefaultSettingsDo: [
		| builder client mock logprobs contextInfo suggestions attempts attempt |
		CopilotSettings recordResearchTelemetryConsentAccepted: true.
		CopilotSettings loggingEnabled: true.
		CopilotSettings completionLogprobsEnabled: true.
		builder := CoPharoCopilotResultSetBuilder new.
		mock := OAHttpTransportMockExtended new.
		logprobs := {
			Dictionary new
				at: #token put: 'assert';
				at: #logprob put: -5.0;
				yourself.
			Dictionary new
				at: #token put: ':';
				at: #logprob put: -4.0;
				yourself }.
		mock mockResponse: (Dictionary new
			at: #response put: 'assert: false';
			at: #logprobs put: logprobs;
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

		self assert: suggestions isEmpty.
		attempts := contextInfo at: #generationAttempts.
		self assert: attempts size equals: 1.
		attempt := attempts first.
		self assert: (attempt at: #suggestion) equals: ''.
		self assert: (attempt at: #averageLogprob) equals: -4.5.
		self assert: (attempt at: #lowConfidence) ]
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
CoPharoCopilotResultSetBuilderTest >> testSemanticSelectorFastPathRequiresTwoCharacterToken [

	| builder oneCharacter twoCharacters |
	builder := CoPharoCopilotResultSetBuilder new.
	oneCharacter := CoCopilotContextMock new
		behavior: Object;
		source: 'self a';
		position: 'self a' size;
		yourself.
	twoCharacters := CoCopilotContextMock new
		behavior: Object;
		source: 'self as';
		position: 'self as' size;
		yourself.

	self deny: (builder shouldOpenSemanticSelectorFastPathFor: oneCharacter prefix: oneCharacter source).
	self assert: (builder shouldOpenSemanticSelectorFastPathFor: twoCharacters prefix: twoCharacters source)
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
CoPharoCopilotResultSetBuilderTest >> testRecentCodeChangesFormatsMethodAndClassChanges [

	| provider methodChange classChange result |
	provider := CoPCTestRecentCodeChanges new.
	methodChange := CoPCTestEpMethodChange
		behavior: 'CoFoo'
		selector: #bar
		package: 'AI-Pharo-Copilot'.
	classChange := CoPCTestEpClassChange
		affectedName: 'CoSomething'
		package: 'AI-Pharo-Copilot'.
	provider recentChanges: { methodChange. classChange }.

	result := provider gather.

	self assert: (result includesSubstring: 'CoPCTestEpMethodChange: CoFoo>>bar [AI-Pharo-Copilot]').
	self assert: (result includesSubstring: 'CoPCTestEpClassChange: CoSomething [AI-Pharo-Copilot]').
	self deny: (result includesSubstring: '<|file_sep|>Recent code changes')
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
CoPharoCopilotResultSetBuilderTest >> testSemanticReceiverInfoIsCachedForSameSnapshot [

	| builder context source |
	builder := CopilotTestableBuilder new.
	source := 'semanticContextExample', String lf, String tab, 'self as'.
	context := CoCopilotContextMock new
		behavior: Object;
		source: source;
		position: source size;
		yourself.

	builder semanticReceiverInfoFor: context prefix: source.
	builder semanticReceiverInfoFor: context prefix: source.

	self assert: builder semanticAstCallCount equals: 1
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
CoPharoCopilotResultSetBuilderTest >> testNormalizeSuggestionRejectsProseAnswer [

	| builder raw |
	builder := CoPharoCopilotResultSetBuilder new.
	raw := 'Here is the code:', String lf, 'self assert: true'.

	self assert: (builder normalizeSuggestion: raw forPrefix: 'self ') equals: ''
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testNormalizedCompletionContentsRejectMethodHeaderForMessageTail [

	| builder context contextInfo contents |
	builder := CoPharoCopilotResultSetBuilder new.
	context := CoCopilotContextMock new
		behavior: Object;
		source: 'self as';
		position: 'self as' size;
		yourself.
	contextInfo := Dictionary new
		at: #prefix put: 'self as';
		yourself.

	contents := builder
		normalizedCompletionContentsFrom: { 'Object >> foo', String lf, '^ 1' }
		inContext: context
		contextInfo: contextInfo.

	self assert: contents isEmpty
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testReceiverCompletionDoesNotUseStandaloneFallback [

	| builder context |
	builder := CopilotTestableBuilder new.
	context := CoCopilotContextMock new
		isScripting: true;
		source: 'OrderedCollection ne';
		position: 'OrderedCollection ne' size;
		yourself.

	self deny: (builder
		shouldUseFallbackCompletionForContext: context
		prefix: 'OrderedCollection ne')
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testSelfReceiverStillUsesCopilot [

	| builder context |
	builder := CopilotTestableBuilder new.
	context := CoCopilotContextMock new
		isScripting: true;
		source: 'self pri';
		position: 'self pri' size;
		yourself.

	self deny: (builder
		shouldUseFallbackCompletionForContext: context
		prefix: 'self pri')
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testStandaloneTokenOutsideScriptingContextDoesNotUseFallback [

	| builder context |
	builder := CopilotTestableBuilder new.
	context := CoCopilotContextMock new
		source: 'Ord';
		position: 3;
		yourself.

	self deny: (builder
		shouldUseFallbackCompletionForContext: context
		prefix: 'Ord')
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testStandaloneTokenAfterAssignmentUsesFallbackCompletion [

	| builder context source |
	builder := CopilotTestableBuilder new.
	source := 'items := Ord'.
	context := CoCopilotContextMock new
		isScripting: true;
		source: source;
		position: source size;
		yourself.

	self assert: (builder
		shouldUseFallbackCompletionForContext: context
		prefix: source)
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testStandaloneTokenAfterKeywordArgumentUsesFallbackCompletion [

	| builder context source |
	builder := CopilotTestableBuilder new.
	source := 'Dictionary new at: Ord'.
	context := CoCopilotContextMock new
		isScripting: true;
		source: source;
		position: source size;
		yourself.

	self assert: (builder
		shouldUseFallbackCompletionForContext: context
		prefix: source)
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testStandaloneTokenAfterStatementSeparatorUsesFallbackCompletion [

	| builder context source |
	builder := CopilotTestableBuilder new.
	source := 'Transcript cr.', String lf, 'Ord'.
	context := CoCopilotContextMock new
		isScripting: true;
		source: source;
		position: source size;
		yourself.

	self assert: (builder
		shouldUseFallbackCompletionForContext: context
		prefix: source)
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testStandaloneTokenUsesFallbackCompletion [

	| builder context |
	builder := CopilotTestableBuilder new.
	context := CoCopilotContextMock new
		isScripting: true;
		source: 'Ord';
		position: 3;
		yourself.

	self assert: (builder
		shouldUseFallbackCompletionForContext: context
		prefix: 'Ord')
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
CoPharoCopilotResultSetBuilderTest >> testShouldNotTriggerInsideStringOrComment [

	| b ctx source |
	b := CoPharoCopilotResultSetBuilder new.
	ctx := CoCopilotContextMock new.

	source := (String with: (Character value: 39)) , 'hello wor'.
	ctx
		source: source;
		position: source size.
	self deny: (b shouldRequestCompletionForContext: ctx).

	source := (String with: (Character value: 34)) , 'comment text'.
	ctx
		source: source;
		position: source size.
	self deny: (b shouldRequestCompletionForContext: ctx)
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderTest >> testShouldTriggerShortTokenAfterLongPrefix [

	| b ctx source |
	b := CoPharoCopilotResultSetBuilder new.
	source := 'Transcript cr.', String lf, 'Or'.
	ctx := CoCopilotContextMock new
		source: source;
		position: source size;
		yourself.

	self assert: (b shouldRequestCompletionForContext: ctx)
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
