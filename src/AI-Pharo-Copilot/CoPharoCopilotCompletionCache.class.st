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
	#category : 'AI-Pharo-Copilot-Cach',
	#package : 'AI-Pharo-Copilot',
	#tag : 'Cach'
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
	"Look up a cached completion. If found, evaluate aBlock with the cached value and return the result. Otherwise return nil."

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
	"Store a completion result in the cache. Evicts the least recently used entry if at capacity."

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
	"Remove all cached entries and reset statistics."

	entries removeAll.
	timestamps removeAll.
	clock := 0.
		oldestKey := nil.
	oldestTime := nil.
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> ensureCapacity [

	[ entries size >= maxSize and: [ timestamps notEmpty ] ] whileTrue: [
			(oldestKey notNil and: [ entries includesKey: oldestKey ])
				ifTrue: [
						entries removeKey: oldestKey ifAbsent: [ ].
						timestamps removeKey: oldestKey ifAbsent: [ ] ]
				ifFalse: [
						| scanOldestKey scanOldestTime |
						scanOldestKey := nil.
						scanOldestTime := SmallInteger maxVal.
						timestamps keysAndValuesDo: [ :k :t |
								t < scanOldestTime ifTrue: [
										scanOldestKey := k.
										scanOldestTime := t ] ].
						scanOldestKey ifNil: [ ^ self ].
						entries removeKey: scanOldestKey ifAbsent: [ ].
						timestamps removeKey: scanOldestKey ifAbsent: [ ] ].
			evictions := evictions + 1.
			oldestKey := nil.
			oldestTime := nil ]
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> evictions [

	^ evictions
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> hitRate [
	"Return the cache hit rate as a float between 0.0 and 1.0."

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
	maxSize := 64.
		oldestKey := nil.
	oldestTime := nil.
	self resetStats
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
	"Try a near-match: look up with the last character of the prefix removed.
	Useful when the user just typed one more character but the completion is still valid."

	| shorterPrefix |
	(prefixString size < 2) ifTrue: [ ^ nil ].
	shorterPrefix := prefixString copyFrom: 1 to: prefixString size - 1.
	^ self at: shorterPrefix suffix: suffixString context: contextString ifPresent: aBlock
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> resetStats [
	"Reset hit/miss/eviction counters without clearing cache entries."

	hits := 0.
	misses := 0.
	evictions := 0
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> size [

	^ entries size
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> statisticsDictionary [
	"Return a dictionary of cache performance statistics."

	^ Dictionary new
		at: #hits put: hits;
		at: #misses put: misses;
		at: #evictions put: evictions;
		at: #hitRate put: self hitRate;
		at: #size put: self size;
		at: #maxSize put: maxSize;
		yourself
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> touchKey: aKey [

	clock := clock + 1.
	timestamps at: aKey put: clock.
	(oldestTime isNil or: [ clock = 1 ]) ifFalse: [ ^ self ].
	oldestKey := aKey.
	oldestTime := clock
]
