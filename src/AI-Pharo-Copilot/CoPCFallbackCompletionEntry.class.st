Class {
	#name : 'CoPCFallbackCompletionEntry',
	#superclass : 'Object',
	#instVars : [
		'entry',
		'sessionId'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'instance creation' }
CoPCFallbackCompletionEntry class >> on: anEntry [

	^ self new
		entry: anEntry;
		yourself
]

{ #category : 'actions' }
CoPCFallbackCompletionEntry >> activateOn: aCompletionContext [
	"Delegate insertion to the original Complishon entry so token replacement,
	keyword spacing, usage tracking, etc. keep their normal behavior."

	| applied |
	applied := entry activateOn: aCompletionContext.
	(applied = true and: [ self sessionId notNil ]) ifTrue: [
		[ CoPharoCopilotLogger
			updateCompletionSession: self sessionId
			withAccepted: self contents ]
			on: Error
			do: [ :ex | ] ].
	^ applied
]

{ #category : 'actions' }
CoPCFallbackCompletionEntry >> contents [

	^ [
		(entry respondsTo: #contents)
			ifTrue: [ entry contents asString ]
			ifFalse: [ entry asString ] ]
		on: Error
		do: [ '' ]
]

{ #category : 'actions' }
CoPCFallbackCompletionEntry >> description [

	| kind source |
	kind := [ entry label asString ] on: Error do: [ '' ].
	source := [ entry fetcherName asString ] on: Error do: [ '' ].

	^ String streamContents: [ :stream |
		stream nextPutAll: 'Local Complishon completion'.
		kind isEmpty ifFalse: [
			stream cr; nextPutAll: 'Kind: '; nextPutAll: kind ].
		source isEmpty ifFalse: [
			stream cr; nextPutAll: 'Source: '; nextPutAll: source ] ]
]

{ #category : 'actions' }
CoPCFallbackCompletionEntry >> displayString [

	^ self contents
]

{ #category : 'actions' }
CoPCFallbackCompletionEntry >> entry [

	^ entry
]

{ #category : 'actions' }
CoPCFallbackCompletionEntry >> entry: anEntry [

	entry := anEntry
]

{ #category : 'actions' }
CoPCFallbackCompletionEntry >> label [

	^ self contents
]

{ #category : 'actions' }
CoPCFallbackCompletionEntry >> sessionId [

	^ sessionId
]

{ #category : 'actions' }
CoPCFallbackCompletionEntry >> sessionId: aString [

	sessionId := aString
]
