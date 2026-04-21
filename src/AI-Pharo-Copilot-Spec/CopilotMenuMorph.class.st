"
The menu morph for the user
"
Class {
	#name : 'CopilotMenuMorph',
	#superclass : 'Morph',
	#instVars : [
		'entries',
		'selectedIndex',
		'firstVisible',
		'pageHeight',
		'context',
		'builder',
		'detailMorph',
		'detailPosition',
		'isDetailMorphVisible'
	],
	#category : 'AI-Pharo-Copilot-Spec',
	#package : 'AI-Pharo-Copilot-Spec'
}

{ #category : 'accessing' }
CopilotMenuMorph class >> backgroundColor [ 

^ CopilotSettings backgroundColor

]

{ #category : 'accessing' }
CopilotMenuMorph class >> builder: aBuilder context: aContext entries: entryCollection position: aPoint [
	"Create and display a new menu with the given entries at the specified position."

	^ self new
		builder: aBuilder
		context: aContext
		entries: entryCollection
		position: aPoint
]

{ #category : 'accessing' }
CopilotMenuMorph class >> itemHeight [

	"One visible line only"
	^ StandardFonts codeFont height + 10
]

{ #category : 'accessing' }
CopilotMenuMorph class >> itemWidth [

	^ 420
]

{ #category : 'accessing' }
CopilotMenuMorph class >> maxVisibleItems [

	^ 5 "Show up to 5 suggestions at once"
]

{ #category : 'accessing' }
CopilotMenuMorph class >> scrollColor [

	^ Color r: 0.4 g: 0.6 b: 0.9 alpha: 0.2 "Softer blue highlight with less opacity"
]

{ #category : 'private' }
CopilotMenuMorph >> browse [

	"Browse details of the selected entry if available."

	self itemsCount isZero ifTrue: [ ^ false ].
	detailMorph ifNotNil: [ ^ true ].
	self showDetail.
	^ true
]

{ #category : 'private' }
CopilotMenuMorph >> builder: aBuilder context: aContext entries: entryCollection position: aPoint [

	builder := aBuilder.
	context := aContext.
	entries := entryCollection asArray.

	self resize.
	self openInWorld.
	self position: (self clampPosition: aPoint - (20 @ 0)).
	self selectedIndex: (entries isEmpty
			 ifTrue: [ 0 ]
			 ifFalse: [ 1 ]).

	"entries isEmpty ifFalse: [ self showDetail ]."
	self changed
]

{ #category : 'private' }
CopilotMenuMorph >> clampPosition: aPoint [
	"Ensure the menu stays within the visible screen area."

	| world x y worldWidth worldHeight |
	world := self currentWorld ifNil: [ ^ aPoint ].

	worldWidth := world width.
	worldHeight := world height.
	x := aPoint x.
	y := aPoint y. "If the menu would go off the right edge, shift left"
	x + self width > worldWidth ifTrue: [ x := worldWidth - self width ]. "If the menu would go off the bottom edge, show it above the anchor point"
	y + self height > worldHeight ifTrue: [ y := aPoint y - self height ]. "Keep on screen"
	x := x max: 0.
	y := y max: 0.

	^ x @ y
]

{ #category : 'private' }
CopilotMenuMorph >> close [

	self delete
]

{ #category : 'private' }
CopilotMenuMorph >> currentPage [
	^ (self selectedIndex - 1 // self pageHeight) + 1
]

{ #category : 'accessing - defaults' }
CopilotMenuMorph >> defaultColor [

	^ self theme windowColorFor: self
]

{ #category : 'private' }
CopilotMenuMorph >> delete [

	super delete.
	builder ifNotNil: [ builder menuClosed ]
]

{ #category : 'private' }
CopilotMenuMorph >> detailDescriptionFor: anEntry [
	| scopeLabel behavior |
	behavior := (context respondsTo: #completionClass)
		ifTrue: [ context completionClass ]
		ifFalse: [ nil ].

	scopeLabel := behavior
		ifNil: [ 'copilot' ]
		ifNotNil: [ behavior name ].

	^ CoCopilotEntryDescription
		label: scopeLabel
		title: anEntry label
		description: anEntry description
]

{ #category : 'private' }
CopilotMenuMorph >> detailPosition: aPoint [

	detailPosition := aPoint.
	self updateDetail
]

{ #category : 'private' }
CopilotMenuMorph >> drawLine: index on: aCanvas rectangle: rectangle [
	"Complishon-style: selected row drives detail anchor."

	| entry displayText font previewText rect |
	entry := entries at: index.
	displayText := entry displayString.

	index = selectedIndex ifTrue: [
		rect := rectangle withHeight: self class itemHeight.
		aCanvas fillRectangle: rect color: self class scrollColor.
		self detailPosition: rect topRight
	].

	font := StandardFonts codeFont.
	previewText := self previewTextFor: displayText maxLines: 1.

	rect := rectangle insetBy: 4.
	aCanvas
		drawString: previewText
		in: rect
		font: font
		color: Color white.

	index < self lastVisible ifTrue: [
		aCanvas
			line: (rectangle bottomLeft translateBy: 6 @ -1)
			to: (rectangle bottomRight translateBy: -6 @ -1)
			color: (Color white alpha: 0.12)
	]
]

{ #category : 'private' }
CopilotMenuMorph >> drawOn: aCanvas [

	"Draw the menu background and all visible entries."

	| rectangle |
	super drawOn: aCanvas.

	rectangle := self bounds insetBy: 1.
	rectangle := rectangle withHeight: self class itemHeight.

	self firstVisible to: self lastVisible do: [ :index |
		self drawLine: index on: aCanvas rectangle: rectangle.
		rectangle := rectangle translateBy: 0 @ self class itemHeight
	]
]

{ #category : 'private' }
CopilotMenuMorph >> end [
	"Move to the last page."

	self gotoPage: self pageCount.
	self changed
]

{ #category : 'private' }
CopilotMenuMorph >> firstVisible [

	^ firstVisible min: self itemsCount max: 1
]

{ #category : 'private' }
CopilotMenuMorph >> gotoPage: anInteger [

	"Navigate to the specified page number."

	| item |
	item := (anInteger - 1) * self pageHeight + 1.
	item >= self itemsCount ifTrue: [ ^ self ].
	item := item max: 1.
	firstVisible := item.
	self selectedIndex: firstVisible
]

{ #category : 'private' }
CopilotMenuMorph >> handlesKeyDown: anEvent [

	^ true
]

{ #category : 'private' }
CopilotMenuMorph >> handlesMouseDown: anEvent [

	^ true
]

{ #category : 'private' }
CopilotMenuMorph >> hasDetail [

	^ detailMorph isNotNil
]

{ #category : 'private' }
CopilotMenuMorph >> hideDetail [
	detailMorph ifNil: [ ^ false ].

	self removeMorph: detailMorph.
	detailMorph delete.
	detailMorph := nil.
	isDetailMorphVisible := false.
	self changed.
	^ true
]

{ #category : 'private' }
CopilotMenuMorph >> home [

	"Move to the first page."

	self gotoPage: 1.
	self changed
]

{ #category : 'private' }
CopilotMenuMorph >> initialize [

	super initialize.
	self color: self defaultColor.
	self borderStyle: (BorderStyle color: Color gray width: 1).
	isDetailMorphVisible := false.
	selectedIndex := 1.
	firstVisible := 1.
	entries := #()
]

{ #category : 'private' }
CopilotMenuMorph >> insertSelected [

	"Insert the selected suggestion into the editor and close the menu."

	| selectedEntry |
	self itemsCount isZero ifTrue: [ ^ false ].

	selectedEntry := entries at: selectedIndex.
	self delete.

	"Apply the selected entry to the context"
	selectedEntry activateOn: context.

	^ true
]

{ #category : 'private' }
CopilotMenuMorph >> isClosed [

	^ owner isNil
]

{ #category : 'private' }
CopilotMenuMorph >> itemsCount [

	^ entries size
]

{ #category : 'private' }
CopilotMenuMorph >> keyDown: anEvent [
	"Handle keyboard navigation."

	| key |
	key := anEvent key.

	({KeyboardKey up. KeyboardKey keypadUp} includes: key) ifTrue: [
		self moveUp.
		^ true
	].

	({KeyboardKey down. KeyboardKey keypadDown} includes: key) ifTrue: [
		self moveDown.
		^ true
	].

	key = KeyboardKey pageUp ifTrue: [
		self pageUp.
		^ true
	].

	key = KeyboardKey pageDown ifTrue: [
		self pageDown.
		^ true
	].

	key = KeyboardKey home ifTrue: [
		self home.
		^ true
	].

	key = KeyboardKey end ifTrue: [
		self end.
		^ true
	].

	({KeyboardKey enter. KeyboardKey keypadEnter. KeyboardKey tab} includes: key) ifTrue: [
		self insertSelected.
		^ true
	].

	key = KeyboardKey escape ifTrue: [
		self close.
		^ true
	].

	key = KeyboardKey right ifTrue: [
		detailMorph
			ifNil: [ self showDetail ]
			ifNotNil: [ self browse ].
		^ true
	].

	key = KeyboardKey left ifTrue: [
		self hideDetail.
		^ true
	].

	^ false
]

{ #category : 'private' }
CopilotMenuMorph >> lastVisible [

	^ (self firstVisible + self pageHeight - 1) min: self itemsCount
]

{ #category : 'private' }
CopilotMenuMorph >> mouseDown: evt [
	"Handle mouse clicks on entries."

	(self bounds containsPoint: evt cursorPoint) ifTrue: [
		evt wasHandled: true.
		^ self
			selectIndexAtPoint: evt cursorPoint;
			insertSelected
	].

	"Click outside closes the menu"
	self close
]

{ #category : 'private' }
CopilotMenuMorph >> moveDown [

	"Move selection down one item."

	self selectedIndex: self selectedIndex + 1.
	(self selectedIndex > self lastVisible and: [ self selectedIndex <= self itemsCount ])
		ifTrue: [ firstVisible := firstVisible + 1 ].
	self changed
]

{ #category : 'private' }
CopilotMenuMorph >> moveUp [
	"Move selection up one item."

	self selectedIndex isZero ifTrue: [ ^ self ].
	self selectedIndex: self selectedIndex - 1.
	self selectedIndex < self firstVisible
		ifTrue: [ firstVisible := firstVisible - 1 ].
	self changed
]

{ #category : 'private' }
CopilotMenuMorph >> pageCount [
	| count |
	self itemsCount == self pageHeight ifTrue: [ ^ 1 ].
	count := self itemsCount // self pageHeight.
	(self itemsCount \\ self pageHeight) > 0 ifTrue: [ count := count + 1 ].
	^ count
]

{ #category : 'private' }
CopilotMenuMorph >> pageDown [
	"Move down one page."

	self gotoPage: self currentPage + 1.
	self changed
]

{ #category : 'private' }
CopilotMenuMorph >> pageHeight [
	^ pageHeight ifNil: [ self class maxVisibleItems ]
]

{ #category : 'private' }
CopilotMenuMorph >> pageUp [
	"Move up one page."

	self gotoPage: self currentPage - 1.
	self changed
]

{ #category : 'private' }
CopilotMenuMorph >> previewTextFor: aString maxLines: maxLineCount [
	"Extract a preview of the text, limiting to maxLines."

	| lines |
	lines := aString lines.
	lines size <= maxLineCount
		ifTrue: [ ^ aString ].

	^ String streamContents: [ :stream |
		1 to: maxLineCount do: [ :i |
			i > 1 ifTrue: [ stream cr ].
			stream nextPutAll: (lines at: i)
		].
		stream nextPutAll: '...'
	]
]

{ #category : 'private' }
CopilotMenuMorph >> resize [
	"Calculate and set the appropriate size for the menu."

	| extent height visibleCount |
	visibleCount := self itemsCount min: self class maxVisibleItems.
	height := visibleCount * self class itemHeight.
	pageHeight := self class maxVisibleItems.
	extent := self class itemWidth @ height.
	self extent: extent
]

{ #category : 'private' }
CopilotMenuMorph >> selectIndexAtPoint: aPoint [
	"Select the entry at the given point."

	| yPos |
	yPos := aPoint y - self bounds top.
	selectedIndex := firstVisible + (yPos / self class itemHeight) floor.
	selectedIndex := selectedIndex min: self itemsCount max: 1
]

{ #category : 'private' }
CopilotMenuMorph >> selectedEntry [
	^ entries at: self selectedIndex
]

{ #category : 'private' }
CopilotMenuMorph >> selectedIndex [
	^ selectedIndex ifNil: [ selectedIndex := 1 ]
]

{ #category : 'accessing - defaults' }
CopilotMenuMorph >> selectedIndex: aNumber [
	self itemsCount isZero ifTrue: [ ^ self ].

	((1 to: self itemsCount) includes: aNumber) ifTrue: [
		aNumber ~= selectedIndex ifTrue: [
			selectedIndex := aNumber.
			self updateDetail
		]
	]
]

{ #category : 'private' }
CopilotMenuMorph >> showDetail [
	self itemsCount isZero ifTrue: [ ^ self ].

	detailMorph ifNotNil: [ ^ self updateDetail ].

	detailMorph := CopilotDetailMorph new.
	self updateDetail
]

{ #category : 'private' }
CopilotMenuMorph >> takesKeyboardFocus [

	^ true
]

{ #category : 'private' }
CopilotMenuMorph >> updateDetail [
	detailMorph ifNil: [ ^ self ].
	detailPosition ifNil: [ ^ self ].

	detailMorph
		entryDescription: (self detailDescriptionFor: self selectedEntry);
		position: detailPosition menuWidth: self width.

	isDetailMorphVisible ifTrue: [ ^ self ].
	self addMorph: detailMorph.
	isDetailMorphVisible := true
]
