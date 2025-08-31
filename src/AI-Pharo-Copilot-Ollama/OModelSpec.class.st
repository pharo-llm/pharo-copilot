"
Represents an Ollama model identified by family, tag, and label.
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
OModelSpec class >> family: aString tag: aTag label: aLabelString [

  ^ self new
    family: aString;
    tag: aTag;
    label: aLabelString;
    yourself
]

{ #category : 'accessing' }
OModelSpec >> family [

	^ family
]

{ #category : 'accessing' }
OModelSpec >> family: anObject [

	family := anObject
]

{ #category : 'accessing' }
OModelSpec >> fullName [ 

  ^ tag
    ifNil:  [ family ]
    ifNotNil: [ family , ':' , tag ]
]

{ #category : 'accessing' }
OModelSpec >> label [

	^ label
]

{ #category : 'accessing' }
OModelSpec >> label: anObject [

	label := anObject
]

{ #category : 'accessing' }
OModelSpec >> tag [

	^ tag
]

{ #category : 'accessing' }
OModelSpec >> tag: anObject [

	tag := anObject
]
