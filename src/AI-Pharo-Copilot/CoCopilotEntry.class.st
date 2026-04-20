"
CoCopilotEntry models one completion suggestion produced by Pharo Copilot.
It stores the suggested text, can apply it to a completion context, and provides a short preview for UI display.
"
Class {
	#name : 'CoCopilotEntry',
	#superclass : 'Object',
	#instVars : [
		'text',
		'description',
		'label'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'accessing' }
CoCopilotEntry class >> contents: aString [
	"Create a new entry holding the given suggestion text."

	^ self new
		text: aString;
		yourself
]

{ #category : 'accessing' }
CoCopilotEntry class >> contents: aString description: aDescriptionString [

	^ self new
		text: aString;
		description: aDescriptionString;
		yourself
]

{ #category : 'actions' }
CoCopilotEntry >> activateOn: aCoCompletionContext [
	"Apply this suggestion by inserting it at the cursor position."

	| editor |
	aCoCompletionContext ifNil: [ Error signal: 'Completion context is nil' ].

	editor := (aCoCompletionContext respondsTo: #editor)
		ifTrue: [ aCoCompletionContext editor ]
		ifFalse: [ nil ].


	"Try to insert at caret (preserves user's text)"
	editor ifNotNil: [
		(editor respondsTo: #addString:) ifTrue: [
			^ editor addString: self contents
		].


		"Fallback: replace selection if empty"
		(editor respondsTo: #selectionInterval) ifTrue: [
			editor selectionInterval isEmpty ifTrue: [
				^ editor replaceSelectionWith: self contents
			]
		]
	].

	"Last resort: use context's replace method"
	(aCoCompletionContext respondsTo: #replaceTokenInEditorWith:) ifTrue: [
		^ aCoCompletionContext replaceTokenInEditorWith: self contents
	]
]

{ #category : 'accessing' }
CoCopilotEntry >> contents [
	"Answer the full suggestion text stored by this entry."

	^ text
]

{ #category : 'accessing' }
CoCopilotEntry >> defaultLabel [

	| firstLine |
	firstLine := self contents lines
		ifEmpty: [ '' ]
		ifNotEmpty: [ :lines | lines first ].

	^ firstLine size > 80
		ifTrue: [ (firstLine copyFrom: 1 to: 77), '…' ]
		ifFalse: [ firstLine ]
]

{ #category : 'accessing' }
CoCopilotEntry >> description [

	^ description ifNil: [ self contents ]
]

{ #category : 'accessing' }
CoCopilotEntry >> description: aString [

	description := aString
]

{ #category : 'accessing' }
CoCopilotEntry >> displayString [

	^ self label
]

{ #category : 'accessing' }
CoCopilotEntry >> label [

	^ label ifNil: [ self defaultLabel ]
]

{ #category : 'accessing' }
CoCopilotEntry >> label: aString [

	label := aString
]

{ #category : 'displaying' }
CoCopilotEntry >> text: aString [
	"Set the suggestion text stored by this entry."

	text := aString
]
