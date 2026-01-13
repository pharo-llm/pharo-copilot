"
I retrieve code completion suggestions from the Pharo Copilot service and apply accepted suggestions into the active code editor.

"
Class {
	#name : 'CoCompletionEnginePharoCopilot',
	#superclass : 'CoCompletionEngine',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'accessing' }
CoCompletionEnginePharoCopilot >> basicReplaceTokenInEditorWith: newString [
	"Perform the actual token replacement by delegating to the superclass implementation."

	super replaceTokenInEditorWith: newString
]

{ #category : 'accessing' }
CoCompletionEnginePharoCopilot >> completionBuilder [
	"Answer the result-set builder used to materialize Copilot suggestions (lazily initialized), and log that it was requested."

	| alreadyInitialized builderClassName |
	alreadyInitialized := completionBuilder notNil.
	builderClassName := alreadyInitialized
		ifTrue: [ completionBuilder class name ]
		ifFalse: [ 'none' ].

	CoCopilotLogger
		logFrontEndEvent: 'Requesting completion builder'
		details: (Dictionary new
			at: #engineClass put: self class name;
			at: #builderAlreadyInitialized put: alreadyInitialized;
			at: #builderClass put: builderClassName;
			yourself).

	^ completionBuilder ifNil: [ completionBuilder := CoPharoCopilotResultSetBuilder new ]

]

{ #category : 'replacement' }
CoCompletionEnginePharoCopilot >> replaceTokenInEditorWith: newString [
	"Replace the current token with the given string and keep the caret where it was before the replacement."

	| originalCaretPosition |
	(newString isNil or: [ newString isEmpty ]) ifTrue: [ ^ self ].

	originalCaretPosition := self editor caret.
	self basicReplaceTokenInEditorWith: newString.
	self editor selectAt: originalCaretPosition
]
