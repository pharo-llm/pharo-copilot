Class {
	#name : 'CoPharoCopilotResultSetBuilderTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

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
CoPharoCopilotResultSetBuilderTest >> testInitializeOnContextSetsCompletionContext [
	| builder context |
	context := CoPharoCopilotContext new.
	builder := CoPharoCopilotResultSetBuilder initializeOnContext: context.
	
	self assert: builder completionContext identicalTo: context
]
