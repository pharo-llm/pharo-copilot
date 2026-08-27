"
Composes already-rendered completion context sections in the order expected by
the FIM model.
"
Class {
	#name : 'CoPCPromptContextComposer',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'composing' }
CoPCPromptContextComposer >> appendRaw: aString to: stream [

	| text |
	text := self normalizedString: aString.
	text isEmpty ifTrue: [ ^ self ].

	stream position > 0 ifTrue: [
		self ensureLineFeedOn: stream ].
	stream nextPutAll: text.
	text last = Character lf ifFalse: [
		stream nextPut: Character lf ]
]

{ #category : 'composing' }
CoPCPromptContextComposer >> appendSectionNamed: sectionName contents: contentString to: stream [

	| text |
	text := self normalizedString: contentString.
	text isEmpty ifTrue: [ ^ self ].

	stream position > 0 ifTrue: [
		self ensureLineFeedOn: stream ].
	stream
		nextPutAll: '<|file_sep|>';
		nextPutAll: sectionName;
		nextPut: Character lf;
		nextPutAll: text.
	text last = Character lf ifFalse: [
		stream nextPut: Character lf ]
]

{ #category : 'composing' }
CoPCPromptContextComposer >> composeHeader: headerString semanticContext: semanticString repositoryBody: repositoryBodyString relatedCode: relatedCodeString interactionHistory: historyString recentCodeChanges: recentChangesString [

	^ String streamContents: [ :stream |
		self appendRaw: headerString to: stream.
		self appendSectionNamed: 'Semantic completion context' contents: semanticString to: stream.
		self appendRaw: repositoryBodyString to: stream.
		self appendRaw: relatedCodeString to: stream.
		self appendSectionNamed: 'IDE interaction history' contents: historyString to: stream.
		self appendSectionNamed: 'Recent code changes' contents: recentChangesString to: stream ]
]

{ #category : 'composing' }
CoPCPromptContextComposer >> ensureLineFeedOn: stream [

	| contents |
	stream position = 0 ifTrue: [ ^ self ].
	contents := stream contents.
	contents isEmpty ifTrue: [ ^ self ].
	contents last = Character lf ifFalse: [
		stream nextPut: Character lf ]
]

{ #category : 'composing' }
CoPCPromptContextComposer >> normalizedString: aString [

	aString ifNil: [ ^ '' ].
	^ aString asString
]
