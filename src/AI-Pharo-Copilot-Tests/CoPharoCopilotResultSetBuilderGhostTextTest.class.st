Class {
	#name : 'CoPharoCopilotResultSetBuilderGhostTextTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderGhostTextTest >> testApplyContentUsesGhostRendererWhenContextMatches [

        | builder context | 
        builder := CoPharoCopilotResultSetBuilder new.
        context := CoGhostTextContextMock new.
        context source: 'abc'.
        context position: context source size.

        builder
                applyContent: 'suggested'
                toContext: context
                expectedPrefix: 'abc'
                suffix: ''
                contextInfo: Dictionary new.

        self assert: context editor lastGhostText equals: 'suggested'.
        self assert: context replacement isNil
]
