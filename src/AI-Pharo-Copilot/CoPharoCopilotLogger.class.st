"
CoCopilotLogger is a small, file-based logger for Pharo Copilot.
It writes human-readable sections, completion payloads, evaluation JSONL, and session metadata
inside per-session folders under the `pharo-copilot` directory, when logging is enabled in CopilotSettings.
"
Class {
	#name : 'CoPharoCopilotLogger',
	#superclass : 'Object',
	#classInstVars : [
		'logFileReference',
		'logsDirectoryReference',
		'evaluationLogFileReference',
		'sessionDirectoryReference',
		'sessionArchiveFileReference',
		'sessionArchiveUploader',
		'sessionId',
		'sessionStartedAt',
		'sessionArchived',
		'userId',
		'complishonRerouteCount'
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
    ] forkAt: Processor userBackgroundPriority named: 'Copilot log write'
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> appendEvaluationEvent: eventName data: aDictionary [
	"Append a structured event to the evaluation JSONL file synchronously."

	| event file |
	self loggingEnabled ifFalse: [ ^ self ].

	event := Dictionary new
		at: #event put: eventName;
		at: #userId put: self userId;
		at: #sessionId put: self currentSessionId;
		at: #data put: (aDictionary ifNil: [ Dictionary new ]);
		yourself.

	[
		self ensureEvaluationLogFileInitialized.
		file := self evaluationLogFileReference.
		file writeStreamDo: [ :stream |
			stream setToEnd.
			stream
				nextPutAll: (STONJSON toString: event);
				nextPut: Character lf ]
	] on: Error do: [ :ex |
		Transcript
			show: 'Could not append Copilot evaluation event: ', ex messageText;
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
	^ (self ensureSessionDirectory) / 'completions'
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

{ #category : 'session management' }
CoPharoCopilotLogger class >> ensureSessionDirectory [

	| directory |
	directory := self sessionDirectoryReference.
	self loggingEnabled ifFalse: [ ^ directory ].

	[
		directory ensureCreateDirectory ]
		on: Error
		do: [ :ex |
			Transcript
				show: 'Copilot session log directory could not be created: ', ex messageText;
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
		evaluationLogFileReference := (self ensureSessionDirectory) / self evaluationLogFileName ]
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
		at: #userId put: self userId;
		at: #loggerSessionId put: self currentSessionId;
		at: #cache put: cacheStats;
		at: #completionEnvironment put: (contextInfo at: #completionEnvironment ifAbsent: [ Dictionary new ]);
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
		at: #generated put: (Dictionary new
			at: #suggestions put: ((contextInfo at: #rawSuggestions ifAbsent: [ #() ]) asArray);
			at: #attempts put: ((contextInfo at: #generationAttempts ifAbsent: [ #() ]) asArray);
			at: #semanticGate put: (contextInfo at: #semanticGate ifAbsent: [ Dictionary new ]);
			yourself);
		at: #accepted put: nil;
		at: #acceptedAt put: nil;
		at: #nullCompletion put: false;
		at: #nullCompletionReason put: nil;
		at: #closedAt put: nil;
		at: #rejected put: ((contextInfo at: #rejected ifAbsent: [ #() ]) asArray);
		yourself
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> initialize [

	logFileReference := nil.
	logsDirectoryReference := nil.
	evaluationLogFileReference := nil.
	sessionDirectoryReference := nil.
	sessionArchiveFileReference := nil.
	sessionArchiveUploader := nil.
	sessionId := nil.
	sessionStartedAt := nil.
	sessionArchived := false.
	userId := nil.
	complishonRerouteCount := 0.

	self ensureLogsDirectory.
	self startNewSession
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> instVarNamed: aStringOrSymbol [

	| name |
	name := aStringOrSymbol asSymbol.

	name = #logFileReference ifTrue: [ ^ logFileReference ].
	name = #logsDirectoryReference ifTrue: [ ^ logsDirectoryReference ].
	name = #evaluationLogFileReference ifTrue: [ ^ evaluationLogFileReference ].
	name = #sessionDirectoryReference ifTrue: [ ^ sessionDirectoryReference ].
	name = #sessionArchiveFileReference ifTrue: [ ^ sessionArchiveFileReference ].
	name = #sessionArchiveUploader ifTrue: [ ^ sessionArchiveUploader ].
	name = #sessionId ifTrue: [ ^ sessionId ].
	name = #sessionStartedAt ifTrue: [ ^ sessionStartedAt ].
	name = #sessionArchived ifTrue: [ ^ sessionArchived ].
	name = #userId ifTrue: [ ^ userId ].
	name = #complishonRerouteCount ifTrue: [ ^ complishonRerouteCount ].

	^ super instVarNamed: aStringOrSymbol
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> instVarNamed: aStringOrSymbol put: aValue [

	| name |
	name := aStringOrSymbol asSymbol.

	name = #logFileReference ifTrue: [ logFileReference := aValue. ^ aValue ].
	name = #logsDirectoryReference ifTrue: [ logsDirectoryReference := aValue. ^ aValue ].
	name = #evaluationLogFileReference ifTrue: [ evaluationLogFileReference := aValue. ^ aValue ].
	name = #sessionDirectoryReference ifTrue: [ sessionDirectoryReference := aValue. ^ aValue ].
	name = #sessionArchiveFileReference ifTrue: [ sessionArchiveFileReference := aValue. ^ aValue ].
	name = #sessionArchiveUploader ifTrue: [ sessionArchiveUploader := aValue. ^ aValue ].
	name = #sessionId ifTrue: [ sessionId := aValue. ^ aValue ].
	name = #sessionStartedAt ifTrue: [ sessionStartedAt := aValue. ^ aValue ].
	name = #sessionArchived ifTrue: [ sessionArchived := aValue. ^ aValue ].
	name = #userId ifTrue: [ userId := aValue. ^ aValue ].
	name = #complishonRerouteCount ifTrue: [ complishonRerouteCount := aValue. ^ aValue ].

	^ super instVarNamed: name put: aValue
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> complishonRerouteCount [

	^ complishonRerouteCount ifNil: [ complishonRerouteCount := 0 ]
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
		logFileReference := (self ensureSessionDirectory) / self logFileName ]
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> logFrontEndEvent: eventName details: aDictionary [

	self logSection: 'FRONTEND' event: eventName details: aDictionary
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> logCompletionReroutedToComplishon: aDictionary [

	| details count |
	self loggingEnabled ifFalse: [ ^ self ].

	count := self complishonRerouteCount + 1.
	complishonRerouteCount := count.

	details := Dictionary new.
	(aDictionary notNil and: [ aDictionary respondsTo: #associationsDo ]) ifTrue: [
		aDictionary associationsDo: [ :assoc |
			details at: assoc key put: assoc value ] ].
	details
		at: #oldEngine put: (details at: #oldEngine ifAbsent: [ #Complishon ]);
		at: #rerouteCount put: count.

	self
		logBackEndEvent: 'Completion rerouted to Complishon'
		details: details.
	self
		appendEvaluationEvent: 'completion-rerouted-to-complishon'
		data: details
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
CoPharoCopilotLogger class >> telemetryJsonDirectoryName [

	^ 'pharo-copilot-json'
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> telemetryJsonDirectoryReference [

	| parent |
	parent := self logsDirectoryReference parent.
	parent ifNil: [ parent := FileLocator imageDirectory ].
	^ parent / self telemetryJsonDirectoryName
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> archiveCurrentSession [

	^ self archiveCurrentSessionReportingProgress: nil
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> archiveCurrentSessionReportingProgress: aProgressBlock [

	| directory archiveFile archiveClass archive archivedAt telemetryFile |
	self loggingEnabled ifFalse: [ ^ nil ].

	self
		reportArchiveProgress: aProgressBlock
		status: 'Preparing session archive...'
		percent: 5.

	directory := self ensureSessionDirectory.
	(directory isNil or: [ directory exists not ]) ifTrue: [ ^ nil ].
	archiveFile := self sessionArchiveFileReference.
	archiveFile ifNil: [ ^ nil ].
	archiveClass := Smalltalk globals at: #ZipArchive ifAbsent: [
		self
			reportArchiveProgress: aProgressBlock
			status: 'Cannot archive session: ZipArchive is unavailable.'
			percent: 0.
		self
			logBackEndEvent: 'Could not archive Copilot session'
			details: (Dictionary new
				at: #reason put: 'ZipArchive class is not available';
				at: #sessionDirectory put: directory fullName;
				yourself).
		^ nil ].

	archivedAt := DateAndTime now.
	self
		writeSessionMetadataClosedAt: archivedAt
		archivedAt: archivedAt
		archiveFile: archiveFile.

	^ [
		self
			reportArchiveProgress: aProgressBlock
			status: 'Creating zip archive...'
			percent: 15.
		archiveFile parent ensureCreateDirectory.
		archiveFile exists ifTrue: [ archiveFile ensureDelete ].
		archive := archiveClass new.
		[
			self
				reportArchiveProgress: aProgressBlock
				status: 'Adding session files to archive...'
				percent: 35.
			archive
				addTree: directory
				relativeTo: directory parent
				match: [ :entry | true ].
			self
				reportArchiveProgress: aProgressBlock
				status: 'Writing zip archive...'
				percent: 70.
			archive writeToFile: archiveFile.
			sessionArchived := true.
			self
				reportArchiveProgress: aProgressBlock
				status: 'Writing telemetry summary...'
				percent: 82.
			telemetryFile := self
				writeSessionTelemetrySummaryFor: directory
				archiveFile: archiveFile.
			telemetryFile ifNotNil: [
				self
					reportArchiveProgress: aProgressBlock
					status: 'Uploading telemetry JSON...'
					percent: 90.
				self uploadSessionTelemetrySummary: telemetryFile ].
			self
				reportArchiveProgress: aProgressBlock
				status: 'Session telemetry JSON is complete.'
				percent: 100.
			archiveFile
		] ensure: [
			archive ifNotNil: [ archive close ] ] ]
		on: Error
		do: [ :ex |
			self
				reportArchiveProgress: aProgressBlock
				status: 'Could not archive Copilot session.'
				percent: 0.
			Transcript
				show: 'Could not archive Copilot session: ', ex messageText;
				cr.
			self
				logBackEndEvent: 'Could not archive Copilot session'
				details: (Dictionary new
					at: #errorClass put: ex class name;
					at: #error put: ex description;
					at: #sessionDirectory put: directory fullName;
					yourself).
			nil ]
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> reportArchiveProgress: aProgressBlock status: statusString percent: percentNumber [

	aProgressBlock ifNil: [ ^ self ].

	[
		aProgressBlock value: (Dictionary new
			at: #status put: statusString;
			at: #percent put: percentNumber;
			yourself)
	] on: Error do: [ :ex |
		Transcript
			show: 'Copilot archive progress callback failed: ', ex messageText;
			cr ]
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> archiveFileReferenceForSessionDirectory: aDirectoryReference [

	aDirectoryReference ifNil: [ ^ nil ].
	^ aDirectoryReference parent / (aDirectoryReference basename , '.zip')
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> currentSessionId [

	^ sessionId ifNil: [
		self startNewSession.
		sessionId ]
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

{ #category : 'session management' }
CoPharoCopilotLogger class >> rawSessionArchiveFileReference [

	^ sessionArchiveFileReference
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> rawSessionArchiveFileReference: aFileReference [

	sessionArchiveFileReference := aFileReference
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> rawSessionArchiveUploader [

	^ sessionArchiveUploader
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> rawSessionArchiveUploader: anObject [

	sessionArchiveUploader := anObject
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> rawSessionDirectoryReference [

	^ sessionDirectoryReference
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> rawSessionDirectoryReference: aDirectoryReference [

	sessionDirectoryReference := aDirectoryReference.
	sessionArchiveFileReference := nil.
	logFileReference := nil.
	evaluationLogFileReference := nil.
	sessionId := aDirectoryReference
		ifNil: [ nil ]
		ifNotNil: [ aDirectoryReference basename ].
	sessionStartedAt := aDirectoryReference
		ifNil: [ nil ]
		ifNotNil: [ DateAndTime now ].
	sessionArchived := false.
	complishonRerouteCount := 0
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> rawUserId [

	^ userId
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> rawUserId: aString [

	userId := aString
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> registerSessionHandler [

	| sessionManagerClass manager |
	sessionManagerClass := Smalltalk globals at: #SessionManager ifAbsent: [ ^ false ].
	(sessionManagerClass respondsTo: #default) ifFalse: [ ^ false ].
	manager := sessionManagerClass default.
	(manager respondsTo: #registerUserClassNamed:) ifFalse: [ ^ false ].

	manager registerUserClassNamed: self name.
	^ true
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> sessionArchiveFileReference [

	^ sessionArchiveFileReference ifNil: [
		sessionArchiveFileReference := self archiveFileReferenceForSessionDirectory: self sessionDirectoryReference ]
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> sessionArchiveUploader [

	^ sessionArchiveUploader ifNil: [ CoPCSessionArchiveUploader ]
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> sessionArchiveUploader: anObject [

	sessionArchiveUploader := anObject
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> sessionDirectoryNameForId: aSessionId [

	^ aSessionId asString asFileName
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> sessionDirectoryReference [

	sessionDirectoryReference ifNil: [ self startNewSession ].
	^ sessionDirectoryReference
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> sessionMetadataFileName [

	^ 'session-info.json'
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> sessionMetadataFileReference [

	^ self ensureSessionDirectory / self sessionMetadataFileName
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> sessionsDirectoryName [

	^ 'sessions'
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> sessionsRootDirectoryReference [

	^ self ensureLogsDirectory / self sessionsDirectoryName
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> startNewSession [

	| startedAt newSessionId root |
	self loggingEnabled ifFalse: [ ^ self ].

	startedAt := DateAndTime now.
	newSessionId := self newSessionIdAt: startedAt.
	root := self sessionsRootDirectoryReference.
	root ensureCreateDirectory.

	sessionId := newSessionId.
	sessionStartedAt := startedAt.
	sessionDirectoryReference := root / (self sessionDirectoryNameForId: newSessionId).
	sessionArchiveFileReference := self archiveFileReferenceForSessionDirectory: sessionDirectoryReference.
	sessionArchived := false.
	complishonRerouteCount := 0.
	logFileReference := nil.
	evaluationLogFileReference := nil.

	self ensureSessionDirectory.
	self ensureCompletionsDirectory.
	self ensureLogFileInitialized.
	self ensureEvaluationLogFileInitialized.
	self
		writeSessionMetadataClosedAt: nil
		archivedAt: nil
		archiveFile: nil
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> startUp: isImageStarting [

	isImageStarting ifTrue: [ self startNewSession ]
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> shutDown: isImageQuitting [

	isImageQuitting ifTrue: [ self archiveCurrentSession ]
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> unregisterSessionHandler [

	| sessionManagerClass manager |
	sessionManagerClass := Smalltalk globals at: #SessionManager ifAbsent: [ ^ false ].
	(sessionManagerClass respondsTo: #default) ifFalse: [ ^ false ].
	manager := sessionManagerClass default.
	(manager respondsTo: #unregisterClassNamed:) ifFalse: [ ^ false ].

	manager unregisterClassNamed: self name.
	^ true
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> uploadSessionArchive: archiveFile [

	| uploader |
	archiveFile ifNil: [ ^ self ].
	uploader := self sessionArchiveUploader.
	uploader ifNil: [ ^ self ].

	[
		(uploader respondsTo: #uploadArchive:sessionId:userId:)
			ifTrue: [
				uploader
					uploadArchive: archiveFile
					sessionId: self currentSessionId
					userId: self userId ]
			ifFalse: [
				uploader
					cull: archiveFile
					cull: self currentSessionId
					cull: self userId ] ]
		on: Error
		do: [ :ex |
			Transcript
				show: 'Could not upload Copilot session archive: ', ex messageText;
				cr.
			self
				logBackEndEvent: 'Could not upload Copilot session archive'
				details: (Dictionary new
					at: #errorClass put: ex class name;
					at: #error put: ex description;
					at: #archiveFile put: archiveFile fullName;
					yourself) ]
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> writeSessionTelemetrySummaryFor: sessionDirectory archiveFile: archiveFile [

	^ [
		CoPCSessionTelemetryAnalyzer
			writeSummaryForSessionDirectory: sessionDirectory
			outputDirectory: self telemetryJsonDirectoryReference
			archiveFile: archiveFile
			sessionId: self currentSessionId
			userId: self userId
	] on: Error do: [ :ex |
		Transcript
			show: 'Could not write Copilot telemetry summary: ', ex messageText;
			cr.
		self
			logBackEndEvent: 'Could not write Copilot telemetry summary'
			details: (Dictionary new
				at: #errorClass put: ex class name;
				at: #error put: ex description;
				at: #archiveFile put: (archiveFile ifNil: [ nil ] ifNotNil: [ archiveFile fullName ]);
				yourself).
		nil ]
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> uploadSessionTelemetrySummary: summaryFile [

	| uploader |
	summaryFile ifNil: [ ^ self ].
	uploader := self sessionArchiveUploader.
	uploader ifNil: [ ^ self ].
	(uploader respondsTo: #uploadTelemetrySummary:sessionId:userId:) ifFalse: [ ^ self ].

	[
		uploader
			uploadTelemetrySummary: summaryFile
			sessionId: self currentSessionId
			userId: self userId
	] on: Error do: [ :ex |
		Transcript
			show: 'Could not upload Copilot telemetry summary: ', ex messageText;
			cr.
		self
			logBackEndEvent: 'Could not upload Copilot telemetry summary'
			details: (Dictionary new
				at: #errorClass put: ex class name;
				at: #error put: ex description;
				at: #summaryFile put: summaryFile fullName;
				yourself) ]
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> userId [

	self loggingEnabled ifFalse: [ ^ userId ].
	^ userId ifNil: [ userId := self userIdFromDiskOrCreate ]
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> userIdFileName [

	^ 'user-id.txt'
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> userIdFileReference [

	^ self ensureLogsDirectory / self userIdFileName
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> userIdFromDiskOrCreate [

	| file existing created |
	file := self userIdFileReference.
	(file exists and: [ file isFile ]) ifTrue: [
		existing := [ file contents trimBoth ] on: Error do: [ '' ].
		existing isEmpty ifFalse: [ ^ existing ] ].

	created := self newUserIdAt: DateAndTime now.
	[
		self ensureFileExists: file.
		file writeStreamDo: [ :stream | stream nextPutAll: created ] ]
		on: Error
		do: [ :ex |
			Transcript
				show: 'Could not persist Copilot user id: ', ex messageText;
				cr ].
	^ created
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> newSessionIdAt: aDateAndTime [

	^ 'session-' , aDateAndTime asUnixTime asString , '-' , UUID new asString36
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> newUserIdAt: aDateAndTime [

	^ 'user-' , UUID new asString36 , '-' , aDateAndTime asUnixTime asString
]

{ #category : 'session management' }
CoPharoCopilotLogger class >> writeSessionMetadataClosedAt: closedAt archivedAt: archivedAt archiveFile: archiveFile [

	| payload file |
	self loggingEnabled ifFalse: [ ^ self ].
	sessionDirectoryReference ifNil: [ ^ self ].

	payload := Dictionary new
		at: #userId put: self userId;
		at: #sessionId put: self currentSessionId;
		at: #startedAt put: (sessionStartedAt ifNil: [ nil ] ifNotNil: [ sessionStartedAt asString ]);
		at: #closedAt put: (closedAt ifNil: [ nil ] ifNotNil: [ closedAt asString ]);
		at: #archivedAt put: (archivedAt ifNil: [ nil ] ifNotNil: [ archivedAt asString ]);
		at: #archiveFile put: (archiveFile ifNil: [ nil ] ifNotNil: [ archiveFile fullName ]);
		at: #sessionDirectory put: sessionDirectoryReference fullName;
		at: #logFile put: self logFileName;
		at: #evaluationLogFile put: self evaluationLogFileName;
		at: #completionsDirectory put: 'completions';
		at: #modelName put: CopilotSettings modelName;
		yourself.

	file := self sessionMetadataFileReference.
	self ensureFileExists: file.
	file writeStreamDo: [ :stream |
		stream nextPutAll: (STONJSON toString: payload) ]
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
	payload at: #acceptedAt put: DateAndTime now asString.
	payload at: #nullCompletion put: false.
	payload at: #nullCompletionReason put: nil.
	file writeStreamDo: [ :stream |
		stream nextPutAll: (STONJSON toString: payload) ]
]

{ #category : 'class initialization' }
CoPharoCopilotLogger class >> updateCompletionSession: aSessionId withNullCompletionReason: aReason [
	| file payload accepted reason |
	self loggingEnabled ifFalse: [ ^ self ].
	file := self completionFileReferenceFor: aSessionId.
	file exists ifFalse: [ ^ self ].
	payload := STONJSON fromString: file contents.
	accepted := payload at: #accepted ifAbsent: [ nil ].
	(accepted isString
		ifTrue: [ accepted trimBoth isEmpty not ]
		ifFalse: [ accepted notNil ]) ifTrue: [ ^ self ].
	reason := aReason
		ifNil: [ 'closed' ]
		ifNotNil: [ aReason asString ].
	payload at: #nullCompletion put: true.
	payload at: #nullCompletionReason put: reason.
	payload at: #closedAt put: DateAndTime now asString.
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
