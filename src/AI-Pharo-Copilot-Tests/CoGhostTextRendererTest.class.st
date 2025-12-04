Class {
	#name : 'CoGhostTextRendererTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoGhostTextRendererTest >> testRendersAgainstEditor [

        | context renderer | 
        context := CoGhostTextContextMock new.
        context source: 'hello'.
        context position: context source size.
        renderer := context ghostRenderer.

        renderer renderSuggestion: 'world'.

        self assert: context editor lastGhostText equals: 'world'.
        self assert: context editor lastPosition equals: context position
]

{ #category : 'tests' }
CoGhostTextRendererTest >> testSupportsPartialAcceptance [

        | context renderer | 
        context := CoGhostTextContextMock new.
        renderer := context ghostRenderer.

        renderer renderSuggestion: 'line1', String lf, 'line2'.
        renderer acceptGhostTextFirstLine.
        self assert: context replacement equals: 'line1'.

        renderer renderSuggestion: 'one two three'.
        renderer acceptGhostTextFirstWord.
        self assert: context replacement equals: 'one'.
        self assert: context editor cleared
]
