"
I retrieve code-completion suggestions from the Pharo Copilot service and apply the selected
suggestion to an editor while keeping the caret position unchanged.
"
Class {
	#name : 'CoCompletionEnginePharoCopilot',
	#superclass : 'CoCompletionEngine',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'accessing' }
CoCompletionEnginePharoCopilot >> completionBuilder [
	| builderClassName |

	builderClassName := completionBuilder
		ifNil: [ 'none' ]
		ifNotNil: [ :builder | builder class name ].

	CoCopilotLogger
		logFrontEndEvent: 'Requesting completion builder'
		details: (Dictionary new
			at: #engineClass put: self class name;
			at: #builderAlreadyInitialized put: completionBuilder notNil;
			at: #builderClass put: builderClassName;
			yourself).

	^ completionBuilder ifNil: [ completionBuilder := CoPharoCopilotResultSetBuilder new ]

]

{ #category : 'replacement' }
CoCompletionEnginePharoCopilot >> replaceTokenInEditorWith: newString [
	| caretPosition |

	(newString isNil or: [ newString isEmpty ]) ifTrue: [ ^ self ].

	caretPosition := self editor caret.
	super replaceTokenInEditorWith: newString.
	self editor selectAt: caretPosition
]
