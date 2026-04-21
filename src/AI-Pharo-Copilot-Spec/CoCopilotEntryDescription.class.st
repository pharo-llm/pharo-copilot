"
Desccription of each entry
"
Class {
	#name : 'CoCopilotEntryDescription',
	#superclass : 'Object',
	#instVars : [
		'label',
		'title',
		'description'
	],
	#category : 'AI-Pharo-Copilot-Spec',
	#package : 'AI-Pharo-Copilot-Spec'
}

{ #category : 'instance creation' }
CoCopilotEntryDescription class >> label: aLabel title: aTitle description: aDescription [
	^ self new
		label: aLabel;
		title: aTitle;
		description: aDescription;
		yourself
]

{ #category : 'accessing' }
CoCopilotEntryDescription >> description [
	^ description
]

{ #category : 'accessing' }
CoCopilotEntryDescription >> description: aString [
	description := aString
]

{ #category : 'accessing' }
CoCopilotEntryDescription >> label [
	^ label
]

{ #category : 'accessing' }
CoCopilotEntryDescription >> label: aString [
	label := aString
]

{ #category : 'accessing' }
CoCopilotEntryDescription >> title [
	^ title
]

{ #category : 'accessing' }
CoCopilotEntryDescription >> title: aString [
	title := aString
]
