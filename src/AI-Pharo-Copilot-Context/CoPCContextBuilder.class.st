"
I build the class context string sent to the completion model.
I use a context strategy to render class methods and wrap the current prefix with FIM markers.
"
Class {
	#name : 'CoPCContextBuilder',
	#superclass : 'Object',
	#instVars : [
		'targetClass',
		'strategy'
	],
	#classInstVars : [
		'staticContextCache'
	],
	#category : 'AI-Pharo-Copilot-Context',
	#package : 'AI-Pharo-Copilot-Context'
}

{ #category : 'instance creation' }
CoPCContextBuilder class >> flushStaticContextCache [ 

	staticContextCache := nil
]

{ #category : 'instance creation' }
CoPCContextBuilder class >> forClass: aClass strategy: aStrategy [

	^ self new
		targetClass: aClass;
		strategy: aStrategy;
		yourself
]

{ #category : 'instance creation' }
CoPCContextBuilder class >> staticContextCache [

	^ staticContextCache ifNil: [ staticContextCache := Dictionary new ]
]

{ #category : 'building' }
CoPCContextBuilder >> buildForFIMWithPrefix: prefixString [

	^ self buildForFIMWithPrefix: prefixString suffix: ''
]

{ #category : 'building' }
CoPCContextBuilder >> buildForFIMWithPrefix: prefixString suffix: suffixString [

	| static |
	static := self cachedStaticContext.
	^ String streamContents: [ :s |
		s nextPutAll: static.
		self writeFIMOn: s prefix: prefixString suffix: suffixString ]
]

{ #category : 'building' }
CoPCContextBuilder >> cachedStaticContext [

	| cache key |
	cache := self class staticContextCache.
	key := self staticContextCacheKey.
	^ cache at: key ifAbsentPut: [ self renderStaticContext ]
]

{ #category : 'accessing' }
CoPCContextBuilder >> methodLabelFor: each [

	(each isKindOf: CompiledMethod)
		ifTrue: [ ^ each selector asString ].
	^ each asString
]

{ #category : 'building' }
CoPCContextBuilder >> renderStaticContext [
	"Render only the immutable part of the FIM context (header + methods). The FIM tail is
	composed per-request because it depends on the user prefix."

	^ String streamContents: [ :s |
		self writeRepoHeaderOn: s.
		self writeMethodsOn: s ]
]

{ #category : 'building' }
CoPCContextBuilder >> staticContextCacheKey [

	| dict |
	dict := targetClass methodDict.
	^ { targetClass. dict identityHash. dict size. strategy class name }
]

{ #category : 'accessing' }
CoPCContextBuilder >> strategy [

	^ strategy
]

{ #category : 'accessing' }
CoPCContextBuilder >> strategy: aStrategy [

	strategy := aStrategy
]

{ #category : 'accessing' }
CoPCContextBuilder >> targetClass [

	^ targetClass
]

{ #category : 'accessing' }
CoPCContextBuilder >> targetClass: aClass [

	targetClass := aClass
]

{ #category : 'accessing' }
CoPCContextBuilder >> writeFIMOn: aStream prefix: prefixString suffix: suffixString [
	"Exact Qwen FIM layout: no newlines between the markers and the code, otherwise the
	model believes the cursor sits on a fresh line."

	aStream
		nextPutAll: '<|fim_prefix|>';
		nextPutAll: (prefixString ifNil: [ '' ]);
		nextPutAll: '<|fim_suffix|>';
		nextPutAll: (suffixString ifNil: [ '' ]);
		nextPutAll: '<|fim_middle|>'
]

{ #category : 'accessing' }
CoPCContextBuilder >> writeMethodsOn: aStream [
	| methods |
	methods := strategy methodsFor: targetClass.

	methods do: [ :each |
		aStream
			nextPutAll: '<|file_sep|>';
			nextPutAll: (self methodLabelFor: each);
			nextPut: Character lf;
			nextPutAll: (strategy renderMethod: each);
			nextPut: Character lf
	]
]

{ #category : 'accessing' }
CoPCContextBuilder >> writeRepoHeaderOn: aStream [

	aStream
		nextPutAll: '<|repo_name|>';
		nextPutAll: targetClass name;
		nextPut: Character lf
]
