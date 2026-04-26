"
I gather the current Calypso browser navigation history (currently visible
selection plus the recent undo/redo navigation states) and format it as a
short textual block that can be prepended to the class context sent to the
completion model.
I am completely safe to call from any environment: if Calypso is not loaded,
no browser is open, or anything fails while reading the browser state, I
return an empty string and never raise.
To disable me from runtime code use:
	CoPCContextNavigationHistory enabled: false.
To disable me from the source, comment out the call to
#prependNavigationHistoryTo: in CoPharoCopilotResultSetBuilder>>classContextFor:prefix:.
"
Class {
	#name : 'CoPCContextNavigationHistory',
	#superclass : 'Object',
	#instVars : [
		'maxHistoryEntries'
	],
	#classInstVars : [
		'enabled'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'accessing' }
CoPCContextNavigationHistory class >> enabled [

	^ enabled ifNil: [ enabled := true ]
]

{ #category : 'accessing' }
CoPCContextNavigationHistory class >> enabled: aBoolean [

	enabled := aBoolean = true.
	CopilotSettings autoSaveSettings
]

{ #category : 'class initialization' }
CoPCContextNavigationHistory class >> initialize [

	enabled ifNotNil: [ ^ self ].
	self initializeDefaults
]

{ #category : 'accessing' }
CoPCContextNavigationHistory class >> initializeDefaults [

	enabled := true
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> bestBrowserFrom: browsers [

	| best bestCount |
	best := browsers first.
	bestCount := self totalSelectionsForBrowser: best.
	browsers do: [ :candidate |
			| count |
			count := self totalSelectionsForBrowser: candidate.
			count > bestCount ifTrue: [
					best := candidate.
					bestCount := count ] ].
	^ best
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> browserStateFromHistoryEntry: entry [

	(entry respondsTo: #viewStates) ifTrue: [ ^ entry ].
	(entry respondsTo: #browserState) ifTrue: [
		^ [ entry browserState ] on: Error do: [ nil ] ].
	^ nil
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> formatNames: names [

	names isEmpty ifTrue: [ ^ '(none)' ].
	^ String streamContents: [ :s |
		names
			do: [ :each | s nextPutAll: each asString ]
			separatedBy: [ s nextPutAll: ', ' ] ]
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> formatTitle: title currentPanes: currentPanes undoEntries: undoEntries redoEntries: redoEntries [

	(currentPanes isEmpty
		and: [ undoEntries isEmpty
		and: [ redoEntries isEmpty ] ]) ifTrue: [ ^ '' ].

	^ String streamContents: [ :s |
		s nextPutAll: 'Browser navigation history (Calypso):'; cr.
		title isEmpty ifFalse: [
			s nextPutAll: 'Browser: '; nextPutAll: title; cr ].

		currentPanes isEmpty ifFalse: [
			s nextPutAll: 'Current selection:'; cr.
			self writePanes: currentPanes on: s ].

		undoEntries isEmpty ifFalse: [
			s nextPutAll: 'Recent navigation (undo, oldest first):'; cr.
			self writeEntries: undoEntries on: s ].

		redoEntries isEmpty ifFalse: [
			s nextPutAll: 'Forward navigation (redo):'; cr.
			self writeEntries: redoEntries on: s ] ]
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> gather [

	^ [ self gatherUnsafe ] on: Error do: [ :ex | '' ]
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> gatherUnsafe [

	| browserClass browsers browser title currentPanes history undoEntries redoEntries |
	browserClass := Smalltalk globals at: #ClyBrowserMorph ifAbsent: [ nil ].
	browserClass ifNil: [ ^ '' ].

	browsers := self openBrowsersFrom: browserClass.
	browsers isEmpty ifTrue: [ ^ '' ].

	browser := self bestBrowserFrom: browsers.
	title := [ browser window labelString asString ] on: Error do: [ '' ].

	currentPanes := self paneSelectionsFromBrowser: browser.

	history := [ browser navigationHistory ] on: Error do: [ nil ].
	undoEntries := history
		ifNil: [ #() ]
		ifNotNil: [ self paneSelectionsFromHistoryList: ([ history undoList ] on: Error do: [ #() ]) ].
	redoEntries := history
		ifNil: [ #() ]
		ifNotNil: [ self paneSelectionsFromHistoryList: ([ history redoList ] on: Error do: [ #() ]) ].

	^ self
		formatTitle: title
		currentPanes: currentPanes
		undoEntries: undoEntries
		redoEntries: redoEntries
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> initialize [

	super initialize.
	maxHistoryEntries := 8
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> maxHistoryEntries [

	^ maxHistoryEntries
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> maxHistoryEntries: anInteger [

	maxHistoryEntries := (anInteger max: 1) min: 64
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> openBrowsersFrom: aBrowserClass [

	| all |
	all := aBrowserClass withAllSubclasses flatCollect: [ :each |
		[ each allInstances ] on: Error do: [ #() ] ].
	^ all select: [ :each |
		[ each window notNil and: [ each window isInWorld ] ]
			on: Error
			do: [ false ] ]
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> paneSelectionFromView: aViewOrViewState [

	| selection items |
	selection := [ aViewOrViewState selection ] on: Error do: [ nil ].
	items := (selection notNil and: [ selection respondsTo: #items ])
		ifTrue: [ [ selection items ] on: Error do: [ #() ] ]
		ifFalse: [ #() ].
	^ (items collect: [ :item |
		[ item name asString ] on: Error do: [ item printString ] ]) asArray
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> paneSelectionsFromBrowser: aBrowser [

	| views panes |
	views := [ aBrowser navigationViews ] on: Error do: [ #() ].
	panes := OrderedCollection new.
	views do: [ :view | panes add: (self paneSelectionFromView: view) ].
	^ panes asArray
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> paneSelectionsFromBrowserState: aBrowserState [

	| viewStates panes |
	viewStates := [ aBrowserState viewStates ] on: Error do: [ #() ].
	panes := OrderedCollection new.
	viewStates do: [ :viewState | panes add: (self paneSelectionFromView: viewState) ].
	^ panes asArray
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> paneSelectionsFromHistoryList: aList [

	| result |
	result := OrderedCollection new.
	aList do: [ :entry |
		| state panes |
		state := self browserStateFromHistoryEntry: entry.
		state ifNotNil: [
			panes := self paneSelectionsFromBrowserState: state.
			(self totalSelectionsIn: panes) > 0 ifTrue: [
				result add: panes ] ] ].

	^ result size > maxHistoryEntries
		ifTrue: [ (result last: maxHistoryEntries) asArray ]
		ifFalse: [ result asArray ]
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> totalSelectionsForBrowser: aBrowser [

	^ self totalSelectionsIn: (self paneSelectionsFromBrowser: aBrowser)
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> totalSelectionsIn: panes [

	^ panes inject: 0 into: [ :sum :pane | sum + pane size ]
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> writeEntries: entries on: aStream [

	entries do: [ :panes |
		aStream nextPutAll: '  - '.
		panes
			do: [ :names | aStream nextPutAll: (self formatNames: names) ]
			separatedBy: [ aStream nextPutAll: ' | ' ].
		aStream cr ]
]

{ #category : 'as yet unclassified' }
CoPCContextNavigationHistory >> writePanes: panes on: aStream [

	panes withIndexDo: [ :names :i |
		aStream
			nextPutAll: '  pane ';
			print: i;
			nextPutAll: ': ';
			nextPutAll: (self formatNames: names);
			cr ]
]
