"
CoCopilotLogger is a small, file-based logger for Pharo Copilot.
It writes human-readable sections to `copilot.log` and also maintains a JSONL file for evaluation logs
inside the `pharo-copilot` directory under the image directory, when logging is enabled in CopilotSettings.
"
Class {
	#name : 'CoCopilotLogger',
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
CoCopilotLogger class >> appendDetailAssociation: anAssociation to: lines [
	"Append one key/value detail in a readable YAML-ish format. Multi-line values are indented."

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
CoCopilotLogger class >> appendLines: lines [
	"Append the given lines to the main log file, preserving previous content."

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
CoCopilotLogger class >> ensureEvaluationLogFileInitialized [
	"Make sure the evaluation JSONL file exists (and its parent directory), if logging is enabled."

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
CoCopilotLogger class >> ensureFileExists: aFileReference [
	"Ensure the parent directory exists (if any) and create the file if missing."

	aFileReference parent ifNotNil: [ :parent | parent ensureCreateDirectory ].
	aFileReference ensureCreateFile
]

{ #category : 'class initialization' }
CoCopilotLogger class >> ensureLogFileInitialized [
	"Make sure the main log file exists (and its parent directory), if logging is enabled."

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
CoCopilotLogger class >> ensureLogsDirectory [
	"Ensure the directory that holds Copilot log files exists and return it."

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
CoCopilotLogger class >> evaluationLogFileName [
	"Return the filename used for evaluation logs."

	^ 'copilot-evaluation-log.jsonl'
]

{ #category : 'class initialization' }
CoCopilotLogger class >> evaluationLogFileReference [
	"Return the file reference for the evaluation JSONL log, lazily initialized."

	^ evaluationLogFileReference ifNil: [
		evaluationLogFileReference := (self ensureLogsDirectory) / self evaluationLogFileName ]
]

{ #category : 'class initialization' }
CoCopilotLogger class >> evaluationLogFileReference: aFileReference [
	"Override the evaluation log file location (mainly for tests or custom setups)."

	evaluationLogFileReference := aFileReference
]

{ #category : 'class initialization' }
CoCopilotLogger class >> formatValue: anObject [
	"Convert common objects to a readable string, using JSON for collections when possible."

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
CoCopilotLogger class >> initialize [
	"Reset cached file references and eagerly ensure the log locations exist (when enabled)."

	logFileReference := nil.
	logsDirectoryReference := nil.
	evaluationLogFileReference := nil.

	self ensureLogsDirectory.
	self ensureLogFileInitialized.
	self ensureEvaluationLogFileInitialized
]

{ #category : 'class initialization' }
CoCopilotLogger class >> instVarNamed: aStringOrSymbol [
	"Support reflective access to class instance variables (used by some tools/tests)."

	| name |
	name := aStringOrSymbol asSymbol.

	name = #logFileReference ifTrue: [ ^ logFileReference ].
	name = #logsDirectoryReference ifTrue: [ ^ logsDirectoryReference ].
	name = #evaluationLogFileReference ifTrue: [ ^ evaluationLogFileReference ].

	^ super instVarNamed: aStringOrSymbol
]

{ #category : 'class initialization' }
CoCopilotLogger class >> instVarNamed: aStringOrSymbol put: aValue [
	"Support reflective writes to class instance variables (used by some tools/tests)."

	| name |
	name := aStringOrSymbol asSymbol.

	name = #logFileReference ifTrue: [ logFileReference := aValue. ^ aValue ].
	name = #logsDirectoryReference ifTrue: [ logsDirectoryReference := aValue. ^ aValue ].
	name = #evaluationLogFileReference ifTrue: [ evaluationLogFileReference := aValue. ^ aValue ].

	^ super instVarNamed: name put: aValue
]

{ #category : 'class initialization' }
CoCopilotLogger class >> logBackEndEvent: eventName details: aDictionary [
	"Log an event coming from the backend side of the Copilot integration."

	self logSection: 'BACKEND' event: eventName details: aDictionary
]

{ #category : 'class initialization' }
CoCopilotLogger class >> logError: eventName origin: originSymbol exception: anException payload: aDictionary [
	"Log an error event, enriching the payload with origin, error message, and best-effort stack info."

	| details |
	details := (aDictionary ifNil: [ Dictionary new ]) copy.
	details
		at: #origin put: (self formatValue: originSymbol);
		at: #error put: (anException
			ifNil: [ 'Unknown error' ]
			ifNotNil: [ anException messageText ]).

	anException ifNotNil: [
		(anException respondsTo: #stack)
			ifTrue: [ details at: #stack put: (self formatValue: anException stack) ].

		(anException respondsTo: #signalerContext)
			ifTrue: [
				[
					details at: #stackTrace put: (
						String streamContents: [ :s |
							anException signalerContext printDebugOn: s ])
				]
					on: Error
					do: [ :ignored | "best-effort only" ] ] ].

	self logSection: 'ERROR' event: eventName details: details
]

{ #category : 'class initialization' }
CoCopilotLogger class >> logFileName [
	"Return the filename used for the main log."

	^ 'copilot.log'
]

{ #category : 'class initialization' }
CoCopilotLogger class >> logFileReference [
	"Return the file reference for the main log file, lazily initialized."

	^ logFileReference ifNil: [
		logFileReference := (self ensureLogsDirectory) / self logFileName ]
]

{ #category : 'class initialization' }
CoCopilotLogger class >> logFrontEndEvent: eventName details: aDictionary [
	"Log an event coming from the frontend/UI side of the Copilot integration."

	self logSection: 'FRONTEND' event: eventName details: aDictionary
]

{ #category : 'class initialization' }
CoCopilotLogger class >> logSection: sectionName event: eventName details: aDictionary [
	"Write one structured log section (header + optional key/value details) into the main log file."

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
CoCopilotLogger class >> loggingEnabled [
	"Answer whether Copilot logging is currently enabled in settings."

	^ CopilotSettings loggingEnabled
]

{ #category : 'class initialization' }
CoCopilotLogger class >> logsDirectoryName [
	"Return the directory name used to store Copilot logs."

	^ self pharoCopilotDirectoryName
]

{ #category : 'class initialization' }
CoCopilotLogger class >> logsDirectoryReference [
	"Return the directory reference where Copilot logs live, lazily initialized."

	^ logsDirectoryReference ifNil: [
		logsDirectoryReference := FileLocator imageDirectory / self pharoCopilotDirectoryName ]
]

{ #category : 'class initialization' }
CoCopilotLogger class >> pharoCopilotDirectoryName [
	"Return the folder name used under the image directory for Copilot files."

	^ 'pharo-copilot'
]

{ #category : 'class initialization' }
CoCopilotLogger class >> rawEvaluationLogFileReference [
	"Return the cached evaluation log file reference (may be nil if not initialized)."

	^ evaluationLogFileReference
]

{ #category : 'class initialization' }
CoCopilotLogger class >> rawEvaluationLogFileReference: aFileReference [
	"Set the cached evaluation log file reference directly (used by tests)."

	evaluationLogFileReference := aFileReference
]

{ #category : 'class initialization' }
CoCopilotLogger class >> rawLogFileReference [
	"Return the cached main log file reference (may be nil if not initialized)."

	^ logFileReference
]

{ #category : 'class initialization' }
CoCopilotLogger class >> rawLogFileReference: aFileReference [
	"Set the cached main log file reference directly (used by tests)."

	logFileReference := aFileReference
]

{ #category : 'class initialization' }
CoCopilotLogger class >> rawLogsDirectoryReference [
	"Return the cached logs directory reference (may be nil if not initialized)."

	^ logsDirectoryReference
]

{ #category : 'class initialization' }
CoCopilotLogger class >> rawLogsDirectoryReference: aDirectoryReference [
	"Set the cached logs directory reference directly (used by tests)."

	logsDirectoryReference := aDirectoryReference
]
