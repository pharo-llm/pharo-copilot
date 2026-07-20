"
View current statistics:
   CoSuggestionEvaluator default sessionStats inspect

2. Generate a report:
   CoSuggestionEvaluator default generateReport inspect

3. Export to CSV:
   CoSuggestionEvaluator default exportToCSV: 'my-evaluation.csv'

4. Manually mark a suggestion as rejected:
   suggestion markAsRejected: context reason: 'Incorrect syntax'

5. Check acceptance rate:
   CoSuggestionEvaluator default acceptanceRate

6. View accepted suggestions:
   CoSuggestionEvaluator default acceptedEntries inspect

7. View rejected suggestions:
   CoSuggestionEvaluator default rejectedEntries inspect
"
Class {
	#name : 'CoPCSuggestionEvaluator',
	#superclass : 'Object',
	#instVars : [
		'acceptedEntries',
		'rejectedEntries',
		'sessionStats',
		'persistentStats'
	],
	#classInstVars : [
		'default'
	],
	#category : 'AI-Pharo-Copilot-Evaluator',
	#package : 'AI-Pharo-Copilot-Evaluator'
}

{ #category : 'accessing' }
CoPCSuggestionEvaluator class >> default [
	^ default ifNil: [ default := self new ]
]

{ #category : 'accessing' }
CoPCSuggestionEvaluator class >> reset [
	<script>
	default := nil
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> acceptanceRate [

	| total accepted |
	total := sessionStats at: #totalSuggestions ifAbsent: [ 0 ].
	total = 0 ifTrue: [ ^ 0 ].
	accepted := sessionStats at: #totalAccepted ifAbsent: [ 0 ].
	^ (accepted / total * 100) rounded
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> acceptedEntries [
	^ acceptedEntries
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> announceEvaluation: anEvaluationEntry [
	"Send announcement for potential model training/improvement"
	SystemAnnouncer uniqueInstance announce: (CoPCEvaluationAnnouncement new
		entry: anEvaluationEntry;
		yourself)
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> appendEvaluationEntry: anEvaluationEntry [
	| evaluationFile data safeData |
	CoPharoCopilotLogger loggingEnabled ifFalse: [ ^ self ].

	evaluationFile := CoPharoCopilotLogger evaluationLogFileReference.
	data := Dictionary new
		at: #timestamp put: anEvaluationEntry timestamp;
		at: #action put: anEvaluationEntry action asString;
		at: #suggestion put: anEvaluationEntry suggestion contents;
		at: #contextType put: (self determineContextType: anEvaluationEntry context);
		at: #modelName put: CopilotSettings modelName;
		at: #rejectionReason put: anEvaluationEntry rejectionReason;
		yourself.

	safeData := self jsonSafeObject: data.

	[
		CoPharoCopilotLogger ensureEvaluationLogFileInitialized.
		evaluationFile writeStreamDo: [ :stream |
			stream setToEnd.
			stream nextPutAll: (STONJSON toString: safeData).
			stream nextPut: Character lf ] ]
		on: Error
		do: [ :ex |
			Transcript
				show: 'Could not append evaluation entry: ', ex messageText;
				cr ]
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> conditionSelectors [
	^ #(' ifTrue:' ' ifFalse:' ' ifNil:' ' ifNotNil:' ' ifEmpty:' ' ifNotEmpty:' ' ifPresent:' ' ifAbsent:').

]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> determineContextType: aContext [

        | src |
        aContext isNil ifTrue: [ ^ #other ].
        src := (aContext respondsTo: #source)
                ifTrue: [ [ aContext source ] on: Error do: [ nil ] ]
                ifFalse: [ aContext ].
        src ifNil: [ ^ #other ].
        (src respondsTo: #asString) ifFalse: [ ^ #other ].
        src := (src asString) trimBoth.
        src isEmpty ifTrue: [ ^ #other ].

        (self isClassDef: src)         ifTrue: [ ^ #classDef ].
        (self isMethodDef: src)        ifTrue: [ ^ #method ].
        (self hasTopLevel: '^' in: src)    ifTrue: [ ^ #return ].
        (self hasTopLevel: ':=' in: src)   ifTrue: [ ^ #assignment ].
        (self hasAnyTopLevel: self iterationSelectors in: src)
                                          ifTrue: [ ^ #iteration ].
        (self hasAnyTopLevel: self conditionSelectors in: src)
                                          ifTrue: [ ^ #condition ].
        ^ #other
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> exportToCSV: filename [
	"Export evaluation data to CSV for external analysis"
	| entries |
	entries := OrderedCollection new.
	entries addAll: acceptedEntries.
	entries addAll: rejectedEntries.
	
	filename asFileReference writeStreamDo: [ :stream |
		"Header"
		stream nextPutAll: 'Timestamp,Action,Suggestion,Context,Model,Length,Reason'; lf.
		
		"Data rows"
		entries do: [ :entry |
			stream 
				nextPutAll: entry timestamp asString; nextPut: $,;
				nextPutAll: entry action asString; nextPut: $,;
				nextPutAll: '"', (entry suggestion contents copyReplaceAll: '"' with: '""'), '"'; nextPut: $,;
				nextPutAll: '"', (entry context source copyFrom: 1 to: (50 min: entry context source size)), '"'; nextPut: $,;
				nextPutAll: CopilotSettings modelName; nextPut: $,;
				nextPutAll: entry suggestion contents size asString; nextPut: $,;
				nextPutAll: (entry rejectionReason ifNil: [ '' ]); lf ] ]
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> generateReport [
	"Generate a comprehensive evaluation report"
	^ CoPCEvaluationReport new
		evaluator: self;
		generate
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> hasAnyTopLevel: tokens in: src [
	^ tokens anySatisfy: [ :tok | self hasTopLevel: tok in: src ].

]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> hasTopLevel: token in: src [
"Find TOKEN only when not inside (), [], {}, strings (''...''), or comments (""..."" )."
        | stream depthPar depthBracket depthBrace inStr inCmt quote lookAhead |
        src ifNil: [ ^ false ].
        stream := ReadStream on: src asString.
        depthPar := depthBracket := depthBrace := 0.
        inStr := false.
        inCmt := false.
        quote := $'.
        [ stream atEnd ] whileFalse: [
                | ch |
                ch := stream next.
                inCmt ifTrue: [
                        ch = $" ifTrue: [ inCmt := false ].
                ] ifFalse: [
                        inStr ifTrue: [
                                ch = quote ifTrue: [
                                        (stream atEnd not and: [ stream peek = quote ])
                                                ifTrue: [ stream next ] "escaped quote"
                                                ifFalse: [ inStr := false ] ].
                        ] ifFalse: [
                                ch = $" ifTrue: [ inCmt := true ].
                                ch = quote ifTrue: [ inStr := true ].
                                ch = $( ifTrue: [ depthPar := depthPar + 1 ].
                                ch = $) ifTrue: [ depthPar := (depthPar - 1) max: 0 ].
                                ch = $[ ifTrue: [ depthBracket := depthBracket + 1 ].
                                ch = $] ifTrue: [ depthBracket := (depthBracket - 1) max: 0 ].
                                ch = ${ ifTrue: [ depthBrace := depthBrace + 1 ].
                                ch = $} ifTrue: [ depthBrace := (depthBrace - 1) max: 0 ].
                                (depthPar = 0 and: [ depthBracket = 0 and: [ depthBrace = 0 ]]) ifTrue: [
                                        lookAhead := stream position.
                                        (src findString: token startingAt: lookAhead) = lookAhead ifTrue: [ ^ true ] ] ] ].
        ].
        ^ false
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> initialize [

	super initialize.
	acceptedEntries := OrderedCollection new.
	rejectedEntries := OrderedCollection new.
	sessionStats := Dictionary new.
	self initializeStats.
	self loadPersistentStats.
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> initializeStats [ 
	sessionStats
		at: #totalSuggestions put: 0;
		at: #totalAccepted put: 0;
		at: #totalRejected put: 0;
		at: #sessionStartTime put: DateAndTime now;
		at: #modelStats put: Dictionary new;
		at: #contextStats put: Dictionary new;
		at: #lengthStats put: Dictionary new.
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> isClassDef: src [

	        | normalized |
        normalized := src asString.
        ^ ((normalized findString: 'Class {' startingAt: 1) > 0)
          and: [ (normalized findString: '#name' startingAt: 1) > 0 ]
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> isMethodDef: src [
	"e.g., 'method: arg { #category : ''accessing'' } ...'"
	^ (src findString: '{' startingAt: 1) > 0
	  and: [ (src findString: '#category' startingAt: 1) > 0 ].
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> iterationSelectors [
	^ #(' do:' ' collect:' ' select:' ' reject:' ' detect:' ' inject:into:'
	    ' anySatisfy:' ' allSatisfy:' ' noneSatisfy:' ' withIndexDo:' ' keysAndValuesDo:' ' timesRepeat:').
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> jsonSafeObject: anObject [
        anObject isNil ifTrue: [ ^ nil ].

        (anObject isString or: [ anObject isKindOf: Text ]) ifTrue: [ ^ anObject asString ].
        (anObject isKindOf: DateAndTime) ifTrue: [ ^ anObject asString ].
        (anObject isKindOf: Number) ifTrue: [ ^ anObject ].
        (anObject isKindOf: Boolean) ifTrue: [ ^ anObject ].

        (anObject isKindOf: Dictionary) ifTrue: [
                | jsonDict |
                jsonDict := Dictionary new.
                anObject keysAndValuesDo: [ :key :value |
                        | jsonKey |
                        jsonKey := key ifNil: [ 'nil' ] ifNotNil: [ key asString ].
                        jsonDict at: jsonKey put: (self jsonSafeObject: value) ].
                ^ jsonDict ].

        (anObject isKindOf: SequenceableCollection) ifTrue: [
                ^ anObject collect: [ :each | self jsonSafeObject: each ] ].

        (anObject isKindOf: Set) ifTrue: [
                ^ anObject asArray collect: [ :each | self jsonSafeObject: each ] ].

        (anObject respondsTo: #asString) ifTrue: [ ^ anObject asString ].

        ^ anObject printString
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> loadPersistentStats [
	"Load previous evaluation data if available"
CoPharoCopilotLogger loggingEnabled ifFalse: [ ^ self ].
	[
		| evaluationFile |
		evaluationFile := CoPharoCopilotLogger evaluationLogFileReference.

		(evaluationFile exists and: [ evaluationFile isFile ]) ifTrue: [
				persistentStats := OrderedCollection new.
				evaluationFile readStreamDo: [ :stream |
						[ stream atEnd ] whileFalse: [
								| line |
								line := stream nextLine.
								(line isNil or: [ line isEmpty ]) ifFalse: [
										[ persistentStats add: (STONJSON fromString: line) ]
											on: Error
											do: [ "Ignore invalid entries" ] ] ] ] ] ]
		on: Error
		do: [ "Ignore if can't access files" ]
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> recordSuggestionAccepted: aCopilotEntry context: aCompletionContext [
	| evaluationEntry |
	
	evaluationEntry := CoPCEvaluationEntry new
		suggestion: aCopilotEntry;
		context: aCompletionContext;
		timestamp: DateAndTime now;
		action: #accepted;
		yourself.
	
	acceptedEntries add: evaluationEntry.
	self updateStats: evaluationEntry.
	self recordTelemetryForEvaluationEntry: evaluationEntry.
	self savePersistentStats.
	
	"Notify for potential model improvement"
	self announceEvaluation: evaluationEntry.
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> recordSuggestionIgnored: aCopilotEntry context: aCompletionContext [
	| evaluationEntry |
	
	evaluationEntry := CoPCEvaluationEntry new
		suggestion: aCopilotEntry;
		context: aCompletionContext;
		timestamp: DateAndTime now;
		action: #ignored;
		yourself.
	
	"For ignored suggestions, we don't add to either collection but update stats"
	self updateStats: evaluationEntry.
	self recordTelemetryForEvaluationEntry: evaluationEntry.
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> recordSuggestionRejected: aCopilotEntry context: aCompletionContext reason: aString [

	| evaluationEntry |
	evaluationEntry := CoPCEvaluationEntry new
		suggestion: aCopilotEntry;
		context: aCompletionContext;
		timestamp: DateAndTime now;
		action: #rejected;
		rejectionReason: aString;
		yourself.
	rejectedEntries add: evaluationEntry.
	self updateStats: evaluationEntry.
	self recordTelemetryForEvaluationEntry: evaluationEntry.
	self savePersistentStats.
	self announceEvaluation: evaluationEntry.
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> recordTelemetryForEvaluationEntry: anEvaluationEntry [

	[
		CoPharoCopilotTelemetry
			recordEvent: 'suggestion-evaluated'
			details: (self telemetryDetailsForEvaluationEntry: anEvaluationEntry)
	] on: Error do: [ :ignored | ]
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> rejectedEntries [
	^ rejectedEntries
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> rejectionRate [

	| total rejected |
	total := sessionStats at: #totalSuggestions ifAbsent: [ 0 ].
	total = 0 ifTrue: [ ^ 0 ].
	rejected := sessionStats at: #totalRejected ifAbsent: [ 0 ].
	^ (rejected / total * 100) rounded
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> savePersistentStats [
	"Save evaluation data to file for long-term analysis"
        | evaluationFile data |
        CoPharoCopilotLogger loggingEnabled ifFalse: [ ^ self ].

        evaluationFile := CoPharoCopilotLogger evaluationLogFileReference.
        data := Dictionary new
                        at: #acceptedCount put: acceptedEntries size;
		        at: #rejectedCount put: rejectedEntries size;
		        at: #sessionStats put: sessionStats;
		        at: #timestamp put: DateAndTime now;
		        at: #modelName put: CopilotSettings modelName;
		        yourself.

	[
		CoPharoCopilotLogger ensureEvaluationLogFileInitialized.
		evaluationFile writeStreamDo: [ :stream |
				| safeData |
				safeData := self jsonSafeObject: data.
				stream setToEnd.
				stream nextPutAll: (STONJSON toString: safeData).
				stream nextPut: Character lf ] ]
		on: Error
		do: [ :ex | "Silently ignore file write errors"
				Transcript
					show: 'Could not save evaluation stats: ' , ex messageText;
					cr ]
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> sessionStats [
	^ sessionStats
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> telemetryDetailsForEvaluationEntry: anEvaluationEntry [
	"Answer sanitized telemetry. Do not include source code, prompts, generated
	completions, or the raw suggestion text."

	| suggestion suggestionLength |
	suggestion := anEvaluationEntry suggestion.
	suggestionLength := suggestion
		ifNil: [ 0 ]
		ifNotNil: [
			[ (suggestion contents ifNil: [ '' ]) size ]
				on: Error
				do: [ :ignored | 0 ] ].

	^ Dictionary new
		at: #timestamp put: anEvaluationEntry timestamp asString;
		at: #action put: anEvaluationEntry action asString;
		at: #contextType put: (self determineContextType: anEvaluationEntry context) asString;
		at: #modelName put: CopilotSettings modelName;
		at: #suggestionLength put: suggestionLength;
		at: #rejectionReason put: anEvaluationEntry rejectionReason;
		yourself
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> updateLengthStats: length action: action [
        | bucket lengthStats bucketStats |
        bucket := length <= 10
                ifTrue: [ #short ]
                ifFalse: [ length <= 50 ifTrue: [ #medium ] ifFalse: [ #long ] ].

        lengthStats := sessionStats at: #lengthStats ifAbsentPut: [ Dictionary new ].
        bucketStats := lengthStats at: bucket ifAbsentPut: [ Dictionary new
                at: #accepted put: 0;
                at: #rejected put: 0;
                at: #ignored put: 0;
                yourself ].
        bucketStats
                at: action
                put: ((bucketStats at: action ifAbsent: [ 0 ]) + 1).
]

{ #category : 'initialization' }
CoPCSuggestionEvaluator >> updateStats: anEvaluationEntry [
        | modelName contextType suggestion suggestionLength |

        sessionStats
                at: #totalSuggestions
                put: (sessionStats at: #totalSuggestions ifAbsent: [ 0 ]) + 1.

        anEvaluationEntry action = #accepted ifTrue: [
                sessionStats
                        at: #totalAccepted
                        put: (sessionStats at: #totalAccepted ifAbsent: [ 0 ]) + 1 ].

        anEvaluationEntry action = #rejected ifTrue: [
                sessionStats
                        at: #totalRejected
                        put: (sessionStats at: #totalRejected ifAbsent: [ 0 ]) + 1 ].

        "Update model-specific stats"
        modelName := CopilotSettings modelName.
        ((sessionStats at: #modelStats ifAbsentPut: [ Dictionary new ])
                at: modelName
                ifAbsentPut: [ Dictionary new
                        at: #accepted put: 0;
                        at: #rejected put: 0;
                        at: #ignored put: 0;
                        yourself ])
                at: anEvaluationEntry action
                put: (((sessionStats at: #modelStats) at: modelName)
                        at: anEvaluationEntry action
                        ifAbsent: [ 0 ]) + 1.

        "Update context-type stats"
        contextType := self determineContextType: anEvaluationEntry context.
        ((sessionStats at: #contextStats ifAbsentPut: [ Dictionary new ])
                at: contextType
                ifAbsentPut: [ Dictionary new
                        at: #accepted put: 0;
                        at: #rejected put: 0;
                        at: #ignored put: 0;
                        yourself ])
                at: anEvaluationEntry action
                put: (((sessionStats at: #contextStats) at: contextType)
                        at: anEvaluationEntry action
                        ifAbsent: [ 0 ]) + 1.

        "Update length stats"
        suggestion := anEvaluationEntry suggestion.
        suggestionLength := suggestion
                ifNil: [ 0 ]
                ifNotNil: [ (suggestion contents ifNil: [ '' ]) size ].
        self updateLengthStats: suggestionLength action: anEvaluationEntry action.
]
