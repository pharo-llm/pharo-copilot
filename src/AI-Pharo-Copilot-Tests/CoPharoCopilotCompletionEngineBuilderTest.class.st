Class {
	#name : 'CoPharoCopilotCompletionEngineBuilderTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> test10DistinctEnginesHave10DistinctBuilders [
	| engines builders |
	engines := (1 to: 10) collect: [ :ignored | CoPharoCopilotCompletionEngine new ].
	builders := engines collect: [ :e | e completionBuilder ].
	self assert: (builders asSet size) equals: 10
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> test11DistinctEnginesHave11DistinctBuilders [
	| engines builders |
	engines := (1 to: 11) collect: [ :ignored | CoPharoCopilotCompletionEngine new ].
	builders := engines collect: [ :e | e completionBuilder ].
	self assert: (builders asSet size) equals: 11
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> test12DistinctEnginesHave12DistinctBuilders [
	| engines builders |
	engines := (1 to: 12) collect: [ :ignored | CoPharoCopilotCompletionEngine new ].
	builders := engines collect: [ :e | e completionBuilder ].
	self assert: (builders asSet size) equals: 12
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> test13DistinctEnginesHave13DistinctBuilders [
	| engines builders |
	engines := (1 to: 13) collect: [ :ignored | CoPharoCopilotCompletionEngine new ].
	builders := engines collect: [ :e | e completionBuilder ].
	self assert: (builders asSet size) equals: 13
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> test14DistinctEnginesHave14DistinctBuilders [
	| engines builders |
	engines := (1 to: 14) collect: [ :ignored | CoPharoCopilotCompletionEngine new ].
	builders := engines collect: [ :e | e completionBuilder ].
	self assert: (builders asSet size) equals: 14
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> test15DistinctEnginesHave15DistinctBuilders [
	| engines builders |
	engines := (1 to: 15) collect: [ :ignored | CoPharoCopilotCompletionEngine new ].
	builders := engines collect: [ :e | e completionBuilder ].
	self assert: (builders asSet size) equals: 15
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> test3DistinctEnginesHave3DistinctBuilders [
	| engines builders |
	engines := (1 to: 3) collect: [ :ignored | CoPharoCopilotCompletionEngine new ].
	builders := engines collect: [ :e | e completionBuilder ].
	self assert: (builders asSet size) equals: 3
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> test4DistinctEnginesHave4DistinctBuilders [
	| engines builders |
	engines := (1 to: 4) collect: [ :ignored | CoPharoCopilotCompletionEngine new ].
	builders := engines collect: [ :e | e completionBuilder ].
	self assert: (builders asSet size) equals: 4
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> test5DistinctEnginesHave5DistinctBuilders [
	| engines builders |
	engines := (1 to: 5) collect: [ :ignored | CoPharoCopilotCompletionEngine new ].
	builders := engines collect: [ :e | e completionBuilder ].
	self assert: (builders asSet size) equals: 5
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> test6DistinctEnginesHave6DistinctBuilders [
	| engines builders |
	engines := (1 to: 6) collect: [ :ignored | CoPharoCopilotCompletionEngine new ].
	builders := engines collect: [ :e | e completionBuilder ].
	self assert: (builders asSet size) equals: 6
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> test7DistinctEnginesHave7DistinctBuilders [
	| engines builders |
	engines := (1 to: 7) collect: [ :ignored | CoPharoCopilotCompletionEngine new ].
	builders := engines collect: [ :e | e completionBuilder ].
	self assert: (builders asSet size) equals: 7
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> test8DistinctEnginesHave8DistinctBuilders [
	| engines builders |
	engines := (1 to: 8) collect: [ :ignored | CoPharoCopilotCompletionEngine new ].
	builders := engines collect: [ :e | e completionBuilder ].
	self assert: (builders asSet size) equals: 8
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> test9DistinctEnginesHave9DistinctBuilders [
	| engines builders |
	engines := (1 to: 9) collect: [ :ignored | CoPharoCopilotCompletionEngine new ].
	builders := engines collect: [ :e | e completionBuilder ].
	self assert: (builders asSet size) equals: 9
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderClassIsResultSetBuilder [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: engine completionBuilder class equals: CoPharoCopilotResultSetBuilder
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderContextCanBeAssigned [
	| engine builder ctx |
	engine := CoPharoCopilotCompletionEngine new.
	builder := engine completionBuilder.
	ctx := CoCopilotContextMock new.
	builder completionContext: ctx.
	self assert: builder completionContext identicalTo: ctx
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderHasNilCompletionContext [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: engine completionBuilder completionContext isNil
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderIdenticalAcross10Calls [
	| engine first |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	10 timesRepeat: [ self assert: engine completionBuilder identicalTo: first ]
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderIdenticalAcross25Calls [
	| engine first |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	25 timesRepeat: [ self assert: engine completionBuilder identicalTo: first ]
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderIdenticalAcross2Calls [
	| engine first |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	2 timesRepeat: [ self assert: engine completionBuilder identicalTo: first ]
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderIdenticalAcross50Calls [
	| engine first |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	50 timesRepeat: [ self assert: engine completionBuilder identicalTo: first ]
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderIdenticalAcross5Calls [
	| engine first |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	5 timesRepeat: [ self assert: engine completionBuilder identicalTo: first ]
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderIdentityStableAfterContextAssignment [
	| engine builder ctx |
	engine := CoPharoCopilotCompletionEngine new.
	builder := engine completionBuilder.
	ctx := CoCopilotContextMock new.
	builder completionContext: ctx.
	self assert: engine completionBuilder identicalTo: builder
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderIsCreatedLazily [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: engine completionBuilder notNil
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderIsKindOfCoResultSetBuilder [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine completionBuilder isKindOf: CoResultSetBuilder)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderIsKindOfResultSetBuilder [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine completionBuilder isKindOf: CoPharoCopilotResultSetBuilder)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderIsNotNil [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: engine completionBuilder notNil
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall01 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	1 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall02 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	2 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall03 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	3 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall04 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	4 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall05 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	5 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall06 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	6 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall07 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	7 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall08 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	8 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall09 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	9 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall10 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	10 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall11 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	11 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall12 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	12 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall13 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	13 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall14 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	14 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall15 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	15 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall16 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	16 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall17 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	17 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall18 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	18 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall19 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	19 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderMemoizationCall20 [
	| engine first second |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	20 timesRepeat: [ second := engine completionBuilder ].
	self assert: first identicalTo: second
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderRespondsToBuildCompletion [
	| engine builder |
	engine := CoPharoCopilotCompletionEngine new.
	builder := engine completionBuilder.
	self assert: (builder respondsTo: #buildCompletion)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderRespondsToClassContextFor [
	| engine builder |
	engine := CoPharoCopilotCompletionEngine new.
	builder := engine completionBuilder.
	self assert: (builder respondsTo: #classContextFor:)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderRespondsToCleanedContentFrom [
	| engine builder |
	engine := CoPharoCopilotCompletionEngine new.
	builder := engine completionBuilder.
	self assert: (builder respondsTo: #cleanedContentFrom:)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderRespondsToCompletionCache [
	| engine builder |
	engine := CoPharoCopilotCompletionEngine new.
	builder := engine completionBuilder.
	self assert: (builder respondsTo: #completionCache)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderRespondsToCompletionContext [
	| engine builder |
	engine := CoPharoCopilotCompletionEngine new.
	builder := engine completionBuilder.
	self assert: (builder respondsTo: #completionContext)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderRespondsToCompletionContextSetter [
	| engine builder |
	engine := CoPharoCopilotCompletionEngine new.
	builder := engine completionBuilder.
	self assert: (builder respondsTo: #completionContext:)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderReturnsSameInstanceTenTimes [
	| engine first |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	10 timesRepeat: [ self assert: engine completionBuilder identicalTo: first ]
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderReturnsSameInstanceTwice [
	| engine a b |
	engine := CoPharoCopilotCompletionEngine new.
	a := engine completionBuilder.
	b := engine completionBuilder.
	self assert: a == b
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testBuilderSurvivesAcrossCalls [
	| engine first |
	engine := CoPharoCopilotCompletionEngine new.
	first := engine completionBuilder.
	self assert: engine completionBuilder class equals: first class
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testDifferentEnginesHaveDifferentBuilders [
	| e1 e2 |
	e1 := CoPharoCopilotCompletionEngine new.
	e2 := CoPharoCopilotCompletionEngine new.
	self deny: e1 completionBuilder identicalTo: e2 completionBuilder
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testFreshEngineBuilderHasNoCompletionContext [
	| engine builder |
	engine := CoPharoCopilotCompletionEngine new.
	builder := engine completionBuilder.
	self assert: builder completionContext isNil
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testSpyEngineBuilderClassIsResultSetBuilder [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	self assert: engine completionBuilder class equals: CoPharoCopilotResultSetBuilder
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testSpyEngineBuilderContextInitiallyNil [
	| engine |
	engine := CoSpyCompletionEnginePharoCopilot new.
	self assert: engine completionBuilder completionContext isNil
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineBuilderTest >> testSpyEngineBuilderMemoizes [
	| engine a b |
	engine := CoSpyCompletionEnginePharoCopilot new.
	a := engine completionBuilder.
	b := engine completionBuilder.
	self assert: a identicalTo: b
]
