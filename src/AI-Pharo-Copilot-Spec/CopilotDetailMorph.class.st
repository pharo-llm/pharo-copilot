"
I display detailed information about a selected Copilot suggestion.
I show the full text of the suggestion in a scrollable view,
positioned next to the CopilotMenuMorph.
"
Class {
	#name : 'CopilotDetailMorph',
	#superclass : 'Morph',
	#instVars : [
		'title',
		'description',
		'arrowPosition',
		'label'
	],
	#category : 'AI-Pharo-Copilot-Spec',
	#package : 'AI-Pharo-Copilot-Spec'
}

{ #category : 'accessing' }
CopilotDetailMorph class >> height [

	^ CopilotMenuMorph itemHeight * 5.
]

{ #category : 'accessing' }
CopilotDetailMorph class >> width [

	^ CopilotMenuMorph itemWidth * 1.2
]

{ #category : 'accessing - defaults' }
CopilotDetailMorph class >> foregroundColorForBackground: aColor [
	"Answer a readable text color for the configured popup background."

	| brightness |
	aColor ifNil: [ ^ Color black ].

	brightness := [
		(aColor red * 0.299) + (aColor green * 0.587) + (aColor blue * 0.114)
	] on: Error do: [ ^ Color black ].

	^ brightness > 0.55
		ifTrue: [ Color black ]
		ifFalse: [ Color white ]
]

{ #category : 'geometry' }
CopilotDetailMorph >> bounds [

	^ super bounds topLeft extent: self class width @ self class height
]

{ #category : 'geometry' }
CopilotDetailMorph >> contentBounds [

	| factor rectangle |
	factor := CopilotMenuMorph itemHeight + 10.
	rectangle := self bounds top: self bounds top + 3.
	rectangle := rectangle left: rectangle left + (factor * 2.0).
	^ rectangle
]

{ #category : 'accessing - defaults' }
CopilotDetailMorph >> defaultColor [

	^ CopilotMenuMorph backgroundColor
]

{ #category : 'geometry' }
CopilotDetailMorph >> descriptionBounds [

	^ self contentBounds top: self contentBounds top + 40
]

{ #category : 'initialization' }
CopilotDetailMorph >> drawArrowOn: aCanvas [

	| point factor polygon |
	factor := CopilotMenuMorph itemHeight.
	point := arrowPosition.
	polygon := OrderedCollection new.
	polygon add: point.
	polygon add: (point := point translateBy: (factor / 2) @ 0).
	polygon add: (point := point translateBy: 0 @ (factor * -0.5)).
	polygon add: (point := point translateBy: factor @ factor).
	polygon add: (point := point translateBy: (factor * -1) @ factor).
	polygon add: (point := point translateBy: 0 @ (factor * -0.5)).
	polygon add: (point := point translateBy: (factor * -0.5) @ 0).
	aCanvas drawPolygon: polygon fillStyle: CopilotMenuMorph scrollColor
]

{ #category : 'initialization' }
CopilotDetailMorph >> drawOn: aCanvas [

	super drawOn: aCanvas.
	arrowPosition ifNotNil: [ self drawArrowOn: aCanvas ]
]

{ #category : 'initialization' }
CopilotDetailMorph >> foregroundColor [

	^ self class foregroundColorForBackground: self defaultColor
]

{ #category : 'initialization' }
CopilotDetailMorph >> entryDescription: anEntryDescription [
	title
		contents: (anEntryDescription title
			ifNil: [
				description bounds: self titleBounds.
				String new ]
			ifNotNil: [
				description bounds: self descriptionBounds.
				anEntryDescription title ]).
	description contentsWrapped: anEntryDescription description.
	label contents: anEntryDescription label
]

{ #category : 'initialization' }
CopilotDetailMorph >> initialize [

	| childBounds foregroundColor |
	super initialize.
	self color: self defaultColor.
	self borderStyle: (BorderStyle color: Color gray width: 1).

	childBounds := self contentBounds.
	foregroundColor := self foregroundColor.

	label := StringMorph
		contents: ''
		font: StandardFonts menuFont.
	label color: foregroundColor.
	label bounds: childBounds.
	self addMorph: label.

	title := StringMorph
		contents: ''
		font: StandardFonts windowTitleFont.
	title color: foregroundColor.
	title bounds: self titleBounds.
	self addMorph: title.

	description := TextMorph new.
	description autoFit: false.
	description bounds: self descriptionBounds.
	description borderWidth: 0.
	self setTextColor: foregroundColor on: description.
	self addMorph: description
]

{ #category : 'initialization' }
CopilotDetailMorph >> setTextColor: aColor on: aMorph [

	(aMorph respondsTo: #textColor:) ifTrue: [
		aMorph textColor: aColor.
		^ self ].

	(aMorph respondsTo: #color:) ifTrue: [
		aMorph color: aColor ]
]

{ #category : 'initialization' }
CopilotDetailMorph >> position: aPoint menuWidth: anInteger [

	| y x |
	arrowPosition := aPoint.
	y := aPoint y + self class height.
	y := y > self currentWorld height
		ifTrue: [ self currentWorld height - self class height ]
		ifFalse: [ aPoint y - CopilotMenuMorph itemHeight ].
	x := aPoint x.
	x := x + self class width > self currentWorld width
		ifTrue: [
			arrowPosition := (self positionOnLeft: anInteger) @ aPoint y.
			arrowPosition x ]
		ifFalse: [ x ].
	self position: x @ y
]

{ #category : 'initialization' }
CopilotDetailMorph >> positionOnLeft: anInteger [

	^ arrowPosition x - self class width - anInteger
]

{ #category : 'geometry' }
CopilotDetailMorph >> titleBounds [

	^ self contentBounds top: self contentBounds top + 20
]
