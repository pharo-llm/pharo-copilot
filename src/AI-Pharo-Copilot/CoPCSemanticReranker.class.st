"
Orders model suggestions against local semantic selector completions.
"
Class {
	#name : 'CoPCSemanticReranker',
	#superclass : 'Object',
	#instVars : [
		'builder',
		'context',
		'contextInfo',
		'prefix',
		'token',
		'receiverInfo',
		'receiverTypes',
		'selectorCache'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'instance creation' }
CoPCSemanticReranker class >> builder: aBuilder context: aContext contextInfo: aDictionary [

	^ self new
		builder: aBuilder;
		context: aContext;
		contextInfo: aDictionary;
		yourself
]

{ #category : 'accessing' }
CoPCSemanticReranker >> builder: aBuilder [

	builder := aBuilder
]

{ #category : 'classification' }
CoPCSemanticReranker >> classificationForEntry: anEntry [

	| candidate selector firstPart selectors |
	candidate := self selectorCandidateForEntry: anEntry.
	selector := candidate at: #selector ifAbsent: [ '' ].
	firstPart := candidate at: #firstPart ifAbsent: [ '' ].
	selector isEmpty ifTrue: [ ^ #medium ].

	selectors := self supportedSelectors.
	(selectors includes: selector) ifTrue: [ ^ #high ].
	(firstPart isEmpty not and: [
		selectors anySatisfy: [ :each | each beginsWith: firstPart ] ])
			ifTrue: [ ^ #medium ].

	^ #low
]

{ #category : 'accessing' }
CoPCSemanticReranker >> context: aContext [

	context := aContext
]

{ #category : 'accessing' }
CoPCSemanticReranker >> contextInfo: aDictionary [

	contextInfo := aDictionary
]

{ #category : 'classification' }
CoPCSemanticReranker >> emptySelectorCandidate [

	^ Dictionary new
		at: #selector put: '';
		at: #firstPart put: '';
		yourself
]

{ #category : 'ordering' }
CoPCSemanticReranker >> first: count from: entryCollection [

	| entries limit |
	entries := entryCollection asArray.
	limit := count min: entries size.
	limit <= 0 ifTrue: [ ^ #() ].
	^ entries copyFrom: 1 to: limit
]

{ #category : 'ordering' }
CoPCSemanticReranker >> fusedFallbackLimit [

	^ 3
]

{ #category : 'testing' }
CoPCSemanticReranker >> hasSemanticMessageContext [

	^ self receiverName isEmpty not
		and: [ self receiverTypes isEmpty not ]
]

{ #category : 'testing' }
CoPCSemanticReranker >> isBinarySelectorChar: aCharacter [

	aCharacter ifNil: [ ^ false ].
	(self isWordChar: aCharacter) ifTrue: [ ^ false ].
	aCharacter isSeparator ifTrue: [ ^ false ].
	aCharacter = $: ifTrue: [ ^ false ].
	^ '+-*/\~<>=@%|&?!,' includes: aCharacter
]

{ #category : 'testing' }
CoPCSemanticReranker >> isWordChar: aCharacter [

	aCharacter ifNil: [ ^ false ].
	^ aCharacter isLetter
		or: [ aCharacter isDigit
		or: [ aCharacter = $_ ] ]
]

{ #category : 'classification' }
CoPCSemanticReranker >> keywordSelectorFrom: text firstPart: firstPart afterColon: startIndex [

	| selector index depth ch wordEnd |
	selector := firstPart.
	index := startIndex.
	depth := 0.

	[ index <= text size ] whileTrue: [
		ch := text at: index.
		(ch = Character lf or: [ ch = Character cr or: [ ch = $. ] ])
			ifTrue: [ ^ selector ].

		((ch = $[) or: [ ch = $( or: [ ch = ${ ] ]) ifTrue: [
			depth := depth + 1.
			index := index + 1 ]
		ifFalse: [
			((ch = $]) or: [ ch = $) or: [ ch = $} ] ]) ifTrue: [
				depth := depth - 1 max: 0.
				index := index + 1 ]
			ifFalse: [
				(depth = 0 and: [ self isWordChar: ch ])
					ifTrue: [
						wordEnd := self wordEndIn: text startingAt: index.
						(wordEnd < text size and: [ (text at: wordEnd + 1) = $: ])
							ifTrue: [
								selector := selector , (text copyFrom: index to: wordEnd) , ':'.
								index := wordEnd + 2 ]
							ifFalse: [ index := wordEnd + 1 ] ]
					ifFalse: [ index := index + 1 ] ] ] ].

	^ selector
]

{ #category : 'accessing' }
CoPCSemanticReranker >> prefix [

	prefix ifNotNil: [ ^ prefix ].

	prefix := contextInfo
		ifNil: [ nil ]
		ifNotNil: [ contextInfo at: #prefix ifAbsent: [ nil ] ].
	prefix ifNotNil: [ ^ prefix ].

	prefix := context
		ifNil: [ '' ]
		ifNotNil: [ (builder contextSnapshotFor: context) at: #prefix ifAbsent: [ '' ] ].
	^ prefix
]

{ #category : 'accessing' }
CoPCSemanticReranker >> receiverInfo [

	receiverInfo ifNil: [
		receiverInfo := builder
			semanticReceiverInfoFor: context
			prefix: self prefix ].
	^ receiverInfo
]

{ #category : 'accessing' }
CoPCSemanticReranker >> receiverName [

	^ self receiverInfo at: #receiver ifAbsent: [ '' ]
]

{ #category : 'accessing' }
CoPCSemanticReranker >> receiverTypes [

	receiverTypes ifNil: [
		receiverTypes := builder normalizeSemanticTypes:
			(self receiverInfo at: #types ifAbsent: [ #() ]) ].
	^ receiverTypes
]

{ #category : 'logging' }
CoPCSemanticReranker >> recordDecisionStatus: status scoredEntries: scoredEntries fallbackEntries: fallbackEntries resultEntries: resultEntries [

	| payload |
	contextInfo ifNil: [ ^ self ].

	payload := Dictionary new
		at: #status put: status;
		at: #token put: self token;
		at: #receiver put: self receiverName;
		at: #receiverTypes put: (builder typeNamesStringFor: self receiverTypes);
		at: #modelTop put: (scoredEntries isEmpty
			ifTrue: [ '' ]
			ifFalse: [ builder entryContentsFor: scoredEntries first key ]);
		at: #heuristicTop put: (fallbackEntries isEmpty
			ifTrue: [ '' ]
			ifFalse: [ builder entryContentsFor: fallbackEntries first ]);
		at: #modelStatuses put: ((scoredEntries collect: [ :assoc |
			Dictionary new
				at: #contents put: (builder entryContentsFor: assoc key);
				at: #status put: assoc value;
				yourself ]) asArray);
		at: #shownOrder put: ((resultEntries collect: [ :entry |
			self sourceNameForEntry: entry ]) asArray);
		yourself.

	contextInfo at: #semanticGate put: payload
]

{ #category : 'ordering' }
CoPCSemanticReranker >> rerankModelEntries: modelEntries fallbackEntries: fallbackEntries [

	| scored firstStatus highModels mediumModels acceptedModels result |
	scored := modelEntries collect: [ :entry |
		entry -> (self classificationForEntry: entry) ].
	firstStatus := scored first value.
	highModels := (scored select: [ :assoc | assoc value = #high ])
		collect: [ :assoc | assoc key ].
	mediumModels := (scored select: [ :assoc | assoc value = #medium ])
		collect: [ :assoc | assoc key ].
	acceptedModels := OrderedCollection new.
	acceptedModels addAll: highModels.
	acceptedModels addAll: mediumModels.

	result := OrderedCollection new.
	firstStatus = #high
		ifTrue: [
			result addAll: acceptedModels.
			result addAll: (self first: self fusedFallbackLimit from: fallbackEntries) ]
		ifFalse: [
			fallbackEntries isEmpty
				ifTrue: [ result addAll: modelEntries ]
				ifFalse: [
					result addAll: (self first: self fusedFallbackLimit from: fallbackEntries).
					firstStatus = #medium ifTrue: [ result addAll: acceptedModels ].
					(firstStatus = #low and: [ acceptedModels isEmpty not ])
						ifTrue: [ result addAll: acceptedModels ] ] ].

	self
		recordDecisionStatus: firstStatus
		scoredEntries: scored
		fallbackEntries: fallbackEntries
		resultEntries: result.

	^ result asArray
]

{ #category : 'classification' }
CoPCSemanticReranker >> selectorCandidateForEntry: anEntry [

	^ self selectorCandidateFrom:
		(self token , (builder entryContentsFor: anEntry))
]

{ #category : 'classification' }
CoPCSemanticReranker >> selectorCandidateFrom: aString [

	| text first index wordEnd word firstPart selector |
	text := (aString ifNil: [ '' ]) asString trimLeft.
	text isEmpty ifTrue: [ ^ self emptySelectorCandidate ].

	first := text first.
	(self isBinarySelectorChar: first) ifTrue: [
		index := 1.
		[ index <= text size and: [ self isBinarySelectorChar: (text at: index) ] ]
			whileTrue: [ index := index + 1 ].
		selector := text copyFrom: 1 to: index - 1.
		^ Dictionary new
			at: #selector put: selector;
			at: #firstPart put: selector;
			yourself ].

	(self isWordChar: first) ifFalse: [ ^ self emptySelectorCandidate ].

	wordEnd := self wordEndIn: text startingAt: 1.
	word := text copyFrom: 1 to: wordEnd.
	(wordEnd < text size and: [ (text at: wordEnd + 1) = $: ])
		ifFalse: [
			^ Dictionary new
				at: #selector put: word;
				at: #firstPart put: word;
				yourself ].

	firstPart := word , ':'.
	selector := self
		keywordSelectorFrom: text
		firstPart: firstPart
		afterColon: wordEnd + 2.

	^ Dictionary new
		at: #selector put: selector;
		at: #firstPart put: firstPart;
		yourself
]

{ #category : 'testing' }
CoPCSemanticReranker >> shouldUseSemanticGate [

	^ self hasSemanticMessageContext
]

{ #category : 'logging' }
CoPCSemanticReranker >> sourceNameForEntry: anEntry [

	^ (anEntry isKindOf: CoPCFallbackCompletionEntry)
		ifTrue: [ #heuristic ]
		ifFalse: [ #copilot ]
]

{ #category : 'accessing' }
CoPCSemanticReranker >> supportedSelectors [

	selectorCache ifNil: [
		selectorCache := Set new.
		self receiverTypes do: [ :type |
			| current |
			current := type.
			[ current notNil ] whileTrue: [
				[
					current selectorsDo: [ :selector |
						selectorCache add: selector asString ] ]
					on: Error
					do: [ ].
				current := [ current superclass ] on: Error do: [ nil ] ] ] ].
	^ selectorCache
]

{ #category : 'accessing' }
CoPCSemanticReranker >> token [

	token ifNil: [
		token := builder completionTokenFor: context prefix: self prefix ].
	^ token
]

{ #category : 'classification' }
CoPCSemanticReranker >> wordEndIn: text startingAt: startIndex [

	| index |
	index := startIndex.
	[ index <= text size and: [ self isWordChar: (text at: index) ] ]
		whileTrue: [ index := index + 1 ].
	^ index - 1
]
