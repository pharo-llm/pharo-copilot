"
I cache completion suggestions keyed by prefix/suffix/classContext hash.
Supports LRU eviction, near-match lookups, and hit-rate statistics.
"
Class {
	#name : 'CoPharoCopilotCompletionCache',
	#superclass : 'Object',
	#instVars : [
		'entries',
		'timestamps',
		'clock',
		'maxSize',
		'hits',
		'misses',
		'evictions',
		'oldestKey',
		'oldestTime'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'instance creation' }
CoPharoCopilotCompletionCache class >> new [

	^ super new initialize
]

{ #category : 'instance creation' }
CoPharoCopilotCompletionCache class >> withMaxSize: anInteger [

	^ self new maxSize: anInteger

]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> at: prefixString suffix: suffixString context: contextString ifPresent: aBlock [
| key entry |
	key := self keyFor: prefixString suffix: suffixString context: contextString.
	entry := entries at: key ifAbsent: [ nil ].
	(entry notNil and: [ self entry: entry matchesPrefix: prefixString suffix: suffixString context: contextString ])
		ifFalse: [
			misses := misses + 1.
			^ nil ].
	hits := hits + 1.
	self touchKey: key.
	^ aBlock value: (entry at: 4)
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> at: prefixString suffix: suffixString context: contextString put: aValue [

| key entry existing |
	key := self keyFor: prefixString suffix: suffixString context: contextString.
	entry := { prefixString. suffixString. contextString. aValue }.
	existing := entries at: key ifAbsent: [ nil ].
	(existing notNil and: [ self entry: existing matchesPrefix: prefixString suffix: suffixString context: contextString ])
		ifTrue: [
			entries at: key put: entry.
			self touchKey: key.
			^ aValue ].

	existing ifNil: [ self ensureCapacity ].
	entries at: key put: entry.
	self touchKey: key.
	^ aValue
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> clear [

	entries removeAll.
	timestamps removeAll.
	clock := 0.
	oldestKey := nil.
	oldestTime := nil.
]

{ #category : 'new' }
CoPharoCopilotCompletionCache >> ensureCapacity [

	[ self isAtCapacity ] whileTrue: [
		self evictOldestEntry
	]
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> entry: anEntry matchesPrefix: prefixString suffix: suffixString context: contextString [
	"Identity-first equality (cheap when the same string instances are reused), falling back
	to value equality. Guards integer-hash key collisions."

	| eP eS eC |
	eP := anEntry at: 1.
	eS := anEntry at: 2.
	eC := anEntry at: 3.
	^ ((eP == prefixString or: [ eP = prefixString ])
		and: [ eS == suffixString or: [ eS = suffixString ] ])
		and: [ eC == contextString or: [ eC = contextString ] ]
]

{ #category : 'new' }
CoPharoCopilotCompletionCache >> evictOldestEntry [

	| keyToEvict |
	keyToEvict := self oldestExistingKey.
	keyToEvict ifNil: [ ^ self ].

	entries removeKey: keyToEvict ifAbsent: [ ].
	timestamps removeKey: keyToEvict ifAbsent: [ ].
	evictions := evictions + 1.

	self resetOldestTracking
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> evictions [

	^ evictions
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> hitRate [

	| total |
	total := hits + misses.
	total = 0 ifTrue: [ ^ 0.0 ].
	^ hits / total asFloat
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> hits [

	^ hits
]

{ #category : 'initialization' }
CoPharoCopilotCompletionCache >> initialize [

    super initialize.
    entries := Dictionary new.
    timestamps := Dictionary new.
    clock := 0.
    maxSize := 512.
    oldestKey := nil.
    oldestTime := nil.
    self resetStats
]

{ #category : 'new' }
CoPharoCopilotCompletionCache >> isAtCapacity [

	^ entries size >= maxSize and: [ timestamps notEmpty ]
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> keyFor: prefixString suffix: suffixString context: contextString [

	| hash |
	hash := prefixString hash.
	hash := (hash hashMultiply bitXor: suffixString hash) hashMultiply.
	^ hash bitXor: contextString hash
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> maxSize [

	^ maxSize
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> maxSize: anInteger [

	maxSize := anInteger max: 1
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> misses [

	^ misses
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> nearMatchAt: prefixString suffix: suffixString context: contextString ifPresent: aBlock [

	| shorterPrefix |
	prefixString size < 2 ifTrue: [ ^ nil ].
	shorterPrefix := prefixString copyFrom: 1 to: prefixString size - 1.
	^ self
		  at: shorterPrefix
		  suffix: suffixString
		  context: contextString
		  ifPresent: aBlock
]

{ #category : 'new' }
CoPharoCopilotCompletionCache >> oldestExistingKey [

	(oldestKey notNil and: [ entries includesKey: oldestKey ]) ifTrue: [
		^ oldestKey
	].

	^ self scanOldestKey
]

{ #category : 'new' }
CoPharoCopilotCompletionCache >> resetOldestTracking [ 

	oldestKey := nil.
	oldestTime := nil
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> resetStats [

	hits := 0.
	misses := 0.
	evictions := 0
]

{ #category : 'new' }
CoPharoCopilotCompletionCache >> scanOldestKey [

	| scanOldestKey scanOldestTime |
	scanOldestKey := nil.
	scanOldestTime := SmallInteger maxVal.

	timestamps keysAndValuesDo: [ :key :time |
		time < scanOldestTime ifTrue: [
			scanOldestKey := key.
			scanOldestTime := time
		]
	].

	oldestKey := scanOldestKey.
	oldestTime := scanOldestTime = SmallInteger maxVal
		ifTrue: [ nil ]
		ifFalse: [ scanOldestTime ].

	^ scanOldestKey
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> size [

	^ entries size
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> statisticsDictionary [

	^ Dictionary new
		  at: #hits put: hits;
		  at: #misses put: misses;
		  at: #evictions put: evictions;
		  at: #hitRate put: self hitRate;
		  at: #size put: self size;
		  at: #maxSize put: maxSize;
		  yourself
]

{ #category : 'new' }
CoPharoCopilotCompletionCache >> touchKey: aKey [

	clock := clock + 1.
	timestamps at: aKey put: clock.

	(oldestKey isNil or: [ oldestTime isNil ]) ifFalse: [ ^ self ].
	oldestKey := aKey.
	oldestTime := clock
]
