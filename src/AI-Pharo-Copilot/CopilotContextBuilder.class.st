Class {
	#name : 'CopilotContextBuilder',
	#superclass : 'Object',
	#instVars : [
		'targetClass',
		'strategy'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'instance creation' }
CopilotContextBuilder class >> forClass: aClass strategy: aStrategy [

	^ self new
		targetClass: aClass;
		strategy: aStrategy;
		yourself
]

{ #category : 'building' }
CopilotContextBuilder >> buildForFIMWithPrefix: prefixString [

	| stream |
	stream := String streamContents: [ :s |
		self writeRepoHeaderOn: s.
		self writeMethodsOn: s.
		self writeFIMOn: s prefix: prefixString
	].
	^ stream
]

{ #category : 'accessing' }
CopilotContextBuilder >> methodLabelFor: each [

	(each isKindOf: CompiledMethod)
		ifTrue: [ ^ each selector asString ].
	^ each asString
]

{ #category : 'accessing' }
CopilotContextBuilder >> strategy [

	^ strategy
]

{ #category : 'accessing' }
CopilotContextBuilder >> strategy: aStrategy [

	strategy := aStrategy
]

{ #category : 'accessing' }
CopilotContextBuilder >> targetClass [

	^ targetClass
]

{ #category : 'accessing' }
CopilotContextBuilder >> targetClass: aClass [

	targetClass := aClass
]

{ #category : 'accessing' }
CopilotContextBuilder >> writeFIMOn: aStream prefix: prefixString [

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
CopilotContextBuilder >> writeMethodsOn: aStream [
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
CopilotContextBuilder >> writeRepoHeaderOn: aStream [

	aStream
		nextPutAll: '<|repo_name|>';
		nextPutAll: targetClass name;
		cr;
		cr
]
