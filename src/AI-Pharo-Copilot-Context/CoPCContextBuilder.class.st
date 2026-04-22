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
	#category : 'AI-Pharo-Copilot-Context',
	#package : 'AI-Pharo-Copilot-Context'
}

{ #category : 'instance creation' }
CoPCContextBuilder class >> forClass: aClass strategy: aStrategy [

	^ self new
		targetClass: aClass;
		strategy: aStrategy;
		yourself
]

{ #category : 'building' }
CoPCContextBuilder >> buildForFIMWithPrefix: prefixString [

	| stream |
	stream := String streamContents: [ :s |
		self writeRepoHeaderOn: s.
		self writeMethodsOn: s.
		self writeFIMOn: s prefix: prefixString
	].
	^ stream
]

{ #category : 'accessing' }
CoPCContextBuilder >> methodLabelFor: each [

	(each isKindOf: CompiledMethod)
		ifTrue: [ ^ each selector asString ].
	^ each asString
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
CoPCContextBuilder >> writeFIMOn: aStream prefix: prefixString [

	aStream
		nextPutAll: '<|fim_prefix|>';
		cr;
		nextPutAll: prefixString;
		cr;
		nextPutAll: '<|fim_suffix|>';
		cr;
		nextPutAll: '<|fim_middle|>'
]

{ #category : 'accessing' }
CoPCContextBuilder >> writeMethodsOn: aStream [
	| methods |
	methods := strategy methodsFor: targetClass.

	methods do: [ :each |
		aStream
			nextPutAll: '<|file_sep|> ';
			nextPutAll: (self methodLabelFor: each);
			cr;
			nextPutAll: (strategy renderMethod: each);
			cr;
			cr
	]
]

{ #category : 'accessing' }
CoPCContextBuilder >> writeRepoHeaderOn: aStream [

	aStream
		nextPutAll: '<|repo_name|>';
		nextPutAll: targetClass name;
		cr;
		cr
]
