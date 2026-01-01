"
Completion engine that retrieves suggestions from the Pharo Copilot service.

"
Class {
	#name : 'CoCompletionEnginePharoCopilot',
	#superclass : 'CoCompletionEngine',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'replacement' }
CoCompletionEnginePharoCopilot >> basicReplaceTokenInEditorWith: newString [

    super replaceTokenInEditorWith: newString.
]

{ #category : 'accessing' }
CoCompletionEnginePharoCopilot >> completionBuilder [

	| builderClass |
	builderClass := completionBuilder ifNil: [ 'none' ] ifNotNil: [ :builder | builder class name ].
	^ completionBuilder ifNil: [ completionBuilder := CoPharoCopilotResultSetBuilder new ]
]

{ #category : 'replacement' }
CoCompletionEnginePharoCopilot >> replaceTokenInEditorWith: newString [

	| originalCaretPosition |
	    newString ifNil: [ ^ self ].
    newString isEmpty ifTrue: [ ^ self ].
	originalCaretPosition := self editor caret.
	self basicReplaceTokenInEditorWith: newString.
	self editor selectAt: originalCaretPosition
]
