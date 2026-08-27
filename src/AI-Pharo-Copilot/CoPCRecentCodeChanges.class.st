"
I provide a small, bounded summary of the most recent code changes
recorded by Epicea.

I use Epicea's log API instead of reading Ombu files directly. The resulting
context is intended as a lightweight recency signal for code completion.
"
Class {
	#name : 'CoPCRecentCodeChanges',
	#superclass : 'Object',
	#instVars : [
		'log',
		'limit',
		'scanLimit'
	],
	#category : 'AI-Pharo-Copilot-Context',
	#package : 'AI-Pharo-Copilot',
	#tag : 'Context'
}

{ #category : 'formatting' }
CoPCRecentCodeChanges >> formatChange: aChange [

	^ [
		| target packageName |
		target := self formattedTargetFor: aChange.
		target isEmpty ifTrue: [ target := aChange printString ].
		packageName := self packageNameFor: aChange.

		String streamContents: [ :stream |
			stream
				nextPutAll: aChange class name asString;
				nextPutAll: ': ';
				nextPutAll: target.
			packageName isEmpty ifFalse: [
				stream
					nextPutAll: ' [';
					nextPutAll: packageName;
					nextPut: $] ] ] ]
		on: Error
		do: [ :ignored | '' ]
]

{ #category : 'formatting' }
CoPCRecentCodeChanges >> formattedTargetFor: aChange [

	(self isMethodChange: aChange) ifTrue: [
		^ (self safeStringFrom: [ aChange behaviorAffectedName ]) ,
			'>>' ,
			(self safeStringFrom: [ aChange methodAffectedSelector ]) ].

	^ self safeStringFrom: [ aChange affectedName ]
]

{ #category : 'formatting' }
CoPCRecentCodeChanges >> gather [

	^ [
		| lines |
		lines := OrderedCollection new.
		self recentChanges do: [ :change |
			| line |
			line := self formatChange: change.
			line isEmpty ifFalse: [ lines add: line ] ].
		lines isEmpty
			ifTrue: [ '' ]
			ifFalse: [
				String streamContents: [ :stream |
					lines
						do: [ :line | stream nextPutAll: line ]
						separatedBy: [ stream nextPut: Character lf ] ] ] ]
		on: Error
		do: [ :ignored | '' ]
]

{ #category : 'initialization' }
CoPCRecentCodeChanges >> initialize [

	super initialize.
	limit := 5.
	scanLimit := 50
]

{ #category : 'testing' }
CoPCRecentCodeChanges >> isMethodChange: aChange [

	^ [ aChange isEpMethodChange ] on: Error do: [ false ]
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

{ #category : 'formatting' }
CoPCRecentCodeChanges >> packageNameFor: aChange [

	^ self safeStringFrom: [ aChange affectedPackageName ]
]

{ #category : 'collecting' }
CoPCRecentCodeChanges >> recentChanges [

	| currentLog reference changes scanned |
	currentLog := self log.
	currentLog ifNil: [ ^ #() ].

	changes := OrderedCollection new.
	reference := currentLog headReference.
	scanned := 0.

	[
		(reference isNil or: [ reference isNull ]) or: [
			changes size >= limit or: [ scanned >= scanLimit ] ] ]
		whileFalse: [
			scanned := scanned + 1.
			currentLog
				entryFor: reference
				ifPresent: [ :entry |
					[
						entry content isCodeChange ifTrue: [
							changes add: entry content ] ]
						on: Error
						do: [ :ignored | ].
					reference := currentLog priorReferenceAt: entry ]
				ifAbsent: [
					reference := currentLog nullReference ] ].

	^ changes asArray
]

{ #category : 'private' }
CoPCRecentCodeChanges >> safeStringFrom: aBlock [

	| value |
	value := [ aBlock value ] on: Error do: [ nil ].
	value ifNil: [ ^ '' ].
	^ value asString
]

{ #category : 'accessing' }
CoPCRecentCodeChanges >> scanLimit [

	^ scanLimit
]

{ #category : 'accessing' }
CoPCRecentCodeChanges >> scanLimit: anInteger [

	scanLimit := (anInteger max: 1) min: 200
]
