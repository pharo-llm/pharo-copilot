"
The renderer is intentionally defensive: if the host editor does not support the
ghost-text hooks we expect (for example, in tests), the renderer simply records
state and no-ops the UI calls.
"
Class {
	#name : 'CoGhostTextRenderer',
	#superclass : 'CoCompletionContext',
	#instVars : [
		'context',
		'currentGhostText'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'instance creation' }
CoGhostTextRenderer class >> onContext: aContext [

        ^ self new
                context: aContext;
                yourself
]

{ #category : 'visiting' }
CoGhostTextRenderer >> accept: acceptedText [

        acceptedText ifNil: [ ^ self clearGhostText ].
        acceptedText isEmpty ifTrue: [ ^ self clearGhostText ].
        context ifNil: [ ^ self clearGhostText ].

        context replaceTokenInEditorWith: acceptedText.
        self clearGhostText.
        CoCopilotLogger
                logFrontEndEvent: 'Ghost text accepted'
                details: (Dictionary new
                        at: #acceptedTextLength put: acceptedText size;
                        at: #acceptedTextPreview put: (acceptedText copyFrom: 1 to: (30 min: acceptedText size));
                        yourself)
]

{ #category : 'visiting' }
CoGhostTextRenderer >> acceptGhostText [

        self accept: currentGhostText
]

{ #category : 'visiting' }
CoGhostTextRenderer >> acceptGhostTextFirstLine [

        | newlineIndex |
currentGhostText ifNil: [ ^ self clearGhostText ].
        newlineIndex := currentGhostText indexOf: Character lf ifAbsent: [ 0 ].
        newlineIndex := newlineIndex = 0
                ifTrue: [ currentGhostText size ]
                ifFalse: [ newlineIndex - 1 ].
        self accept: (currentGhostText copyFrom: 1 to: newlineIndex)
]

{ #category : 'visiting' }
CoGhostTextRenderer >> acceptGhostTextFirstWord [

        | spaceIndex |
currentGhostText ifNil: [ ^ self clearGhostText ].
        spaceIndex := currentGhostText indexOf: Character space ifAbsent: [ 0 ].
        spaceIndex := spaceIndex = 0
                ifTrue: [ currentGhostText size ]
                ifFalse: [ spaceIndex - 1 ].
        self accept: (currentGhostText copyFrom: 1 to: spaceIndex)
]

{ #category : 'visiting' }
CoGhostTextRenderer >> attachGhostText: aString toEditor: anEditor [

        anEditor ifNil: [ ^ self ].
        (anEditor respondsTo: #showGhostSuggestion:at:color:)
                ifTrue: [ ^ anEditor
                                        showGhostSuggestion: aString
                                        at: (context ifNil: [ 0 ] ifNotNil: [ context position ])
                                        color: Color gray alpha: 0.35 ].

        (anEditor respondsTo: #showGhostText:) ifTrue: [ ^ anEditor showGhostText: aString ].
        (anEditor respondsTo: #ghostText:) ifTrue: [ ^ anEditor ghostText: aString ].
]

{ #category : 'visiting' }
CoGhostTextRenderer >> clearGhostText [

        | editor |
        editor := self editorIfAvailable.
        (editor respondsTo: #clearGhostSuggestion) ifTrue: [ editor clearGhostSuggestion ].
        (editor respondsTo: #clearGhostText) ifTrue: [ editor clearGhostText ].
        currentGhostText := nil.
]

{ #category : 'visiting' }
CoGhostTextRenderer >> context: aContext [

        context := aContext
]

{ #category : 'visiting' }
CoGhostTextRenderer >> editorIfAvailable [

        ^ (context respondsTo: #editor)
                ifTrue: [ [ context editor ] on: Error do: [ nil ] ]
                ifFalse: [ nil ]
]

{ #category : 'visiting' }
CoGhostTextRenderer >> renderSuggestion: aString [

        self clearGhostText.
        aString ifNil: [ ^ self ].
        aString isEmpty ifTrue: [ ^ self ].

        currentGhostText := aString.
        self attachGhostText: aString toEditor: self editorIfAvailable.

        CoCopilotLogger
                logFrontEndEvent: 'Rendered ghost text suggestion'
                details: (Dictionary new
                        at: #ghostLength put: aString size;
                        at: #ghostPreview put: (aString copyFrom: 1 to: (30 min: aString size));
                        yourself)
]
