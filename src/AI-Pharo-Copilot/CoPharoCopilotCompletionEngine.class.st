"
I retrieve code completion suggestions from the Pharo Copilot service
and apply accepted suggestions into the active code editor.
"
Class {
	#name : 'CoPharoCopilotCompletionEngine',
	#superclass : 'CoCompletionEngine',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'accessing' }
CoPharoCopilotCompletionEngine >> completionBuilder [

	^ completionBuilder ifNil: [ completionBuilder := CoPharoCopilotResultSetBuilder new ]
]

{ #category : 'new' }
CoPharoCopilotCompletionEngine >> replaceTokenInEditorWith: newString [

	| caretPosition |
	(newString isNil or: [ newString isEmpty ]) ifTrue: [ ^ self ].

	caretPosition := self editor caret.
	super replaceTokenInEditorWith: newString.
	self editor selectAt: caretPosition
]
