Class {
	#name : 'CoPharoCopilotCompletionCache',
	#superclass : 'Object',
	#instVars : [
		'entries',
		'accessOrder',
		'maxSize',
		'hits',
		'misses',
		'evictions'
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
	accessOrder addLast: key.
	^ aValue
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> clear [
	"Remove all cached entries and reset statistics."

	entries removeAll.
	accessOrder removeAll.
	self resetStats
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> ensureCapacity [
	"Evict the least recently used entry if the cache is at capacity."

	[ entries size >= maxSize and: [ accessOrder notEmpty ] ] whileTrue: [
		| oldestKey |
		oldestKey := accessOrder removeFirst.
		entries removeKey: oldestKey ifAbsent: [ ].
		evictions := evictions + 1 ]
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

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> initialize [

	super initialize.
	entries := Dictionary new.
	accessOrder := OrderedCollection new.
	maxSize := 128.
	self resetStats
]

{ #category : 'accessing' }
CoPharoCopilotCompletionCache >> keyFor: prefixString suffix: suffixString context: contextString [
	"Compute a cache key from the three inputs."

	^ (prefixString , '|||' , suffixString , '|||' , contextString) hash
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
	"Move a key to the end of the access order (most recently used)."

	accessOrder remove: aKey ifAbsent: [ ].
	accessOrder addLast: aKey
]
