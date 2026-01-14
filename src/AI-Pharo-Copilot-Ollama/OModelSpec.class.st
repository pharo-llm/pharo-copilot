"
OModelSpec is a small value object that describes an Ollama model using a
model family (name), an optional tag (version/variant), and a human-friendly label.
It also knows how to produce the model's full name as expected by Ollama: 'family' or 'family:tag'.

"
Class {
	#name : 'OModelSpec',
	#superclass : 'Object',
	#instVars : [
		'family',
		'tag',
		'label'
	],
	#category : 'AI-Pharo-Copilot-Ollama',
	#package : 'AI-Pharo-Copilot-Ollama'
}

{ #category : 'instance creation' }
OModelSpec class >> family: aFamilyString tag: aTagStringOrNil label: aLabelString [
	"Create a model spec with a family name, optional tag, and a display label."

	^ self new
		family: aFamilyString;
		tag: aTagStringOrNil;
		label: aLabelString;
		yourself
]

{ #category : 'accessing' }
OModelSpec >> family [
	"Answer the model family (base name)."

	^ family
]

{ #category : 'accessing' }
OModelSpec >> family: aFamilyString [
	"Set the model family (base name)."

	family := aFamilyString
]

{ #category : 'accessing' }
OModelSpec >> fullName [
	"Answer the Ollama model identifier: 'family' when tag is nil, otherwise 'family:tag'."

	^ tag
		ifNil: [ family ]
		ifNotNil: [ family , ':' , tag ]
]

{ #category : 'accessing' }
OModelSpec >> label [
	"Answer the human-friendly label for this model."

	^ label
]

{ #category : 'accessing' }
OModelSpec >> label: aLabelString [
	"Set the human-friendly label for this model."

	label := aLabelString
]

{ #category : 'accessing' }
OModelSpec >> tag [
	"Answer the model tag (version/variant) or nil if not set."

	^ tag
]

{ #category : 'accessing' }
OModelSpec >> tag: aTagStringOrNil [
	"Set the model tag (version/variant). Use nil when there is no tag."

	tag := aTagStringOrNil
]
