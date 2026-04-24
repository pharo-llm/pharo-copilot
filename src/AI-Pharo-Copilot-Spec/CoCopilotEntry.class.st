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
		'label',
		'sessionId'
	],
	#category : 'AI-Pharo-Copilot-Spec',
	#package : 'AI-Pharo-Copilot-Spec'
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

{ #category : 'accessing' }
CoCopilotEntry >> activateOn: aCoCompletionContext [

	| editor applied evaluatorClass insertionStart |
	aCoCompletionContext ifNil: [ Error signal: 'Completion context is nil' ].

	applied := false.
	insertionStart := nil.

	editor := (aCoCompletionContext respondsTo: #editor)
		          ifTrue: [
				          [ aCoCompletionContext editor ]
					          on: Error
					          do: [ nil ] ]
		          ifFalse: [ nil ].

	editor ifNotNil: [
			insertionStart := self insertionStartIn: editor.
			(editor respondsTo: #addString:) ifTrue: [
					editor addString: self contents.
					applied := true ].

			(applied not and: [
					 (editor respondsTo: #selectionInterval) and: [
						 (editor respondsTo: #replaceSelectionWith:) and: [ editor selectionInterval isEmpty ] ] ]) ifTrue: [
					editor replaceSelectionWith: self contents.
					applied := true ].

			(applied and: [ insertionStart notNil ]) ifTrue: [
					self placeCaretOf: editor at: insertionStart + self contents size ] ].

	(applied not and: [ aCoCompletionContext respondsTo: #replaceTokenInEditorWith: ]) ifTrue: [
			aCoCompletionContext replaceTokenInEditorWith: self contents.
			applied := true ].

	applied ifTrue: [
			evaluatorClass := Smalltalk globals at: #CoPCSuggestionEvaluator ifAbsent: [ nil ].

			evaluatorClass ifNotNil: [
					[ evaluatorClass default recordSuggestionAccepted: self context: aCoCompletionContext ]
						on: Error
						do: [ :ex |  ] ] ].

	^ applied
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
CoCopilotEntry >> insertionStartIn: editor [
	"Answer the 1-based index where text is about to be inserted in the given editor, or nil if it cannot be determined."

	[
		(editor respondsTo: #startIndex) ifTrue: [ ^ editor startIndex ].
		(editor respondsTo: #selectionInterval) ifTrue: [
				| interval |
				interval := editor selectionInterval.
				interval isEmpty
					ifTrue: [
						(editor respondsTo: #caret) ifTrue: [ ^ editor caret ] ]
					ifFalse: [ ^ interval first ] ].
		(editor respondsTo: #caret) ifTrue: [ ^ editor caret ]
	]
		on: Error
		do: [ :ex |  ].
	^ nil
]

{ #category : 'accessing' }
CoCopilotEntry >> label [

	^ label ifNil: [ self defaultLabel ]
]

{ #category : 'accessing' }
CoCopilotEntry >> label: aString [

	label := aString
]

{ #category : 'accessing' }
CoCopilotEntry >> placeCaretOf: editor at: position [
	"Collapse any selection and position the editor caret at the given 1-based index.
	Pharo's RubTextEditor leaves inserted text selected after #addString:/#replaceSelectionWith:,
	which would cause the next keystroke to erase the accepted suggestion."

	[
		(editor respondsTo: #selectInvisiblyFrom:to:) ifTrue: [
				editor selectInvisiblyFrom: position to: position - 1.
				^ self ].
		(editor respondsTo: #selectAt:) ifTrue: [ editor selectAt: position ]
	]
		on: Error
		do: [ :ex |  ]
]

{ #category : 'accessing' }
CoCopilotEntry >> sessionId [

	^ sessionId
]

{ #category : 'accessing' }
CoCopilotEntry >> sessionId: aString [

	sessionId := aString
]

{ #category : 'displaying' }
CoCopilotEntry >> text: aString [
	"Set the suggestion text stored by this entry."

	text := aString
]
