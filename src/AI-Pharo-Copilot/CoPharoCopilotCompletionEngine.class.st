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

{ #category : 'new' }
CoPharoCopilotCompletionEngine >> replaceTokenInEditorWith: newString [

	| caretPosition |
	(self shouldIgnoreReplacement: newString) ifTrue: [ ^ self ].

	caretPosition := self editor caret.
	self basicReplaceTokenInEditorWith: newString.
	self restoreCaretTo: caretPosition
]

{ #category : 'new' }
CoPharoCopilotCompletionEngine >> restoreCaretTo: caretPosition [

	self editor selectAt: caretPosition
]

{ #category : 'new' }
CoPharoCopilotCompletionEngine >> shouldIgnoreReplacement: newString [

	^ newString isNil or: [ newString isEmpty ]
]
