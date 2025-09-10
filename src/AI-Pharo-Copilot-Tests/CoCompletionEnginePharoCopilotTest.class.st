Class {
	#name : 'CoCompletionEnginePharoCopilotTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
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
CoCompletionEnginePharoCopilotTest >> testCleanedContentFromUsesCodeBlock [
    | builder raw cleaned |
    builder := CoPharoCopilotResultSetBuilder new.
    raw := 'aaa```code', String lf, 'line```bbb'.
    cleaned := builder cleanedContentFrom: raw.
    self assert: cleaned equals: 'code', String lf, 'line'.
]

{ #category : 'tests' }
CoCompletionEnginePharoCopilotTest >> testCompletionBuilderHasNilContext [

    | engine builder |
    engine := CoCompletionEnginePharoCopilot new.
    builder := engine completionBuilder.
    self assert: builder completionContext isNil.
]

{ #category : 'tests' }
CoCompletionEnginePharoCopilotTest >> testCompletionBuilderIsCoPharoCopilotResultSetBuilder [

    | engine builder |
    engine := CoCompletionEnginePharoCopilot new.
    builder := engine completionBuilder.
    self assert: builder class equals: CoPharoCopilotResultSetBuilder.
]

{ #category : 'tests' }
CoCompletionEnginePharoCopilotTest >> testCompletionBuilderMemoization [

	| engine firstBuilder secondBuilder |
	engine := CoCompletionEnginePharoCopilot new.
	firstBuilder := engine completionBuilder.
	secondBuilder := engine completionBuilder.
	self assert: firstBuilder identicalTo: secondBuilder
]

{ #category : 'tests' }
CoCompletionEnginePharoCopilotTest >> testDifferentEnginesHaveDifferentBuilders [

    | engine1 engine2 builder1 builder2 |
    engine1 := CoCompletionEnginePharoCopilot new.
    engine2 := CoCompletionEnginePharoCopilot new.
    builder1 := engine1 completionBuilder.
    builder2 := engine2 completionBuilder.
    self deny: builder1 identicalTo: builder2.
]
