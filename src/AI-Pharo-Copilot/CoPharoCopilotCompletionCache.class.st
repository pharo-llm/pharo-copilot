"
a cach
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

	| key value |
	key := self keyFor: prefixString suffix: suffixString context: contextString.
	value := entries at: key ifAbsent: [
		misses := misses + 1.
		^ nil ].
	hits := hits + 1.
	self touchKey: key.
	^ aBlock value: value
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> at: prefixString suffix: suffixString context: contextString put: aValue [

	| key |
	key := self keyFor: prefixString suffix: suffixString context: contextString.
	(entries includesKey: key) ifTrue: [
		entries at: key put: aValue.
		self touchKey: key.
		^ aValue ].
	self ensureCapacity.
	entries at: key put: aValue.
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
	hash := hash bitXor: (suffixString hash bitShift: -3).
	hash := hash bitXor: (contextString hash bitShift: -7).
	^ { hash. prefixString. suffixString. contextString }
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
