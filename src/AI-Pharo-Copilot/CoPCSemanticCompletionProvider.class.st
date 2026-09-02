"
Compatibility shell for the former local semantic completion lane.
Complishon-backed entries are disabled so Copilot suggestions stay model-only.
"
Class {
	#name : 'CoPCSemanticCompletionProvider',
	#superclass : 'Object',
	#instVars : [
		'builder',
		'limit',
		'lastLocationKey',
		'lastResultSet',
		'entryCache'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'initialization' }
CoPCSemanticCompletionProvider >> initialize [

	super initialize.
	limit := 10
]

{ #category : 'accessing' }
CoPCSemanticCompletionProvider >> builder [

	^ builder
]

{ #category : 'accessing' }
CoPCSemanticCompletionProvider >> builder: aBuilder [

	builder := aBuilder
]

{ #category : 'completion' }
CoPCSemanticCompletionProvider >> cacheEntries: entries locationKey: locationKey token: tokenString [

	| key cache |
	cache := self entryCache.
	key := self entryCacheKeyForLocationKey: locationKey token: tokenString.
	cache at: key put: entries.
	cache size > 64 ifTrue: [ cache removeAll ].
	^ entries
]

{ #category : 'completion' }
CoPCSemanticCompletionProvider >> entriesFor: aContext [

	^ #()
]

{ #category : 'completion' }
CoPCSemanticCompletionProvider >> entryCache [

	^ entryCache ifNil: [
		entryCache := Dictionary new ]
]

{ #category : 'completion' }
CoPCSemanticCompletionProvider >> entryCacheKeyForLocationKey: locationKey token: tokenString [

	^ {
		locationKey.
		tokenString ifNil: [ '' ] ifNotNil: [ tokenString asString ] }
]

{ #category : 'accessing' }
CoPCSemanticCompletionProvider >> limit [

	^ limit ifNil: [ 10 ]
]

{ #category : 'accessing' }
CoPCSemanticCompletionProvider >> limit: anInteger [

	limit := (anInteger ifNil: [ 10 ]) max: 0
]

{ #category : 'completion' }
CoPCSemanticCompletionProvider >> locationKeyFor: aContext [

	| source position prefix token base receiver behavior selector |
	source := [
		aContext source ifNil: [ '' ] ]
		on: Error
		do: [ '' ].
	position := [
		aContext position ifNil: [ source size ] ]
		on: Error
		do: [ source size ].
	position := (position max: 0) min: source size.
	prefix := position = 0
		ifTrue: [ '' ]
		ifFalse: [ source copyFrom: 1 to: position ].

	token := self tokenFor: aContext prefix: prefix.
	base := prefix.
	(token isEmpty not and: [ base size >= token size ]) ifTrue: [
		((base copyFrom: base size - token size + 1 to: base size) = token)
			ifTrue: [
				base := base size = token size
					ifTrue: [ '' ]
					ifFalse: [ base copyFrom: 1 to: base size - token size ] ] ].

	receiver := self receiverFor: aContext prefix: prefix.
	behavior := builder
		ifNil: [ nil ]
		ifNotNil: [ [ builder behaviorFor: aContext ] on: Error do: [ nil ] ].
	selector := builder
		ifNil: [ nil ]
		ifNotNil: [ [ builder selectorFromPrefix: prefix ] on: Error do: [ nil ] ].

	^ {
		behavior.
		selector.
		receiver.
		base }
]

{ #category : 'completion' }
CoPCSemanticCompletionProvider >> rankedEntries: entryCollection [

	| scores |
	entryCollection ifNil: [ ^ #() ].
	entryCollection isEmpty ifTrue: [ ^ entryCollection ].

	scores := Dictionary new.
	entryCollection do: [ :entry |
		scores at: entry put: (self scoreEntry: entry) ].
	(scores values anySatisfy: [ :each | each ~= 0 ]) ifFalse: [
		^ entryCollection ].

	^ entryCollection sorted: [ :a :b |
		(scores at: a ifAbsent: [ 0 ]) > (scores at: b ifAbsent: [ 0 ]) ]
]

{ #category : 'completion' }
CoPCSemanticCompletionProvider >> receiverFor: aContext prefix: prefixString [

	builder ifNil: [ ^ '' ].
	^ [
		builder textualReceiverBeforeCompletionIn: prefixString ]
		on: Error
		do: [ '' ]
]

{ #category : 'completion' }
CoPCSemanticCompletionProvider >> resultSetFor: aContext locationKey: locationKey token: tokenString [

	^ nil
]

{ #category : 'completion' }
CoPCSemanticCompletionProvider >> scoreEntry: anEntry [

	| tracker contents |
	tracker := Smalltalk globals
		at: #CoAdHocUsageTracker
		ifAbsent: [ ^ 0 ].
	contents := [
		(anEntry respondsTo: #contents)
			ifTrue: [ anEntry contents asString ]
			ifFalse: [ anEntry asString ] ]
		on: Error
		do: [ ^ 0 ].
	contents isEmpty ifTrue: [ ^ 0 ].

	^ [
		(tracker respondsTo: #usageCountFor:)
			ifTrue: [ tracker usageCountFor: contents ]
			ifFalse: [ 0 ] ]
		on: Error
		do: [ 0 ]
]

{ #category : 'completion' }
CoPCSemanticCompletionProvider >> tokenFor: aContext locationKey: locationKey [

	| base token |
	locationKey ifNil: [ ^ '' ].
	base := locationKey size >= 4
		ifTrue: [ locationKey at: 4 ]
		ifFalse: [ '' ].
	token := self tokenFor: aContext prefix: base.
	token isEmpty ifTrue: [
		| source position prefix |
		source := [ aContext source ifNil: [ '' ] ] on: Error do: [ '' ].
		position := [ aContext position ifNil: [ source size ] ] on: Error do: [ source size ].
		position := (position max: 0) min: source size.
		prefix := position = 0
			ifTrue: [ '' ]
			ifFalse: [ source copyFrom: 1 to: position ].
		^ self tokenFor: aContext prefix: prefix ].
	^ token
]

{ #category : 'completion' }
CoPCSemanticCompletionProvider >> tokenFor: aContext prefix: prefixString [

	builder ifNil: [ ^ '' ].
	^ [
		builder completionTokenFor: aContext prefix: prefixString ]
		on: Error
		do: [ '' ]
]
