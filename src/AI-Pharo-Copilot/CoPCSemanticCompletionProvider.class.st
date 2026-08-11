"
Thin adapter around Complishon's AST heuristic completion builder.
This is the local semantic lane for Pharo Copilot; callers should not reach
directly into CoASTHeuristicsResultSetBuilder unless they need compatibility.
"
Class {
	#name : 'CoPCSemanticCompletionProvider',
	#superclass : 'Object',
	#instVars : [
		'builder',
		'limit'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'initialization' }
CoPCSemanticCompletionProvider >> initialize [

	super initialize.
	limit := 10
]

{ #category : 'accessing' }
CoPCSemanticCompletionProvider >> builder [

	^ builder
]

{ #category : 'accessing' }
CoPCSemanticCompletionProvider >> builder: aBuilder [

	builder := aBuilder
]

{ #category : 'completion' }
CoPCSemanticCompletionProvider >> entriesFor: aContext [

	| result count entries |
	result := [
		(CoASTHeuristicsResultSetBuilder initializeOnContext: aContext)
			buildCompletion ]
		on: Error
		do: [ nil ].
	result ifNil: [ ^ #() ].

	count := self limit.
	entries := [ result first: count ]
		on: Error
		do: [ #() ].
	^ self rankedEntries: entries
]

{ #category : 'accessing' }
CoPCSemanticCompletionProvider >> limit [

	^ limit ifNil: [ 10 ]
]

{ #category : 'accessing' }
CoPCSemanticCompletionProvider >> limit: anInteger [

	limit := (anInteger ifNil: [ 10 ]) max: 0
]

{ #category : 'completion' }
CoPCSemanticCompletionProvider >> rankedEntries: entryCollection [

	| scores |
	entryCollection ifNil: [ ^ #() ].
	entryCollection isEmpty ifTrue: [ ^ entryCollection ].

	scores := Dictionary new.
	entryCollection do: [ :entry |
		scores at: entry put: (self scoreEntry: entry) ].
	(scores values anySatisfy: [ :each | each ~= 0 ]) ifFalse: [
		^ entryCollection ].

	^ entryCollection sorted: [ :a :b |
		(scores at: a ifAbsent: [ 0 ]) > (scores at: b ifAbsent: [ 0 ]) ]
]

{ #category : 'completion' }
CoPCSemanticCompletionProvider >> scoreEntry: anEntry [

	| tracker contents |
	tracker := Smalltalk globals
		at: #CoAdHocUsageTracker
		ifAbsent: [ ^ 0 ].
	contents := [
		(anEntry respondsTo: #contents)
			ifTrue: [ anEntry contents asString ]
			ifFalse: [ anEntry asString ] ]
		on: Error
		do: [ ^ 0 ].
	contents isEmpty ifTrue: [ ^ 0 ].

	^ [
		(tracker respondsTo: #usageCountFor:)
			ifTrue: [ tracker usageCountFor: contents ]
			ifFalse: [ 0 ] ]
		on: Error
		do: [ 0 ]
]
