"
I retrieve code completion suggestions from the Pharo Copilot service and apply accepted suggestions into the active code editor.

"
Class {
	#name : 'CoPharoCopilotCompletionEngine',
	#superclass : 'CoCompletionEngine',
	#instVars : [
		'scripting',
		'completionClass',
		'doItContext',
		'doItRequestor',
		'smartCharacters'
	],
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

{ #category : 'accessing' }
CoPharoCopilotCompletionEngine >> completionClass [

	^ completionClass
]

{ #category : 'accessing' }
CoPharoCopilotCompletionEngine >> completionClass: anObject [

	completionClass := anObject
]

{ #category : 'menu morph' }
CoPharoCopilotCompletionEngine >> createContext [

	| completionContext |
	completionContext := super createContext.
	(completionClass notNil and: [
		completionContext respondsTo: #completionClass: ]) ifTrue: [
		completionContext completionClass: completionClass ].
	^ completionContext
]

{ #category : 'accessing' }
CoPharoCopilotCompletionEngine >> doItContext [

	doItContext ifNotNil: [ ^ doItContext ].
	^ [ super doItContext ] on: Error do: [ nil ]
]

{ #category : 'accessing' }
CoPharoCopilotCompletionEngine >> doItContext: aContext [

	doItContext := aContext
]

{ #category : 'accessing' }
CoPharoCopilotCompletionEngine >> doItRequestor [

	doItRequestor ifNotNil: [ ^ doItRequestor ].
	^ [ super doItRequestor ] on: Error do: [ nil ]
]

{ #category : 'accessing' }
CoPharoCopilotCompletionEngine >> doItRequestor: aRequestor [

	doItRequestor := aRequestor
]

{ #category : 'testing' }
CoPharoCopilotCompletionEngine >> isScripting [

	scripting ifNotNil: [ ^ scripting ].
	^ [ super isScripting ] on: Error do: [ false ]
]

{ #category : 'replacement' }
CoPharoCopilotCompletionEngine >> openCopilotMenuFor: aContext entries: entryCollection position: aPoint builder: aBuilder [

	| editorMorph |

	self closeMenu.

	context := aContext.
	menuMorph := CopilotMenuMorph
		builder: aBuilder
		context: aContext
		entries: entryCollection
		position: aPoint.

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

{ #category : 'accessing' }
CoPharoCopilotCompletionEngine >> scripting: aBoolean [

	scripting := aBoolean
]

{ #category : 'replacement' }
CoPharoCopilotCompletionEngine >> shouldIgnoreReplacement: newString [

	^ newString isNil or: [ newString isEmpty ]
]

{ #category : 'accessing' }
CoPharoCopilotCompletionEngine >> smartCharacters [

	smartCharacters ifNotNil: [ ^ smartCharacters ].
	^ super smartCharacters
]

{ #category : 'accessing' }
CoPharoCopilotCompletionEngine >> smartCharacters: aBoolean [

	smartCharacters := aBoolean
]

{ #category : 'accessing' }
CoPharoCopilotCompletionEngine >> variableBindingNames [

	| requestor |
	requestor := self doItRequestor.
	requestor ifNil: [ ^ [ super variableBindingNames ] on: Error do: [ #() ] ].
	(requestor respondsTo: #variableBindingNames) ifTrue: [
		^ [ requestor variableBindingNames ] on: Error do: [ #() ] ].
	^ [ super variableBindingNames ] on: Error do: [ #() ]
]
