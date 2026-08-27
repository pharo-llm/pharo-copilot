"
Gathers a small, deterministic set of related method sources for completion
prompts. It ranks Pharo code directly and renders source, not summaries.
"
Class {
	#name : 'CoPCRelatedCodeContext',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'gathering' }
CoPCRelatedCodeContext >> addCandidateBehavior: aBehavior selector: aSelector score: scoreNumber to: candidates seen: seen [

	| key source |
	(aBehavior isNil or: [ aSelector isNil ]) ifTrue: [ ^ self ].
	key := { aBehavior. aSelector }.
	(seen includes: key) ifTrue: [ ^ self ].

	source := self sourceForBehavior: aBehavior selector: aSelector.
	source isEmpty ifTrue: [ ^ self ].

	seen add: key.
	candidates add: (Dictionary new
		at: #behavior put: aBehavior;
		at: #selector put: aSelector;
		at: #source put: source;
		at: #score put: scoreNumber;
		yourself)
]

{ #category : 'gathering' }
CoPCRelatedCodeContext >> addCandidatesFromReceiverTypes: receiverTypes prefix: selectorPrefix to: candidates seen: seen [

	receiverTypes do: [ :type |
		candidates size >= self candidateLimit ifTrue: [ ^ self ].
		self addSelectorsFromBehavior: type prefix: selectorPrefix score: 120 to: candidates seen: seen.
		(self superclassesFor: type) do: [ :superclass |
			candidates size >= self candidateLimit ifTrue: [ ^ self ].
			self addSelectorsFromBehavior: superclass prefix: selectorPrefix score: 105 to: candidates seen: seen ] ]
]

{ #category : 'gathering' }
CoPCRelatedCodeContext >> addHierarchyCandidatesFor: aBehavior prefix: selectorPrefix to: candidates seen: seen [

	aBehavior ifNil: [ ^ self ].
	(self superclassesFor: aBehavior) do: [ :superclass |
		candidates size >= self candidateLimit ifTrue: [ ^ self ].
		self addSelectorsFromBehavior: superclass prefix: selectorPrefix score: 75 to: candidates seen: seen ].
	(self subclassesFor: aBehavior limit: 12) do: [ :subclass |
		candidates size >= self candidateLimit ifTrue: [ ^ self ].
		self addSelectorsFromBehavior: subclass prefix: selectorPrefix score: 75 to: candidates seen: seen ]
]

{ #category : 'gathering' }
CoPCRelatedCodeContext >> addImplementorCandidatesForSelectorsFrom: receiverTypes prefix: selectorPrefix to: candidates seen: seen [

	| selectors seenSelectors |
	candidates size >= self candidateLimit ifTrue: [ ^ self ].
	selectors := OrderedCollection new.
	seenSelectors := Set new.

	receiverTypes do: [ :type |
		self matchingSelectorsFrom: type prefix: selectorPrefix limit: 3 do: [ :selector |
			(seenSelectors includes: selector) ifFalse: [
				seenSelectors add: selector.
				selectors add: selector ] ] ].

	selectors do: [ :selector |
		self allClasses do: [ :class |
			candidates size >= self candidateLimit ifTrue: [ ^ self ].
			([ class includesSelector: selector ] on: Error do: [ false ]) ifTrue: [
				self addCandidateBehavior: class selector: selector score: 65 to: candidates seen: seen ].
			([ class class includesSelector: selector ] on: Error do: [ false ]) ifTrue: [
				self addCandidateBehavior: class class selector: selector score: 65 to: candidates seen: seen ] ] ]
]

{ #category : 'gathering' }
CoPCRelatedCodeContext >> addSamePackageCandidatesFor: aBehavior prefix: selectorPrefix to: candidates seen: seen [

	| packageName |
	aBehavior ifNil: [ ^ self ].
	packageName := self packageNameForBehavior: aBehavior.
	packageName isEmpty ifTrue: [ ^ self ].

	self allClasses do: [ :class |
		candidates size >= self candidateLimit ifTrue: [ ^ self ].
		((self packageNameForBehavior: class) = packageName) ifTrue: [
			self addSelectorsFromBehavior: class prefix: selectorPrefix score: 85 to: candidates seen: seen ].
		((self packageNameForBehavior: class class) = packageName) ifTrue: [
			self addSelectorsFromBehavior: class class prefix: selectorPrefix score: 85 to: candidates seen: seen ] ]
]

{ #category : 'gathering' }
CoPCRelatedCodeContext >> addSelectorsFromBehavior: aBehavior prefix: selectorPrefix score: scoreNumber to: candidates seen: seen [

	self matchingSelectorsFrom: aBehavior prefix: selectorPrefix limit: self candidateLimit do: [ :selector |
		candidates size >= self candidateLimit ifTrue: [ ^ self ].
		self
			addCandidateBehavior: aBehavior
			selector: selector
			score: scoreNumber
			to: candidates
			seen: seen ]
]

{ #category : 'accessing' }
CoPCRelatedCodeContext >> allClasses [

	^ [
		SystemNavigation default allClasses asArray ]
		on: Error
		do: [ #() ]
]

{ #category : 'accessing' }
CoPCRelatedCodeContext >> behaviorForContext: aContext [

	| behavior |
	aContext ifNil: [ ^ nil ].
	behavior := (aContext respondsTo: #completionClass)
		ifTrue: [ [ aContext completionClass ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	behavior ifNotNil: [ ^ behavior ].

	^ (aContext respondsTo: #behavior)
		ifTrue: [ [ aContext behavior ] on: Error do: [ nil ] ]
		ifFalse: [ nil ]
]

{ #category : 'accessing' }
CoPCRelatedCodeContext >> candidateLimit [

	^ 40
]

{ #category : 'sorting' }
CoPCRelatedCodeContext >> candidate: firstCandidate sortsBefore: secondCandidate [

	| firstScore secondScore firstName secondName firstSelector secondSelector |
	firstScore := firstCandidate at: #score ifAbsent: [ 0 ].
	secondScore := secondCandidate at: #score ifAbsent: [ 0 ].
	firstScore = secondScore ifFalse: [ ^ firstScore > secondScore ].

	firstName := self displayNameForBehavior: (firstCandidate at: #behavior ifAbsent: [ nil ]).
	secondName := self displayNameForBehavior: (secondCandidate at: #behavior ifAbsent: [ nil ]).
	firstName = secondName ifFalse: [ ^ firstName <= secondName ].

	firstSelector := (firstCandidate at: #selector ifAbsent: [ '' ]) asString.
	secondSelector := (secondCandidate at: #selector ifAbsent: [ '' ]) asString.
	^ firstSelector <= secondSelector
]

{ #category : 'accessing' }
CoPCRelatedCodeContext >> displayNameForBehavior: aBehavior [

	aBehavior ifNil: [ ^ '' ].
	^ [ aBehavior name asString ]
		on: Error
		do: [ aBehavior asString ]
]

{ #category : 'gathering' }
CoPCRelatedCodeContext >> gatherFor: aContext receiverTypes: receiverTypes selectorPrefix: selectorPrefix [

	| prefix types candidates seen contextBehavior |
	prefix := selectorPrefix ifNil: [ '' ] ifNotNil: [ selectorPrefix asString ].
	prefix size < 2 ifTrue: [ ^ '' ].

	types := self normalizedBehaviorsFrom: receiverTypes.
	contextBehavior := self behaviorForContext: aContext.
	candidates := OrderedCollection new.
	seen := Set new.

	self addCandidatesFromReceiverTypes: types prefix: prefix to: candidates seen: seen.
	self addSamePackageCandidatesFor: contextBehavior prefix: prefix to: candidates seen: seen.
	self addHierarchyCandidatesFor: contextBehavior prefix: prefix to: candidates seen: seen.
	self addImplementorCandidatesForSelectorsFrom: types prefix: prefix to: candidates seen: seen.

	^ self renderCandidates: candidates
]

{ #category : 'testing' }
CoPCRelatedCodeContext >> isBehaviorLike: anObject [

	anObject ifNil: [ ^ false ].
	^ (anObject respondsTo: #selectors)
		and: [ anObject respondsTo: #sourceCodeAt: ]
]

{ #category : 'accessing' }
CoPCRelatedCodeContext >> matchingSelectorsFrom: aBehavior prefix: selectorPrefix limit: limitInteger do: aBlock [

	| selectors prefix count |
	(self isBehaviorLike: aBehavior) ifFalse: [ ^ self ].
	prefix := selectorPrefix ifNil: [ '' ] ifNotNil: [ selectorPrefix asString ].
	prefix isEmpty ifTrue: [ ^ self ].
	count := 0.

	selectors := [
		aBehavior selectors asSortedCollection asArray ]
		on: Error
		do: [ #() ].
	selectors do: [ :selector |
		(count >= limitInteger) ifTrue: [ ^ self ].
		(selector asString beginsWith: prefix) ifTrue: [
			aBlock value: selector.
			count := count + 1 ] ]
]

{ #category : 'accessing' }
CoPCRelatedCodeContext >> maxCharacters [

	^ 5000
]

{ #category : 'accessing' }
CoPCRelatedCodeContext >> maxMethods [

	^ 5
]

{ #category : 'accessing' }
CoPCRelatedCodeContext >> normalizedBehaviorsFrom: typeCollection [

	| result seen |
	result := OrderedCollection new.
	seen := Set new.
	(typeCollection ifNil: [ #() ]) do: [ :type |
		((self isBehaviorLike: type) and: [ (seen includes: type) not ]) ifTrue: [
			seen add: type.
			result add: type ] ].
	^ result asArray
]

{ #category : 'accessing' }
CoPCRelatedCodeContext >> packageNameForBehavior: aBehavior [

	| behavior package organizer |
	aBehavior ifNil: [ ^ '' ].
	behavior := self packageOwnerForBehavior: aBehavior.

	package := [
		(behavior respondsTo: #package)
			ifTrue: [ behavior package ]
			ifFalse: [ nil ] ]
		on: Error
		do: [ nil ].
	package ifNotNil: [ ^ self packageNameFrom: package ].

	organizer := Smalltalk globals at: #RPackageOrganizer ifAbsent: [ nil ].
	(organizer notNil and: [ organizer respondsTo: #default ]) ifTrue: [
		package := [
			organizer default packageOfClass: behavior ]
			on: Error
			do: [ nil ].
		package ifNotNil: [ ^ self packageNameFrom: package ] ].

	^ ''
]

{ #category : 'accessing' }
CoPCRelatedCodeContext >> packageNameFrom: package [

	^ (package respondsTo: #name)
		ifTrue: [ [ package name asString ] on: Error do: [ package asString ] ]
		ifFalse: [ package asString ]
]

{ #category : 'accessing' }
CoPCRelatedCodeContext >> packageOwnerForBehavior: aBehavior [

	^ ((aBehavior respondsTo: #isMeta) and: [
		[ aBehavior isMeta ] on: Error do: [ false ] ])
			ifTrue: [
				(aBehavior respondsTo: #instanceSide)
					ifTrue: [ [ aBehavior instanceSide ] on: Error do: [ aBehavior ] ]
					ifFalse: [ aBehavior ] ]
			ifFalse: [ aBehavior ]
]

{ #category : 'rendering' }
CoPCRelatedCodeContext >> renderCandidate: candidate maxCharacters: remainingCharacters [

	| behavior selector source header entry sourceLimit |
	remainingCharacters <= 0 ifTrue: [ ^ '' ].
	behavior := candidate at: #behavior ifAbsent: [ nil ].
	selector := candidate at: #selector ifAbsent: [ nil ].
	source := candidate at: #source ifAbsent: [ '' ].
	source isEmpty ifTrue: [ ^ '' ].

	header := '<|file_sep|>Related code: ' ,
		(self displayNameForBehavior: behavior) ,
		'>>' ,
		selector asString ,
		String lf.
	entry := header , source , String lf.
	entry size <= remainingCharacters ifTrue: [ ^ entry ].

	sourceLimit := remainingCharacters - header size - 4.
	sourceLimit <= 0 ifTrue: [ ^ '' ].
	sourceLimit := sourceLimit min: source size.
	^ header ,
		(source copyFrom: 1 to: sourceLimit) ,
		'...' ,
		String lf
]

{ #category : 'rendering' }
CoPCRelatedCodeContext >> renderCandidates: candidates [

	| sorted used count |
	candidates isEmpty ifTrue: [ ^ '' ].

	sorted := candidates asSortedCollection: [ :a :b |
		self candidate: a sortsBefore: b ].
	used := 0.
	count := 0.

	^ String streamContents: [ :stream |
		sorted do: [ :candidate |
			| entry remaining |
			count < self maxMethods ifTrue: [
				remaining := self maxCharacters - used.
				entry := self renderCandidate: candidate maxCharacters: remaining.
				entry isEmpty ifFalse: [
					stream nextPutAll: entry.
					used := used + entry size.
					count := count + 1 ] ] ] ]
]

{ #category : 'accessing' }
CoPCRelatedCodeContext >> sourceForBehavior: aBehavior selector: aSelector [

	^ [
		(aBehavior sourceCodeAt: aSelector) asString trimBoth ]
		on: Error
		do: [ '' ]
]

{ #category : 'accessing' }
CoPCRelatedCodeContext >> subclassesFor: aBehavior limit: limitInteger [

	| subclasses limit |
	(self isBehaviorLike: aBehavior) ifFalse: [ ^ #() ].
	subclasses := OrderedCollection new.
	limit := limitInteger ifNil: [ 12 ].

	[
		aBehavior subclasses do: [ :subclass |
			subclasses size >= limit ifTrue: [ ^ subclasses asArray ].
			subclasses add: subclass ] ]
		on: Error
		do: [ ].
	^ subclasses asArray
]

{ #category : 'accessing' }
CoPCRelatedCodeContext >> superclassesFor: aBehavior [

	| classes current |
	(self isBehaviorLike: aBehavior) ifFalse: [ ^ #() ].
	classes := OrderedCollection new.
	current := [ aBehavior superclass ] on: Error do: [ nil ].

	[ current notNil and: [ classes size < 8 ] ] whileTrue: [
		classes add: current.
		current := [ current superclass ] on: Error do: [ nil ] ].
	^ classes asArray
]
