Class {
	#name : 'CoCompletionEnginePharoCopilotTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoCompletionEnginePharoCopilotTest >> testCleanedContentFromRemovesExplanation [
    | builder raw cleaned |
    builder := CoPharoCopilotResultSetBuilder new.
    raw := 'line1', String lf, 'line2', String lf, String lf, 'Explanation'.
    cleaned := builder cleanedContentFrom: raw.
    self assert: cleaned equals: 'line1', String lf, 'line2'.
]

{ #category : 'tests' }
CoCompletionEnginePharoCopilotTest >> testCompletionBuilderHasNilContext [

    | engine builder |
    engine := CoPharoCopilotCompletionEngine new.
    builder := engine completionBuilder.
    self assert: builder completionContext isNil.
]

{ #category : 'tests' }
CoCompletionEnginePharoCopilotTest >> testCompletionBuilderIsCoPharoCopilotResultSetBuilder [

    | engine builder |
    engine := CoPharoCopilotCompletionEngine new.
    builder := engine completionBuilder.
    self assert: builder class equals: CoPharoCopilotResultSetBuilder.
]

{ #category : 'tests' }
CoCompletionEnginePharoCopilotTest >> testCompletionBuilderMemoization [

	| engine firstBuilder secondBuilder |
	engine := CoPharoCopilotCompletionEngine new.
	firstBuilder := engine completionBuilder.
	secondBuilder := engine completionBuilder.
	self assert: firstBuilder identicalTo: secondBuilder
]

{ #category : 'tests' }
CoCompletionEnginePharoCopilotTest >> testDifferentEnginesHaveDifferentBuilders [

    | engine1 engine2 builder1 builder2 |
    engine1 := CoPharoCopilotCompletionEngine new.
    engine2 := CoPharoCopilotCompletionEngine new.
    builder1 := engine1 completionBuilder.
    builder2 := engine2 completionBuilder.
    self deny: builder1 identicalTo: builder2.

]

{ #category : 'tests' }
CoCompletionEnginePharoCopilotTest >> testSpecConfigurationAccessorsAreStored [

	| engine requestor doItContext |
	engine := CoPharoCopilotCompletionEngine new.
	requestor := Object new.
	doItContext := Object new.

	engine
		scripting: true;
		completionClass: String;
		doItRequestor: requestor;
		doItContext: doItContext;
		smartCharacters: false.

	self assert: engine isScripting.
	self assert: engine completionClass equals: String.
	self assert: engine doItRequestor identicalTo: requestor.
	self assert: engine doItContext identicalTo: doItContext.
	self deny: engine smartCharacters
]

{ #category : 'tests' }
CoCompletionEnginePharoCopilotTest >> testStandaloneTokenKeepsFallbackWhenScriptingComesFromEngine [

	| engine context builder |
	engine := CoPharoCopilotCompletionEngine new
		scripting: true;
		yourself.
	context := CoEngineBackedContextMock new
		engine: engine;
		source: 'Ord';
		position: 3;
		yourself.
	builder := CoPharoCopilotResultSetBuilder new.

	self assert: (builder
		shouldUseFallbackCompletionForContext: context
		prefix: 'Ord')
]
