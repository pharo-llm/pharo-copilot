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
CoPharoCopilotCompletionEngine >> openCopilotMenuFor: aContext entries: entryCollection position: aPoint builder: aBuilder [

	| editorMorph menuClass |

	self closeMenu.

	context := aContext.
	menuClass := Smalltalk globals at: #CopilotMenuMorph ifAbsent: [ nil ].
	menuMorph := menuClass ifNotNil: [
		menuClass
			builder: aBuilder
			context: aContext
			entries: entryCollection
			position: aPoint ].

	editorMorph := [ self editor morph ] on: Error do: [ nil ].
	editorMorph ifNotNil: [
		editorMorph takeKeyboardFocus.
		editorMorph invalidRect: editorMorph bounds.
		editorMorph changed ].

	^ menuMorph
]

{ #category : 'replacement' }
CoPharoCopilotCompletionEngine >> replaceTokenInEditorWith: newString [

	(self shouldIgnoreReplacement: newString) ifTrue: [ ^ self ].

	self basicReplaceTokenInEditorWith: newString
]

{ #category : 'replacement' }
CoPharoCopilotCompletionEngine >> shouldIgnoreReplacement: newString [

	^ newString isNil or: [ newString isEmpty ]
]
