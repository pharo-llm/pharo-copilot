"
I retrieve code completion suggestions from the Pharo Copilot service and apply accepted suggestions into the active code editor.

"
Class {
	#name : 'CoPharoCopilotCompletionEngine',
	#superclass : 'CoCompletionEngine',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'accessing' }
CoPharoCopilotCompletionEngine >> basicReplaceTokenInEditorWith: newString [

	super replaceTokenInEditorWith: newString
]

{ #category : 'accessing' }
CoPharoCopilotCompletionEngine >> completionBuilder [

	| alreadyInitialized builderClassName |
	alreadyInitialized := completionBuilder notNil.
	builderClassName := alreadyInitialized
		ifTrue: [ completionBuilder class name ]
		ifFalse: [ 'none' ].

	^ completionBuilder ifNil: [ completionBuilder := CoPharoCopilotResultSetBuilder new ]

]

{ #category : 'replacement' }
CoPharoCopilotCompletionEngine >> tokenStartPosition [
	"Answer the position at which the token being completed starts in the editor.
	The token ends at the current caret, so its start is the caret minus the token size."

	| caretPosition tokenSize |
	caretPosition := self editor caret.
	tokenSize := [
		| token |
		token := self completionToken.
		token ifNil: [ 0 ] ifNotNil: [ token size ] ]
			on: Error
			do: [ 0 ].
	^ caretPosition - tokenSize
]

{ #category : 'replacement' }
CoPharoCopilotCompletionEngine >> replaceTokenInEditorWith: newString [

	| tokenStartPosition |
	(self shouldIgnoreReplacement: newString) ifTrue: [ ^ self ].

	tokenStartPosition := self tokenStartPosition.
	self basicReplaceTokenInEditorWith: newString.
	self placeCaretAtEndOfSuggestion: newString from: tokenStartPosition
]

{ #category : 'replacement' }
CoPharoCopilotCompletionEngine >> placeCaretAtEndOfSuggestion: newString from: tokenStartPosition [
	"Move the editor caret to the position immediately after the inserted suggestion."

	| endPosition |
	endPosition := tokenStartPosition + (newString ifNil: [ 0 ] ifNotNil: [ newString size ]).
	self restoreCaretTo: endPosition
]

{ #category : 'new' }
CoPharoCopilotCompletionEngine >> restoreCaretTo: caretPosition [

	self editor selectAt: caretPosition
]

{ #category : 'replacement' }
CoPharoCopilotCompletionEngine >> shouldIgnoreReplacement: newString [

	^ newString isNil or: [ newString isEmpty ]
]
