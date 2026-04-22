"
Light result set builder:
  1. Reads prefix/suffix from the completion context
  2. Debounces
  3. Calls the Ollama client (FIM template or native FIM API)
  4. Displays returned suggestions in the Copilot menu
No cleaning, no filtering, no cache, no logging.
"
Class {
	#name : 'CoPharoCopilotResultSetBuilder',
	#superclass : 'CoResultSetBuilder',
	#instVars : [
		'debounceProcess',
		'debounceToken',
		'menuMorph',
		'cachedClient'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'instance creation' }
CoPharoCopilotResultSetBuilder class >> initializeOnContext: aSystemCompletionContext [

	^ self new
		initializeOnContext: aSystemCompletionContext;
		yourself
]

{ #category : 'initialization' }
CoPharoCopilotResultSetBuilder >> initialize [

	super initialize.
	debounceToken := 0
]

{ #category : 'initialization' }
CoPharoCopilotResultSetBuilder >> initializeOnContext: aSystemCompletionContext [

	completionContext := aSystemCompletionContext
]

{ #category : 'accessing' }
CoPharoCopilotResultSetBuilder >> ollamaClient [

	^ cachedClient ifNil: [ cachedClient := CoPCOllamaClient new ]
]

{ #category : 'API - building' }
CoPharoCopilotResultSetBuilder >> buildCompletion [

	| context source position prefix suffix |
	context := completionContext.
	context ifNil: [ ^ self emptyResultSet ].

	source := [ context source ifNil: [ '' ] ] on: Error do: [ '' ].
	position := [ context position ifNil: [ 0 ] ] on: Error do: [ 0 ].
	position := (position max: 0) min: source size.

	(position < CopilotSettings minimumPrefixLength) ifTrue: [ ^ self emptyResultSet ].

	prefix := position > 0
		ifTrue: [ source copyFrom: 1 to: position ]
		ifFalse: [ '' ].
	suffix := position < source size
		ifTrue: [ source copyFrom: position + 1 to: source size ]
		ifFalse: [ '' ].

	self
		scheduleCompletionFor: context
		prefix: prefix
		suffix: suffix.

	^ self emptyResultSet
]

{ #category : 'new' }
CoPharoCopilotResultSetBuilder >> emptyResultSet [

	^ CoResultSet fetcher: (CoCollectionFetcher onCollection: #())
]

{ #category : 'scheduling' }
CoPharoCopilotResultSetBuilder >> scheduleCompletionFor: aContext prefix: prefixString suffix: suffixString [
	"Debounce: cancel any pending request, keep only the most recent."

	| token delayMs |
	debounceToken := debounceToken + 1.
	token := debounceToken.

	debounceProcess ifNotNil: [ debounceProcess terminate ].

	delayMs := CopilotSettings completionDebounceMilliseconds.

	debounceProcess := [
		(Delay forMilliseconds: delayMs) wait.
		token = debounceToken ifTrue: [
			self
				processCompletionFor: aContext
				prefix: prefixString
				suffix: suffixString ] ]
		forkAt: Processor userSchedulingPriority
]

{ #category : 'new' }
CoPharoCopilotResultSetBuilder >> processCompletionFor: aContext prefix: prefixString suffix: suffixString [

	| classContext suggestions entries |
	classContext := self classContextFor: aContext.

	suggestions := self
		fetchSuggestionsForPrefix: prefixString
		suffix: suffixString
		context: classContext.

	suggestions isEmpty ifTrue: [ ^ self ].

	entries := suggestions collect: [ :each |
		CoCopilotEntry contents: each asString ].

	self openCompletionMenuFor: aContext entries: entries
]

{ #category : 'new' }
CoPharoCopilotResultSetBuilder >> fetchSuggestionsForPrefix: prefixString suffix: suffixString context: classContext [
	"Ask the Ollama client for N suggestions. No cleaning, no deduplication."

	| count client collected |
	client := self ollamaClient.
	count := CopilotSettings completionSuggestionsCount.
	collected := OrderedCollection new.

	1 to: count do: [ :i |
		| raw |
		raw := [ client generateForPrefix: prefixString suffix: suffixString context: classContext ]
			on: Error do: [ :ex | '' ].
		(raw notNil and: [ raw asString isEmpty not ])
			ifTrue: [ collected add: raw asString ] ].

	^ collected asArray
]

{ #category : 'new' }
CoPharoCopilotResultSetBuilder >> classContextFor: aContext [
	"Very small class context: just the class definition.
	 Removed: selector extraction, method window, caching, strategies."

	| behavior |
	aContext ifNil: [ ^ '' ].

	behavior := (aContext respondsTo: #completionClass)
		ifTrue: [ [ aContext completionClass ] on: Error do: [ nil ] ]
		ifFalse: [
			(aContext respondsTo: #behavior)
				ifTrue: [ [ aContext behavior ] on: Error do: [ nil ] ]
				ifFalse: [ nil ] ].

	behavior ifNil: [ ^ '' ].
	^ [ behavior definition asString ] on: Error do: [ '' ]
]

{ #category : 'menu' }
CoPharoCopilotResultSetBuilder >> openCompletionMenuFor: aContext entries: entries [

	| position |
	position := self menuPositionFor: aContext.

	self deferUI: [
		self closeMenu.
		menuMorph := CopilotMenuMorph
			builder: self
			context: aContext
			entries: entries
			position: position.
		(menuMorph respondsTo: #takeKeyboardFocus)
			ifTrue: [ menuMorph takeKeyboardFocus ] ]
]

{ #category : 'menu' }
CoPharoCopilotResultSetBuilder >> menuPositionFor: aContext [

	| engine editor token |
	engine := [ aContext engine ] on: Error do: [ nil ].
	engine ifNil: [ ^ 200 @ 200 ].

	editor := [ engine editor ] on: Error do: [ nil ].
	editor ifNil: [ ^ 200 @ 200 ].

	token := [ engine completionToken ] on: Error do: [ '' ].

	^ [ editor selectionPosition: token ] on: Error do: [ 200 @ 200 ]
]

{ #category : 'menu' }
CoPharoCopilotResultSetBuilder >> closeMenu [

	menuMorph ifNotNil: [
		menuMorph isClosed ifFalse: [ menuMorph delete ].
		menuMorph := nil ]
]

{ #category : 'menu' }
CoPharoCopilotResultSetBuilder >> menuClosed [

	menuMorph := nil
]

{ #category : 'private' }
CoPharoCopilotResultSetBuilder >> deferUI: aBlock [
	"Run UI work on Morphic's deferred UI queue when possible."

	| worldStateClass uiClass ui |
	worldStateClass := Smalltalk globals at: #WorldState ifAbsent: [ nil ].
	(worldStateClass notNil and: [ worldStateClass respondsTo: #addDeferredUIMessage: ])
		ifTrue: [ ^ worldStateClass addDeferredUIMessage: aBlock ].

	uiClass := Smalltalk globals at: #UIManager ifAbsent: [ nil ].
	(uiClass notNil and: [ uiClass respondsTo: #default ]) ifTrue: [
		ui := uiClass default.
		(ui respondsTo: #defer:) ifTrue: [ ^ ui defer: aBlock ] ].

	^ aBlock value
]
