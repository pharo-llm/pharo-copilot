"
I display detailed information about a selected Copilot suggestion.
I show the full text of the suggestion in a scrollable view,
positioned next to the CopilotMenuMorph.
"
Class {
	#name : 'CopilotDetailMorph',
	#superclass : 'Morph',
	#instVars : [
		'textMorph',
		'arrowPosition'
	],
	#category : 'AI-Pharo-Copilot-Spec',
	#package : 'AI-Pharo-Copilot-Spec'
}

{ #category : 'accessing' }
CopilotDetailMorph class >> height [

	^ 400
]

{ #category : 'accessing' }
CopilotDetailMorph class >> width [

	^ 600
]

{ #category : 'geometry' }
CopilotDetailMorph >> bounds [

	^ super bounds topLeft extent: self class width @ self class height
]

{ #category : 'geometry' }
CopilotDetailMorph >> contentBounds [

	| rectangle |
	rectangle := self bounds insetBy: 10.
	^ rectangle
]

{ #category : 'accessing - defaults' }
CopilotDetailMorph >> defaultColor [

	^ CopilotSettings backgroundColor
]

{ #category : 'geometry' }
CopilotDetailMorph >> drawArrowOn: aCanvas [

	"Draw a small arrow pointing to the selected item in the menu."

	| point polygon size |
	size := 8.
	point := arrowPosition.
	polygon := OrderedCollection new.
	polygon add: point.
	polygon add: (point translateBy: size @ 0).
	polygon add: (point translateBy: size @ (size // 2)).
	polygon add: (point translateBy: 0 @ size).
	aCanvas drawPolygon: polygon fillStyle: (Color r: 0.4 g: 0.6 b: 0.9 alpha: 0.25)
]

{ #category : 'geometry' }
CopilotDetailMorph >> drawOn: aCanvas [

	super drawOn: aCanvas.
	arrowPosition ifNotNil: [ self drawArrowOn: aCanvas ]
]

{ #category : 'geometry' }
CopilotDetailMorph >> entryText: aString [

	"Set the text content to display."

	textMorph contents: aString
]

{ #category : 'geometry' }
CopilotDetailMorph >> initialize [

	super initialize.

	self borderStyle: (BorderStyle color: Color gray width: 1).
	self color: self defaultColor.

	textMorph := TextMorph new.
	textMorph
		autoFit: false;
		bounds: self contentBounds;
		borderWidth: 0;
		font: StandardFonts codeFont.

	self addMorph: textMorph
]

{ #category : 'geometry' }
CopilotDetailMorph >> position: aPoint menuWidth: anInteger [

	"Position the detail morph next to the menu, accounting for screen boundaries."

	| y x |
	arrowPosition := aPoint.

	"Try to position to the right of the menu"
	x := aPoint x + 10.
	y := aPoint y.

	"If it would go off screen, position to the left instead"
	(x + self class width > self currentWorld width) ifTrue: [
		x := aPoint x - self class width - anInteger - 10.
		arrowPosition := (aPoint x - anInteger) @ aPoint y
	].

	"Keep it on screen vertically"
	(y + self class height > self currentWorld height) ifTrue: [
		y := self currentWorld height - self class height
	].

	self position: x @ y
]
