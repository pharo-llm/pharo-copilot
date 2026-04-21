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

	super replaceTokenInEditorWith: newString
]

{ #category : 'accessing' }
CoCompletionEnginePharoCopilot >> completionBuilder [

	| alreadyInitialized builderClassName |
	alreadyInitialized := completionBuilder notNil.
	builderClassName := alreadyInitialized
		ifTrue: [ completionBuilder class name ]
		ifFalse: [ 'none' ].

	^ completionBuilder ifNil: [ completionBuilder := CoPharoCopilotResultSetBuilder new ]

]

{ #category : 'replacement' }
CoCompletionEnginePharoCopilot >> replaceTokenInEditorWith: newString [

	| originalCaretPosition |
	(newString isNil or: [ newString isEmpty ]) ifTrue: [ ^ self ].

	originalCaretPosition := self editor caret.
	self basicReplaceTokenInEditorWith: newString.
	self editor selectAt: originalCaretPosition
]
