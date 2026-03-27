Class {
	#name : 'CoBenchmarkCacheScenario',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot-Benchmarks',
	#package : 'AI-Pharo-Copilot-Benchmarks'
}

{ #category : 'scenarios' }
CoBenchmarkCacheScenario class >> allScenarios [
	"Return all cache benchmark scenarios combined."

	| all |
	all := Dictionary new.
	all addAll: self cacheHitScenarios.
	all addAll: self cacheMissScenarios.
	all addAll: self cacheSizeScenarios.
	^ all
]

{ #category : 'scenarios' }
CoBenchmarkCacheScenario class >> cacheHitScenarios [
	"Scenarios where the same request is made twice to measure cache hit speed.
	 The first run populates the cache, subsequent runs should be cache hits."

	^ Dictionary new
		at: 'cache_hit_simple_accessor' put: (CoBenchmarkScenario
			named: 'cache_hit_simple_accessor'
			prefix: 'name
	^ '
			suffix: ''
			context: 'Object subclass: #Person
	instanceVariableNames: ''name age email''
Person >> age
	^ age'
			description: 'Cache hit test: simple accessor repeated');
		at: 'cache_hit_method_body' put: (CoBenchmarkScenario
			named: 'cache_hit_method_body'
			prefix: 'initialize
	super initialize.
	'
			suffix: ''
			context: 'Object subclass: #CacheTarget
	instanceVariableNames: ''data cache config''
CacheTarget >> data
	^ data
CacheTarget >> cache
	^ cache'
			description: 'Cache hit test: method body repeated');
		at: 'cache_hit_large_context' put: (CoBenchmarkScenario
			named: 'cache_hit_large_context'
			prefix: 'visitNode: aNode
	"Visit an AST node and collect metrics"
	'
			suffix: ''
			context: (CoBenchmarkContextScenario realisticClassContext)
			description: 'Cache hit test: large context repeated');
		yourself
]

{ #category : 'scenarios' }
CoBenchmarkCacheScenario class >> cacheMissScenarios [
	"Scenarios with unique prefixes to force cache misses."

	| scenarios |
	scenarios := Dictionary new.
	1 to: 3 do: [ :i |
		| name prefix |
		name := 'cache_miss_unique_', i asString.
		prefix := 'uniqueMethod', i asString, '
	"Method variant ', i asString, '"
	'.
		scenarios at: name put: (CoBenchmarkScenario
			named: name
			prefix: prefix
			suffix: ''
			context: 'Object subclass: #CacheMissTarget
	instanceVariableNames: ''x y z''
CacheMissTarget >> x
	^ x'
			description: 'Cache miss test: unique request ', i asString) ].
	^ scenarios
]

{ #category : 'scenarios' }
CoBenchmarkCacheScenario class >> cacheSizeScenarios [
	"Scenarios for benchmarking different cache size configurations."

	| sizes scenarios |
	sizes := #(8 32 64 128 256).
	scenarios := Dictionary new.
	sizes do: [ :size |
		| name |
		name := 'cache_size_', size asString.
		scenarios at: name put: (CoBenchmarkScenario
			named: name
			prefix: 'processItem: anItem
	"Process a single item from the queue"
	'
			suffix: ''
			context: 'Object subclass: #CacheSizeTarget
	instanceVariableNames: ''items processed''
CacheSizeTarget >> items
	^ items
CacheSizeTarget >> processed
	^ processed
CacheSizeTarget >> addItem: anItem
	items add: anItem'
			description: 'Cache size test: maxSize=', size asString) ].
	^ scenarios
]
