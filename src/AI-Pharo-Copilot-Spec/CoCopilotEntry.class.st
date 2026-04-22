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

	| editor applied evaluatorClass |
	aCoCompletionContext ifNil: [ Error signal: 'Completion context is nil' ].

	applied := false.

	"First use the completion context so token replacement + UI state stay consistent"
	(applied not and: [ aCoCompletionContext respondsTo: #replaceTokenInEditorWith: ]) ifTrue: [
		aCoCompletionContext replaceTokenInEditorWith: self contents.
		applied := true
	].

	"Fallback only if the context cannot apply it"
	editor := (aCoCompletionContext respondsTo: #editor)
		ifTrue: [ [ aCoCompletionContext editor ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].

	editor ifNotNil: [
		(applied not and: [ editor respondsTo: #replaceSelectionWith: ]) ifTrue: [
			editor replaceSelectionWith: self contents.
			applied := true
		].

		(applied not and: [ editor respondsTo: #addString: ]) ifTrue: [
			editor addString: self contents.
			applied := true
		].

		(applied and: [ editor respondsTo: #changed ]) ifTrue: [
			editor changed
		].
	].

	applied ifTrue: [
		evaluatorClass := Smalltalk globals at: #CoPCSuggestionEvaluator ifAbsent: [ nil ].
		evaluatorClass ifNotNil: [
			[ evaluatorClass default recordSuggestionAccepted: self context: aCoCompletionContext ]
				on: Error
				do: [ :ex |
					 ] ] ].

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
CoCopilotEntry >> label [

	^ label ifNil: [ self defaultLabel ]
]

{ #category : 'accessing' }
CoCopilotEntry >> label: aString [

	label := aString
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
