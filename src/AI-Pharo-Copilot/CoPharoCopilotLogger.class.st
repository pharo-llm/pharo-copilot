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

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> initialize [

	logFileReference := nil.
	logsDirectoryReference := nil.
	evaluationLogFileReference := nil.

	self ensureLogsDirectory.
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
