"
One completion suggestion produced by Pharo Copilot.
Stores the raw text and applies it to a completion context on accept.
"
Class {
	#name : 'CoCopilotEntry',
	#superclass : 'Object',
	#instVars : [
		'text',
		'label'
	],
	#category : 'AI-Pharo-Copilot-Spec',
	#package : 'AI-Pharo-Copilot-Spec'
}

{ #category : 'instance creation' }
CoCopilotEntry class >> contents: aString [

	^ self new
		text: aString;
		yourself
]

{ #category : 'accessing' }
CoCopilotEntry >> contents [ ^ text ]

{ #category : 'accessing' }
CoCopilotEntry >> text: aString [ text := aString ]

{ #category : 'accessing' }
CoCopilotEntry >> label [

	^ label ifNil: [ self defaultLabel ]
]

{ #category : 'accessing' }
CoCopilotEntry >> label: aString [ label := aString ]

{ #category : 'accessing' }
CoCopilotEntry >> displayString [ ^ self label ]

{ #category : 'accessing' }
CoCopilotEntry >> defaultLabel [

	| firstLine |
	firstLine := self contents lines
		ifEmpty: [ '' ]
		ifNotEmpty: [ :lines | lines first ].
	^ firstLine size > 80
		ifTrue: [ (firstLine copyFrom: 1 to: 77) , '…' ]
		ifFalse: [ firstLine ]
]

{ #category : 'activation' }
CoCopilotEntry >> activateOn: aCoCompletionContext [
	"Insert the suggestion into the editor."

	| editor |
	aCoCompletionContext ifNil: [ ^ false ].

	(aCoCompletionContext respondsTo: #replaceTokenInEditorWith:) ifTrue: [
		aCoCompletionContext replaceTokenInEditorWith: self contents.
		^ true ].

	editor := (aCoCompletionContext respondsTo: #editor)
		ifTrue: [ [ aCoCompletionContext editor ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	editor ifNil: [ ^ false ].

	(editor respondsTo: #addString:) ifTrue: [
		editor addString: self contents.
		^ true ].

	(editor respondsTo: #replaceSelectionWith:) ifTrue: [
		editor replaceSelectionWith: self contents.
		^ true ].

	^ false
]
