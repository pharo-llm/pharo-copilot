"
Light completion menu morph.
Shows a single-line preview per entry, supports keyboard navigation,
Enter/Tab accept, Escape close. No detail pane.
"
Class {
	#name : 'CopilotMenuMorph',
	#superclass : 'Morph',
	#instVars : [
		'entries',
		'selectedIndex',
		'firstVisible',
		'context',
		'builder'
	],
	#category : 'AI-Pharo-Copilot-Spec',
	#package : 'AI-Pharo-Copilot-Spec'
}

{ #category : 'accessing' }
CopilotMenuMorph class >> builder: aBuilder context: aContext entries: entryCollection position: aPoint [

	^ self new
		builder: aBuilder
		context: aContext
		entries: entryCollection
		position: aPoint
]

{ #category : 'accessing' }
CopilotMenuMorph class >> itemHeight [

	^ StandardFonts codeFont height + 10
]

{ #category : 'accessing' }
CopilotMenuMorph class >> itemWidth [ ^ 420 ]

{ #category : 'accessing' }
CopilotMenuMorph class >> maxVisibleItems [ ^ 5 ]

{ #category : 'accessing' }
CopilotMenuMorph class >> scrollColor [

	^ Color r: 0.4 g: 0.6 b: 0.9 alpha: 0.2
]

{ #category : 'initialization' }
CopilotMenuMorph >> initialize [

	super initialize.
	self color: CopilotSettings backgroundColor.
	self borderStyle: (BorderStyle color: Color gray width: 1).
	selectedIndex := 1.
	firstVisible := 1.
	entries := #()
]

{ #category : 'private' }
CopilotMenuMorph >> builder: aBuilder context: aContext entries: entryCollection position: aPoint [

	builder := aBuilder.
	context := aContext.
	entries := entryCollection asArray.

	self resize.
	self openInWorld.
	self position: (self clampPosition: aPoint - (20 @ 0)).
	selectedIndex := entries isEmpty ifTrue: [ 0 ] ifFalse: [ 1 ].
	self changed
]

{ #category : 'private' }
CopilotMenuMorph >> resize [

	| visibleCount height |
	visibleCount := entries size min: self class maxVisibleItems.
	height := visibleCount * self class itemHeight.
	self extent: self class itemWidth @ height
]

{ #category : 'private' }
CopilotMenuMorph >> clampPosition: aPoint [

	| world x y |
	world := self currentWorld ifNil: [ ^ aPoint ].
	x := aPoint x. y := aPoint y.
	x + self width  > world width  ifTrue: [ x := world width  - self width ].
	y + self height > world height ifTrue: [ y := aPoint y - self height ].
	^ (x max: 0) @ (y max: 0)
]

{ #category : 'private' }
CopilotMenuMorph >> isClosed [ ^ owner isNil ]

{ #category : 'private' }
CopilotMenuMorph >> delete [

	super delete.
	builder ifNotNil: [ builder menuClosed ]
]

{ #category : 'private' }
CopilotMenuMorph >> drawOn: aCanvas [

	| rectangle |
	super drawOn: aCanvas.
	entries isEmpty ifTrue: [ ^ self ].

	rectangle := self bounds insetBy: 1.
	rectangle := rectangle withHeight: self class itemHeight.

	firstVisible to: (self lastVisible) do: [ :index |
		self drawLine: index on: aCanvas rectangle: rectangle.
		rectangle := rectangle translateBy: 0 @ self class itemHeight ]
]

{ #category : 'private' }
CopilotMenuMorph >> drawLine: index on: aCanvas rectangle: rectangle [

	| entry preview rect |
	entry := entries at: index.
	index = selectedIndex ifTrue: [
		aCanvas fillRectangle: (rectangle withHeight: self class itemHeight)
			color: self class scrollColor ].
	preview := (entry displayString lines
		ifEmpty: [ '' ]
		ifNotEmpty: [ :ls | ls first ]).
	rect := rectangle insetBy: 4.
	aCanvas
		drawString: preview
		in: rect
		font: StandardFonts codeFont
		color: Color white
]

{ #category : 'private' }
CopilotMenuMorph >> lastVisible [

	^ (firstVisible + self class maxVisibleItems - 1) min: entries size
]

{ #category : 'private' }
CopilotMenuMorph >> handlesKeyDown: anEvent [ ^ true ]

{ #category : 'private' }
CopilotMenuMorph >> handlesMouseDown: anEvent [ ^ true ]

{ #category : 'private' }
CopilotMenuMorph >> takesKeyboardFocus [ ^ true ]

{ #category : 'private' }
CopilotMenuMorph >> keyDown: anEvent [

	| key |
	key := anEvent key.

	({ KeyboardKey up. KeyboardKey keypadUp } includes: key) ifTrue: [
		self moveUp. ^ true ].
	({ KeyboardKey down. KeyboardKey keypadDown } includes: key) ifTrue: [
		self moveDown. ^ true ].
	({ KeyboardKey enter. KeyboardKey keypadEnter. KeyboardKey tab } includes: key) ifTrue: [
		self insertSelected. ^ true ].
	key = KeyboardKey escape ifTrue: [ self delete. ^ true ].

	^ false
]

{ #category : 'private' }
CopilotMenuMorph >> mouseDown: evt [

	(self bounds containsPoint: evt cursorPoint)
		ifTrue: [
			evt wasHandled: true.
			self selectIndexAtPoint: evt cursorPoint.
			^ self insertSelected ].
	self delete
]

{ #category : 'private' }
CopilotMenuMorph >> selectIndexAtPoint: aPoint [

	| y idx |
	y := aPoint y - self bounds top.
	idx := firstVisible + (y / self class itemHeight) floor.
	selectedIndex := (idx min: entries size) max: 1
]

{ #category : 'private' }
CopilotMenuMorph >> moveUp [

	entries isEmpty ifTrue: [ ^ self ].
	selectedIndex := (selectedIndex - 1) max: 1.
	selectedIndex < firstVisible ifTrue: [ firstVisible := selectedIndex ].
	self changed
]

{ #category : 'private' }
CopilotMenuMorph >> moveDown [

	entries isEmpty ifTrue: [ ^ self ].
	selectedIndex := (selectedIndex + 1) min: entries size.
	selectedIndex > self lastVisible ifTrue: [ firstVisible := firstVisible + 1 ].
	self changed
]

{ #category : 'private' }
CopilotMenuMorph >> insertSelected [

	| entry |
	entries isEmpty ifTrue: [ ^ false ].
	entry := entries at: selectedIndex.
	self delete.
	entry activateOn: context.
	^ true
]
