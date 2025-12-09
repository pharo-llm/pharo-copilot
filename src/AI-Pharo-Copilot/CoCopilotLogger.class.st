"
Logger
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
self loggingEnabled ifFalse: [ ^ self ].
	[
		| file |
		file := self logFileReference.
		file ensureCreateFile.
		file writeStreamDo: [ :stream |
				stream setToEnd.
				lines do: [ :line |
						stream nextPutAll: line.
						stream nextPut: Character lf ] ] ]
		on: Error
		do: [ :ex |
				Transcript
					show: 'Copilot logging failed: ' , ex messageText;
					cr ]
]

{ #category : 'class initialization' }
CoCopilotLogger class >> ensureEvaluationLogFileInitialized [

	self loggingEnabled ifFalse: [ ^ self ].
        [ | file |
                file := self evaluationLogFileReference.
                file parent ifNotNil: [ :parent | parent ensureCreateDirectory ].
                file ensureCreateFile ]
                on: Error
                do: [ :ex |
                                Transcript
                                        show: 'Copilot evaluation log file could not be created: ' , ex messageText;
                                        cr ]
]

{ #category : 'class initialization' }
CoCopilotLogger class >> ensureLogFileInitialized [

	self loggingEnabled ifFalse: [ ^ self ].
        [ | file |
                file := self logFileReference.
                file parent ifNotNil: [ :parent | parent ensureCreateDirectory ].
                file ensureCreateFile ]
                on: Error
                do: [ :ex |
                                Transcript
                                        show: 'Copilot log file could not be created: ' , ex messageText;
                                        cr ]
]

{ #category : 'class initialization' }
CoCopilotLogger class >> ensureLogsDirectory [

	| directory |
	self loggingEnabled ifFalse: [ ^ self logsDirectoryReference ].
	directory := self logsDirectoryReference.
	[
		directory directory parent ensureCreateDirectory.
		directory ensureCreateDirectory ]
		on: Error
		do: [ :ex |
				Transcript
					show: 'Copilot log directory could not be created: ' , ex messageText;
					cr ].
	^ directory
]

{ #category : 'class initialization' }
CoCopilotLogger class >> evaluationLogFileName [
        ^ 'copilot-evaluation-log.jsonl'
]

{ #category : 'class initialization' }
CoCopilotLogger class >> evaluationLogFileReference [
        ^ evaluationLogFileReference ifNil: [
                evaluationLogFileReference := (self ensureLogsDirectory)
                        / self evaluationLogFileName ]
]

{ #category : 'class initialization' }
CoCopilotLogger class >> evaluationLogFileReference: aFileReference [
        evaluationLogFileReference := aFileReference
]

{ #category : 'class initialization' }
CoCopilotLogger class >> formatValue: anObject [

        anObject isNil ifTrue: [ ^ 'nil' ].
        (anObject isString or: [ anObject isKindOf: Text ]) ifTrue: [ ^ anObject asString ].
        ((anObject isKindOf: Dictionary)
                or: [ anObject isKindOf: SequenceableCollection ]) ifTrue: [
                        [ ^ STONJSON toString: anObject ]
                                on: Error
                                do: [ :ex | ^ anObject printString ] ].
        (anObject respondsTo: #asString) ifTrue: [
                [ ^ anObject asString ]
                        on: Error
                        do: [ :ex | ^ anObject printString ] ].
        ^ anObject printString
]

{ #category : 'class initialization' }
CoCopilotLogger class >> initialize [
	logFileReference := nil.
	        logsDirectoryReference := nil.
        evaluationLogFileReference := nil.
        self ensureLogsDirectory.
        self ensureLogFileInitialized.
        self ensureEvaluationLogFileInitialized
]

{ #category : 'introspection' }
CoCopilotLogger class >> instVarNamed: aStringOrSymbol [ 

        | name |
        name := aStringOrSymbol asSymbol.
        name = #logFileReference ifTrue: [ ^ logFileReference ].
        name = #logsDirectoryReference ifTrue: [ ^ logsDirectoryReference ].
        name = #evaluationLogFileReference ifTrue: [ ^ evaluationLogFileReference ].
        ^ super instVarNamed: aStringOrSymbol
]

{ #category : 'introspection' }
CoCopilotLogger class >> instVarNamed: aStringOrSymbol put: aValue [

        | name |
        name := aStringOrSymbol asSymbol.
        name = #logFileReference ifTrue: [
                        logFileReference := aValue.
                        ^ aValue ].
        name = #logsDirectoryReference ifTrue: [
                        logsDirectoryReference := aValue.
                        ^ aValue ].
        name = #evaluationLogFileReference ifTrue: [
                        evaluationLogFileReference := aValue.
                        ^ aValue ].
        ^ super instVarNamed: name put: aValue
]

{ #category : 'class initialization' }
CoCopilotLogger class >> logBackEndEvent: eventName details: aDictionary [ 
        self logSection: 'BACKEND' event: eventName details: aDictionary
]

{ #category : 'class initialization' }
CoCopilotLogger class >> logError: eventName origin: originSymbol exception: anException payload: aDictionary [
    | details |
    details := (aDictionary ifNil: [ Dictionary new ]) copy.
    details
        at: #origin put: (self formatValue: originSymbol);
        at: #error put: (anException ifNil: [ 'Unknown error' ] ifNotNil: [ anException messageText ]).
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
                    do: [ :ignored | "Fail silently" ] ] ].
    self logSection: 'ERROR' event: eventName details: details

]

{ #category : 'class initialization' }
CoCopilotLogger class >> logFileName [

	^ 'copilot.log'
]

{ #category : 'class initialization' }
CoCopilotLogger class >> logFileReference [

	^ logFileReference ifNil: [
                logFileReference := (self ensureLogsDirectory) / self logFileName ]
]

{ #category : 'class initialization' }
CoCopilotLogger class >> logFrontEndEvent: eventName details: aDictionary [
        self logSection: 'FRONTEND' event: eventName details: aDictionary
]

{ #category : 'class initialization' }
CoCopilotLogger class >> logSection: sectionName event: eventName details: aDictionary [

	| timestamp lines |
	self loggingEnabled ifFalse: [ ^ self ].
	timestamp := DateAndTime now asString.
	lines := OrderedCollection new. "Blank line before section"
	lines add: ''. "Header line"
	lines add: (String streamContents: [ :stream |
				 stream
					 nextPutAll: '===== [';
					 nextPutAll: sectionName;
					 nextPutAll: '] ';
					 nextPutAll: eventName;
					 nextPutAll: ' @ ';
					 nextPutAll: timestamp;
					 nextPutAll: ' =====' ]). "Details, if any"
	(aDictionary isNil or: [ aDictionary isEmpty ]) ifFalse: [
			(aDictionary respondsTo: #associationsDo)
				ifTrue: [ aDictionary associationsDo: [ :assoc | self appendDetailAssociation: assoc to: lines ] ]
				ifFalse: [ self appendDetailAssociation: aDictionary -> '' to: lines ] ]. "Blank line after section"
	lines add: ''.

	self appendLines: lines
]

{ #category : 'class initialization' }
CoCopilotLogger class >> loggingEnabled [

    ^ CopilotSettings loggingEnabled
]

{ #category : 'class initialization' }
CoCopilotLogger class >> logsDirectoryName [
        ^ self pharoCopilotDirectoryName
]

{ #category : 'class initialization' }
CoCopilotLogger class >> logsDirectoryReference [
        ^ logsDirectoryReference ifNil: [
                logsDirectoryReference := FileLocator imageDirectory
                        / self pharoCopilotDirectoryName ]
]

{ #category : 'class initialization' }
CoCopilotLogger class >> pharoCopilotDirectoryName [
        ^ 'pharo-copilot'
]

{ #category : 'class initialization' }
CoCopilotLogger class >> rawEvaluationLogFileReference [

        ^ evaluationLogFileReference
]

{ #category : 'class initialization' }
CoCopilotLogger class >> rawEvaluationLogFileReference: aFileReference [

        evaluationLogFileReference := aFileReference
]

{ #category : 'class initialization' }
CoCopilotLogger class >> rawLogFileReference [

        ^ logFileReference
]

{ #category : 'class initialization' }
CoCopilotLogger class >> rawLogFileReference: aFileReference [

        logFileReference := aFileReference
]

{ #category : 'class initialization' }
CoCopilotLogger class >> rawLogsDirectoryReference [

        ^ logsDirectoryReference
]

{ #category : 'class initialization' }
CoCopilotLogger class >> rawLogsDirectoryReference: aDirectoryReference [

        logsDirectoryReference := aDirectoryReference
]
