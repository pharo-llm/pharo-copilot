"
CoCopilotLogger is a small, file-based logger for Pharo Copilot.
It writes human-readable sections to `copilot.log` and also maintains a JSONL file for evaluation logs
inside the `pharo-copilot` directory under the image directory, when logging is enabled in CopilotSettings.
"
Class {
	#name : 'CoPharoCopilotLogger',
	#superclass : 'Object',
	#classInstVars : [
		'logFileReference',
		'logsDirectoryReference',
		'evaluationLogFileReference'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> appendDetailAssociation: anAssociation to: lines [

	| keyString valueString valueLines |
	keyString := self formatValue: anAssociation key.
	valueString := self formatValue: anAssociation value.
	valueLines := valueString lines.

	valueLines size = 1
		ifTrue: [ lines add: '  - ', keyString, ': ', valueLines first ]
		ifFalse: [
			lines add: '  - ', keyString, ':'.
			valueLines do: [ :line | lines add: '      ', line ] ]
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> appendLines: lines [

	self loggingEnabled ifFalse: [ ^ self ].

	[
		| file |
		file := self logFileReference.
		self ensureFileExists: file.

		file writeStreamDo: [ :stream |
			stream setToEnd.
			lines do: [ :line |
				stream nextPutAll: line.
				stream nextPut: Character lf ] ] ]
		on: Error
		do: [ :ex |
			Transcript
				show: 'Copilot logging failed: ', ex messageText;
				cr ]
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> completionFileReferenceFor: aSessionId [
	^ self ensureCompletionsDirectory / ('completion-', aSessionId, '.json')
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> completionSessionId [
	^ DateAndTime now asUnixTime asString , '-' , UUID new asString36
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> completionsDirectoryReference [
	^ (self ensureLogsDirectory) / 'completions'
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> ensureCompletionsDirectory [
	| directory |
	directory := self completionsDirectoryReference.
	directory ensureCreateDirectory.
	^ directory

]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> ensureEvaluationLogFileInitialized [

	self loggingEnabled ifFalse: [ ^ self ].

	[
		| file |
		file := self evaluationLogFileReference.
		self ensureFileExists: file ]
		on: Error
		do: [ :ex |
			Transcript
				show: 'Copilot evaluation log file could not be created: ', ex messageText;
				cr ]
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> ensureFileExists: aFileReference [

	aFileReference parent ifNotNil: [ :parent | parent ensureCreateDirectory ].
	aFileReference ensureCreateFile
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> ensureLogFileInitialized [

	self loggingEnabled ifFalse: [ ^ self ].

	[
		| file |
		file := self logFileReference.
		self ensureFileExists: file ]
		on: Error
		do: [ :ex |
			Transcript
				show: 'Copilot log file could not be created: ', ex messageText;
				cr ]
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> ensureLogsDirectory [

	| directory |
	directory := self logsDirectoryReference.
	self loggingEnabled ifFalse: [ ^ directory ].

	[
		directory ensureCreateDirectory ]
		on: Error
		do: [ :ex |
			Transcript
				show: 'Copilot log directory could not be created: ', ex messageText;
				cr ].
	^ directory
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> evaluationLogFileName [

	^ 'copilot-evaluation-log.jsonl'
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> evaluationLogFileReference [

	^ evaluationLogFileReference ifNil: [
		evaluationLogFileReference := (self ensureLogsDirectory) / self evaluationLogFileName ]
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> evaluationLogFileReference: aFileReference [

	evaluationLogFileReference := aFileReference
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> formatValue: anObject [

	anObject isNil ifTrue: [ ^ 'nil' ].

	(anObject isString or: [ anObject isKindOf: Text ])
		ifTrue: [ ^ anObject asString ].

	((anObject isKindOf: Dictionary) or: [ anObject isKindOf: SequenceableCollection ])
		ifTrue: [
			[ ^ STONJSON toString: anObject ]
				on: Error
				do: [ :ex | ^ anObject printString ] ].

	(anObject respondsTo: #asString)
		ifTrue: [
			[ ^ anObject asString ]
				on: Error
				do: [ :ex | ^ anObject printString ] ].

	^ anObject printString
]

{ #category : 'as yet unclassified' }
CoPharoCopilotLogger class >> initialCompletionPayloadForContextInfo: contextInfo prefix: prefixString suffix: suffixString classContext: classContext cacheStats: cacheStats [

	^ Dictionary new
		at: #timestamp put: (contextInfo at: #timestamp ifAbsent: [ DateAndTime now asString ]);
		at: #cache put: cacheStats;
		at: #context put: (Dictionary new
			at: #fullSource put: (contextInfo at: #fullSource ifAbsent: [ '' ]);
			at: #prefix put: prefixString;
			at: #suffix put: suffixString;
			at: #classContext put: classContext;
			yourself);
		at: #fim put: (Dictionary new
			at: #prefix put: prefixString;
			at: #suffix put: suffixString;
			at: #context put: classContext;
			yourself);
		at: #accepted put: nil;
		at: #rejected put: ((contextInfo at: #rejected ifAbsent: [ #() ]) asArray);
		yourself
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> initialize [

	logFileReference := nil.
	logsDirectoryReference := nil.
	evaluationLogFileReference := nil.

	self ensureLogsDirectory.
	self ensureCompletionsDirectory.
	self ensureLogFileInitialized.
	self ensureEvaluationLogFileInitialized
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> instVarNamed: aStringOrSymbol [

	| name |
	name := aStringOrSymbol asSymbol.

	name = #logFileReference ifTrue: [ ^ logFileReference ].
	name = #logsDirectoryReference ifTrue: [ ^ logsDirectoryReference ].
	name = #evaluationLogFileReference ifTrue: [ ^ evaluationLogFileReference ].

	^ super instVarNamed: aStringOrSymbol
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> instVarNamed: aStringOrSymbol put: aValue [

	| name |
	name := aStringOrSymbol asSymbol.

	name = #logFileReference ifTrue: [ logFileReference := aValue. ^ aValue ].
	name = #logsDirectoryReference ifTrue: [ logsDirectoryReference := aValue. ^ aValue ].
	name = #evaluationLogFileReference ifTrue: [ evaluationLogFileReference := aValue. ^ aValue ].

	^ super instVarNamed: name put: aValue
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> logBackEndEvent: eventName details: aDictionary [

	self logSection: 'BACKEND' event: eventName details: aDictionary
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> logFileName [

	^ 'copilot.log'
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> logFileReference [

	^ logFileReference ifNil: [
		logFileReference := (self ensureLogsDirectory) / self logFileName ]
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> logFrontEndEvent: eventName details: aDictionary [

	self logSection: 'FRONTEND' event: eventName details: aDictionary
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> logSection: sectionName event: eventName details: aDictionary [

	| timestamp lines |
	self loggingEnabled ifFalse: [ ^ self ].

	timestamp := DateAndTime now asString.
	lines := OrderedCollection new.

	lines add: ''.
	lines add: (String streamContents: [ :stream |
		stream
			nextPutAll: '===== [';
			nextPutAll: sectionName;
			nextPutAll: '] ';
			nextPutAll: eventName;
			nextPutAll: ' @ ';
			nextPutAll: timestamp;
			nextPutAll: ' =====' ]).

	(aDictionary isNil or: [ aDictionary isEmpty ]) ifFalse: [
		(aDictionary respondsTo: #associationsDo)
			ifTrue: [ aDictionary associationsDo: [ :assoc | self appendDetailAssociation: assoc to: lines ] ]
			ifFalse: [ self appendDetailAssociation: aDictionary -> '' to: lines ] ].

	lines add: ''.

	self appendLines: lines
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> loggingEnabled [

	^ CopilotSettings loggingEnabled
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> logsDirectoryName [

	^ self pharoCopilotDirectoryName
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> logsDirectoryReference [

	^ logsDirectoryReference ifNil: [
		logsDirectoryReference := FileLocator imageDirectory / self pharoCopilotDirectoryName ]
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> pharoCopilotDirectoryName [

	^ 'pharo-copilot'
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> rawEvaluationLogFileReference [

	^ evaluationLogFileReference
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> rawEvaluationLogFileReference: aFileReference [

	evaluationLogFileReference := aFileReference
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> rawLogFileReference [

	^ logFileReference
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> rawLogFileReference: aFileReference [

	logFileReference := aFileReference
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> rawLogsDirectoryReference [

	^ logsDirectoryReference
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> rawLogsDirectoryReference: aDirectoryReference [

	logsDirectoryReference := aDirectoryReference
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> updateCompletionSession: aSessionId addRejected: rejectedString [
	| file payload rejected |
	self loggingEnabled ifFalse: [ ^ self ].
	file := self completionFileReferenceFor: aSessionId.
	file exists ifFalse: [ ^ self ].
	payload := STONJSON fromString: file contents.
	rejected := payload at: #rejected ifAbsent: [ OrderedCollection new ].
	rejected add: rejectedString.
	payload at: #rejected put: rejected asArray.
	file writeStreamDo: [ :stream |
		stream nextPutAll: (STONJSON toString: payload) ]
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> updateCompletionSession: aSessionId withAccepted: acceptedString [
	| file payload |
	self loggingEnabled ifFalse: [ ^ self ].
	file := self completionFileReferenceFor: aSessionId.
	file exists ifFalse: [ ^ self ].
	payload := STONJSON fromString: file contents.
	payload at: #accepted put: acceptedString.
	file writeStreamDo: [ :stream |
		stream nextPutAll: (STONJSON toString: payload) ]
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> writeCompletionSession: aDictionary sessionId: aSessionId [
	| file |
	self loggingEnabled ifFalse: [ ^ self ].
	file := self completionFileReferenceFor: aSessionId.
	self ensureFileExists: file.
	file writeStreamDo: [ :stream |
		stream nextPutAll: (STONJSON toString: aDictionary) ]
]
