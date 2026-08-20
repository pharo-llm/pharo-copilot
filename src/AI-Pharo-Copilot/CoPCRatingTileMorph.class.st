"
I display one large selectable numeric rating tile.
"
Class {
	#name : 'CoPCRatingTileMorph',
	#superclass : 'BorderedMorph',
	#instVars : [
		'value',
		'selected',
		'actionBlock'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'instance creation' }
CoPCRatingTileMorph class >> value: anInteger action: aBlock [

	^ self new
		value: anInteger;
		actionBlock: aBlock;
		yourself
]

{ #category : 'accessing' }
CoPCRatingTileMorph >> actionBlock: aBlock [

	actionBlock := aBlock ifNil: [ [ :ignored | ] ]
]

{ #category : 'colors' }
CoPCRatingTileMorph >> backgroundColor [

	^ selected
		ifTrue: [ Color r: 0.40 g: 0.45 b: 0.63 ]
		ifFalse: [ Color r: 0.21 g: 0.26 b: 0.37 ]
]

{ #category : 'colors' }
CoPCRatingTileMorph >> borderColor [

	^ selected
		ifTrue: [ Color white ]
		ifFalse: [ Color r: 0.13 g: 0.17 b: 0.25 ]
]

{ #category : 'drawing' }
CoPCRatingTileMorph >> drawOn: aCanvas [

	| font text textExtent origin |
	super drawOn: aCanvas.

	font := self ratingFont.
	text := value asString.
	textExtent := (font widthOfString: text) @ font height.
	origin := self bounds center - (textExtent // 2).
	aCanvas
		drawString: text
		at: origin
		font: font
		color: Color white
]

{ #category : 'events' }
CoPCRatingTileMorph >> handlesMouseDown: evt [

	^ true
]

{ #category : 'initialization' }
CoPCRatingTileMorph >> initialize [

	super initialize.

	value := 0.
	selected := false.
	actionBlock := [ :ignored | ].
	self
		extent: 104 @ 68;
		hResizing: #spaceFill;
		vResizing: #spaceFill;
		borderWidth: 2.
	self updateColors
]

{ #category : 'events' }
CoPCRatingTileMorph >> mouseUp: evt [

	super mouseUp: evt.
	(self containsPoint: evt cursorPoint) ifTrue: [
		actionBlock cull: self ]
]

{ #category : 'accessing' }
CoPCRatingTileMorph >> ratingFont [

	^ StandardFonts windowTitleFont
]

{ #category : 'accessing' }
CoPCRatingTileMorph >> selected [

	^ selected
]

{ #category : 'accessing' }
CoPCRatingTileMorph >> selected: aBoolean [

	selected := aBoolean = true.
	self updateColors
]

{ #category : 'private' }
CoPCRatingTileMorph >> updateColors [

	self
		color: self backgroundColor;
		borderStyle: (BorderStyle color: self borderColor width: 2).
	self changed
]

{ #category : 'accessing' }
CoPCRatingTileMorph >> value [

	^ value
]

{ #category : 'accessing' }
CoPCRatingTileMorph >> value: anInteger [

	value := anInteger
]
