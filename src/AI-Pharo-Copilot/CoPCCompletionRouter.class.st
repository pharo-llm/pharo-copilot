"
Classifies the current completion location into a small set of routes.
The router is intentionally conservative; deeper AST routing can replace these
textual checks later without changing the builder's control flow.
"
Class {
	#name : 'CoPCCompletionRouter',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'routing' }
CoPCCompletionRouter >> classifyContext: aContext builder: builder [

	| snapshot |
	(aContext isNil or: [ builder isNil ]) ifTrue: [ ^ #unknown ].

	snapshot := builder contextSnapshotFor: aContext.
	^ self
		classifyContext: aContext
		prefix: (snapshot at: #prefix ifAbsent: [ '' ])
		builder: builder
]

{ #category : 'routing' }
CoPCCompletionRouter >> classifyContext: aContext prefix: prefixString builder: builder [

	| token receiver |
	builder ifNil: [ ^ #unknown ].

	token := builder completionTokenFor: aContext prefix: prefixString.
	receiver := builder textualReceiverBeforeCompletionIn: prefixString.
	(receiver isEmpty not and: [ receiver ~= token ]) ifTrue: [
		^ #selector ].

	token isEmpty not ifTrue: [ ^ #variable ].
	^ #statement
]
