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
	#name : 'CoSuggestionEvaluator',
	#superclass : 'Object',
	#instVars : [
		'acceptedEntries',
		'rejectedEntries',
		'sessionStats'
	],
	#classInstVars : [
		'default'
	],
	#category : 'AI-Pharo-Copilot-Evaluator',
	#package : 'AI-Pharo-Copilot-Evaluator'
}

{ #category : 'accessing' }
CoSuggestionEvaluator class >> default [
	^ default ifNil: [ default := self new ]
]

{ #category : 'accessing' }
CoSuggestionEvaluator class >> reset [
	<script>
	default := nil
]

{ #category : 'initialization' }
CoSuggestionEvaluator >> acceptanceRate [

	| total accepted |
	total := sessionStats at: #totalSuggestions ifAbsent: [ 0 ].
	total = 0 ifTrue: [ ^ 0 ].
	accepted := sessionStats at: #totalAccepted ifAbsent: [ 0 ].
	^ (accepted / total * 100) rounded
]

{ #category : 'initialization' }
CoSuggestionEvaluator >> acceptedEntries [
	^ acceptedEntries
]

{ #category : 'initialization' }
CoSuggestionEvaluator >> announceEvaluation: anEvaluationEntry [
	"Send announcement for potential model training/improvement"
	SystemAnnouncer uniqueInstance announce: (CoEvaluationAnnouncement new
		entry: anEvaluationEntry;
		yourself)
]

{ #category : 'initialization' }
CoSuggestionEvaluator >> conditionSelectors [
	^ #(' ifTrue:' ' ifFalse:' ' ifNil:' ' ifNotNil:' ' ifEmpty:' ' ifNotEmpty:' ' ifPresent:' ' ifAbsent:').

]

{ #category : 'initialization' }
CoSuggestionEvaluator >> determineContextType: aContext [

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
CoSuggestionEvaluator >> exportToCSV: filename [
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
CoSuggestionEvaluator >> generateReport [
	"Generate a comprehensive evaluation report"
	^ CoEvaluationReport new
		evaluator: self;
		generate
]

{ #category : 'initialization' }
CoSuggestionEvaluator >> hasAnyTopLevel: tokens in: src [
	^ tokens anySatisfy: [ :tok | self hasTopLevel: tok in: src ].

]

{ #category : 'initialization' }
CoSuggestionEvaluator >> hasTopLevel: token in: src [
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
CoSuggestionEvaluator >> initialize [

	super initialize.
	acceptedEntries := OrderedCollection new.
	rejectedEntries := OrderedCollection new.
	sessionStats := Dictionary new.
	self initializeStats.
]

{ #category : 'initialization' }
CoSuggestionEvaluator >> initializeStats [ 
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
CoSuggestionEvaluator >> isClassDef: src [

	        | normalized |
        normalized := src asString.
        ^ ((normalized findString: 'Class {' startingAt: 1) > 0)
          and: [ (normalized findString: '#name' startingAt: 1) > 0 ]
]

{ #category : 'initialization' }
CoSuggestionEvaluator >> isMethodDef: src [
	"e.g., 'method: arg { #category : ''accessing'' } ...'"
	^ (src findString: '{' startingAt: 1) > 0
	  and: [ (src findString: '#category' startingAt: 1) > 0 ].
]

{ #category : 'initialization' }
CoSuggestionEvaluator >> iterationSelectors [
	^ #(' do:' ' collect:' ' select:' ' reject:' ' detect:' ' inject:into:'
	    ' anySatisfy:' ' allSatisfy:' ' noneSatisfy:' ' withIndexDo:' ' keysAndValuesDo:' ' timesRepeat:').
]

{ #category : 'initialization' }
CoSuggestionEvaluator >> recordSuggestionAccepted: aCopilotEntry context: aCompletionContext [
	| evaluationEntry |
	
	evaluationEntry := CoEvaluationEntry new
		suggestion: aCopilotEntry;
		context: aCompletionContext;
		timestamp: DateAndTime now;
		action: #accepted;
		yourself.
	
	acceptedEntries add: evaluationEntry.
	self updateStats: evaluationEntry.
	
	"Notify for potential model improvement"
	self announceEvaluation: evaluationEntry.
]

{ #category : 'initialization' }
CoSuggestionEvaluator >> recordSuggestionIgnored: aCopilotEntry context: aCompletionContext [
	| evaluationEntry |
	
	evaluationEntry := CoEvaluationEntry new
		suggestion: aCopilotEntry;
		context: aCompletionContext;
		timestamp: DateAndTime now;
		action: #ignored;
		yourself.
	
	"For ignored suggestions, we don't add to either collection but update stats"
	self updateStats: evaluationEntry.
]

{ #category : 'initialization' }
CoSuggestionEvaluator >> rejectedEntries [
	^ rejectedEntries
]

{ #category : 'initialization' }
CoSuggestionEvaluator >> rejectionRate [

	| total rejected |
	total := sessionStats at: #totalSuggestions ifAbsent: [ 0 ].
	total = 0 ifTrue: [ ^ 0 ].
	rejected := sessionStats at: #totalRejected ifAbsent: [ 0 ].
	^ (rejected / total * 100) rounded
]

{ #category : 'initialization' }
CoSuggestionEvaluator >> sessionStats [
	^ sessionStats
]

{ #category : 'initialization' }
CoSuggestionEvaluator >> updateLengthStats: length action: action [
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
CoSuggestionEvaluator >> updateStats: anEvaluationEntry [
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
