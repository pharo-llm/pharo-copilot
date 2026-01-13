"
CoCopilotEntry models one completion suggestion produced by Pharo Copilot.
It stores the suggested text, can apply it to a completion context, and provides a short preview for UI display.
"
Class {
	#name : 'CoCopilotEntry',
	#superclass : 'Object',
	#instVars : [
		'text'
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
CoCopilotEntry >> activateOn: aCoCompletionContext [
	"Apply this suggestion by replacing the current token in the editor."

	aCoCompletionContext replaceTokenInEditorWith: self contents
]

{ #category : 'accessing' }
CoCopilotEntry >> contents [
	"Answer the full suggestion text stored by this entry."

	^ text
]

{ #category : 'displaying' }
CoCopilotEntry >> displayString [
	"Answer a UI-friendly preview (truncated to 120 characters when needed)."

	^ (self contents size > 120)
		ifTrue: [ (self contents copyFrom: 1 to: 117), '…' ]
		ifFalse: [ self contents ]
]

{ #category : 'displaying' }
CoCopilotEntry >> text: aString [
	"Set the suggestion text stored by this entry."

	text := aString
]
