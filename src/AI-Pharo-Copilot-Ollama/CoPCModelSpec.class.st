"
OModelSpec is a small value object that describes an Ollama model using a
model family (name), an optional tag (version/variant), and a human-friendly label.
It also knows how to produce the model's full name as expected by Ollama: 'family' or 'family:tag'.

"
Class {
	#name : 'CoPCModelSpec',
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
CoPCModelSpec class >> family: aFamilyString tag: aTagStringOrNil label: aLabelString [
	"Create a model spec with a family name, optional tag, and a display label."

	^ self new
		family: aFamilyString;
		tag: aTagStringOrNil;
		label: aLabelString;
		yourself
]

{ #category : 'accessing' }
CoPCModelSpec >> family [
	"Answer the model family (base name)."

	^ family
]

{ #category : 'accessing' }
CoPCModelSpec >> family: aFamilyString [
	"Set the model family (base name)."

	family := aFamilyString
]

{ #category : 'accessing' }
CoPCModelSpec >> fullName [
	"Answer the Ollama model identifier: 'family' when tag is nil, otherwise 'family:tag'."

	^ tag
		ifNil: [ family ]
		ifNotNil: [ family , ':' , tag ]
]

{ #category : 'accessing' }
CoPCModelSpec >> label [
	"Answer the human-friendly label for this model."

	^ label
]

{ #category : 'accessing' }
CoPCModelSpec >> label: aLabelString [
	"Set the human-friendly label for this model."

	label := aLabelString
]

{ #category : 'accessing' }
CoPCModelSpec >> tag [
	"Answer the model tag (version/variant) or nil if not set."

	^ tag
]

{ #category : 'accessing' }
CoPCModelSpec >> tag: aTagStringOrNil [
	"Set the model tag (version/variant). Use nil when there is no tag."

	tag := aTagStringOrNil
]
