"
I provide a small, bounded summary of the most recent code changes
recorded by Epicea.

I deliberately use Epicea's log API instead of reading Ombu files
directly. The resulting context is intended as a lightweight recency
signal for code completion.
"
Class {
	#name : 'CoPCRecentCodeChanges',
	#superclass : 'Object',
	#instVars : [
		'log',
		'limit'
	],
	#category : 'AI-Pharo-Copilot-Context',
	#package : 'AI-Pharo-Copilot',
	#tag : 'Context'
}

{ #category : 'formatting' }
CoPCRecentCodeChanges >> formatChange: aChange [

	^ String streamContents: [ :stream |
		stream
			nextPutAll: aChange class name asString;
			nextPutAll: ': '.

		aChange isEpMethodChange
			ifTrue: [
				stream
					nextPutAll: aChange behaviorAffectedName asString;
					nextPutAll: '>>';
					nextPutAll: aChange methodAffectedSelector asString ]
			ifFalse: [
				stream nextPutAll: aChange affectedName asString ].

		[
			| packageName |
			packageName := aChange affectedPackageName.
			packageName ifNotNil: [
				packageName asString isEmpty ifFalse: [
					stream
						nextPutAll: ' [';
						nextPutAll: packageName asString;
						nextPut: $] ] ] ]
			on: Error
			do: [ :ignored | ] ]
]

{ #category : 'formatting' }
CoPCRecentCodeChanges >> gather [

	^ [
		| changes |
		changes := self recentChanges.
		changes isEmpty ifTrue: [ '' ] ifFalse: [
			String streamContents: [ :stream |
				changes
					do: [ :change |
						stream nextPutAll: (self formatChange: change) ]
					separatedBy: [
						stream nextPut: Character lf ] ] ] ]
		on: Error
		do: [ :ignored | '' ]
]

{ #category : 'initialization' }
CoPCRecentCodeChanges >> initialize [

	super initialize.
	limit := 5
]

{ #category : 'accessing' }
CoPCRecentCodeChanges >> limit [

	^ limit
]

{ #category : 'accessing' }
CoPCRecentCodeChanges >> limit: anInteger [

	limit := (anInteger max: 1) min: 20
]

{ #category : 'accessing' }
CoPCRecentCodeChanges >> log [

	| monitorClass |
	log ifNotNil: [ ^ log ].

	monitorClass := Smalltalk globals at: #EpMonitor ifAbsent: [ ^ nil ].
	([ monitorClass hasCurrent ] on: Error do: [ false ]) ifFalse: [ ^ nil ].

	^ [ monitorClass current log ] on: Error do: [ nil ]
]

{ #category : 'accessing' }
CoPCRecentCodeChanges >> log: anEpLog [

	log := anEpLog
]

{ #category : 'collecting' }
CoPCRecentCodeChanges >> recentChanges [

	| currentLog reference changes |
	currentLog := self log.
	currentLog ifNil: [ ^ #() ].

	changes := OrderedCollection new.
	reference := currentLog headReference.

	[
		reference isNull or: [
			changes size >= limit ] ]
		whileFalse: [
			currentLog
				entryFor: reference
				ifPresent: [ :entry |
					entry content isCodeChange ifTrue: [
						changes add: entry content ].
					reference := currentLog priorReferenceAt: entry ]
				ifAbsent: [
					reference := currentLog nullReference ] ].

	^ changes asArray
]
