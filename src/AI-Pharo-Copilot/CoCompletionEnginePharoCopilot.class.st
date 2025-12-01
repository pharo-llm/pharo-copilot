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
        builderClass := completionBuilder
                ifNil: [ 'none' ]
                ifNotNil: [ :builder | builder class name ].
        CoCopilotLogger
                logFrontEndEvent: 'Requesting completion builder'
                details: (Dictionary new
                        at: #engineClass put: self class name;
                        at: #builderAlreadyInitialized put: completionBuilder notNil;
                        at: #builderClass put: builderClass;
                        yourself).
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
