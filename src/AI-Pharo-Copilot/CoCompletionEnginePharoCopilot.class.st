"
I retrieve code completion suggestions from the Pharo Copilot service and apply accepted suggestions into the active code editor.

"
Class {
	#name : 'CoCompletionEnginePharoCopilot',
	#superclass : 'CoCompletionEngine',
	#category : 'AI-Pharo-Copilot-Core',
	#package : 'AI-Pharo-Copilot',
	#tag : 'Core'
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

	| originalCaretPosition |
	(newString isNil or: [ newString isEmpty ]) ifTrue: [ ^ self ].

	originalCaretPosition := self editor caret.
	self basicReplaceTokenInEditorWith: newString.
	self editor selectAt: originalCaretPosition
]
