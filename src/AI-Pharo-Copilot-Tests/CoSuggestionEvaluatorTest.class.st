Class {
	#name : 'CoSuggestionEvaluatorTest',
	#superclass : 'TestCase',
	#instVars : [
		'evaluator'
	],
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
CoSuggestionEvaluatorTest >> setUp [
	super setUp.
	evaluator := CoPCSuggestionEvaluator new
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testAcceptanceRateCalculation [

	| context entry |
	context := CoPCContext new. 
	entry := CoCopilotEntry contents: 'test1'.
	evaluator recordSuggestionAccepted: entry context: context.

	entry := CoCopilotEntry contents: 'test2'.
	evaluator recordSuggestionAccepted: entry context: context. 
	self assert: evaluator acceptanceRate equals: 100. 
evaluator recordSuggestionRejected: (CoCopilotEntry contents: 'test3') context: context reason: 'Incorrect syntax'.
	
	self assert: evaluator acceptanceRate equals: 67
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testAcceptanceRateWithNoSuggestions [
	self assert: evaluator acceptanceRate equals: 0
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testDetermineContextTypeAssignment [
	| context |
	context := CoPCContext new.
	context source: 'variable := value'.
	
	self assert: (evaluator determineContextType: context) equals: #assignment
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testDetermineContextTypeClassDefinition [
	| context |
	context := CoPCContext new.
	context source: 'Class { #name : ''MyClass'' }'.
	
	self assert: (evaluator determineContextType: context) equals: #classDef
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testDetermineContextTypeConditional [

	| context |
	context := CoPCContext new.
	context source: 'condition ifTrue: [ action ]'.

	self assert: (evaluator determineContextType: context) equals: #condition
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testDetermineContextTypeIteration [
	| context |
	context := CoPCContext new.
	context source: 'collection do: [ :each | process ]'.
	
	self assert: (evaluator determineContextType: context) equals: #iteration
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testDetermineContextTypeMethod [
	| context |
	context := CoPCContext new.
	context source: 'methodName { #category : ''accessing'' }'.
	
	self assert: (evaluator determineContextType: context) equals: #method
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testDetermineContextTypeOther [
	| context |
	context := CoPCContext new.
	context source: 'some random code'.
	
	self assert: (evaluator determineContextType: context) equals: #other
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testDetermineContextTypeReturn [
	| context |
	context := CoPCContext new.
	context source: '^ result'.
	
	self assert: (evaluator determineContextType: context) equals: #return
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testInitialStatsStructure [

	| stats |
	stats := evaluator sessionStats.

	self assert: (stats at: #totalSuggestions) equals: 0.
	self assert: (stats at: #totalAccepted) equals: 0.
	self assert: (stats at: #totalRejected) equals: 0.
	self assert: ((stats at: #sessionStartTime) isKindOf: DateAndTime).
	self assert: ((stats at: #modelStats) isKindOf: Dictionary).
	self assert: ((stats at: #contextStats) isKindOf: Dictionary).
	self assert: ((stats at: #lengthStats) isKindOf: Dictionary)
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testRecordSuggestionAccepted [
	| context entry |
	context := CoPCContext new.
	entry := CoCopilotEntry contents: 'test suggestion'.
	
	evaluator recordSuggestionAccepted: entry context: context.
	
	self assert: evaluator acceptedEntries size equals: 1.
	self assert: evaluator acceptedEntries first suggestion identicalTo: entry.
	self assert: evaluator acceptedEntries first action equals: #accepted.
	self assert: (evaluator sessionStats at: #totalAccepted) equals: 1
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testRecordSuggestionIgnored [
	| context entry |
	context := CoPCContext new.
	entry := CoCopilotEntry contents: 'ignored suggestion'.
	
	evaluator recordSuggestionIgnored: entry context: context.
	
	"Ignored suggestions don't go into accepted or rejected collections"
	self assert: evaluator acceptedEntries isEmpty.
	self assert: evaluator rejectedEntries isEmpty.
	
	"But they do update the total count"
	self assert: (evaluator sessionStats at: #totalSuggestions) equals: 1
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testRejectionRateCalculation [

	| context |
	context := CoPCContext new. 
	self assert: evaluator rejectionRate equals: 0. 
	evaluator recordSuggestionAccepted: (CoCopilotEntry contents: 'accepted') context: context.
evaluator recordSuggestionRejected: (CoCopilotEntry contents: 'rejected') context: context reason: 'Bad suggestion'.
	self assert: evaluator rejectionRate equals: 50
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testSavePersistentStatsProducesJson [

    | tempFs tempDir tempFile sessionDir originalReference originalLogRef originalLogsRef originalSessionRef originalArchiveRef originalUserId originalSessionId originalStartedAt originalArchived originalSettings jsonLine parsed |
    tempFs := FileSystem memory.
            tempDir := tempFs
            / CoPharoCopilotLogger pharoCopilotDirectoryName.
    sessionDir := tempDir / 'session-test'.
    tempDir parent ensureCreateDirectory.
    tempDir ensureCreateDirectory.
    tempFile := tempDir / 'copilot-evaluation-log.jsonl'.

    originalReference := CoPharoCopilotLogger evaluationLogFileReference.
    originalLogRef := CoPharoCopilotLogger rawLogFileReference.
    originalLogsRef := CoPharoCopilotLogger rawLogsDirectoryReference.
    originalSessionRef := CoPharoCopilotLogger rawSessionDirectoryReference.
    originalArchiveRef := CoPharoCopilotLogger rawSessionArchiveFileReference.
    originalUserId := CoPharoCopilotLogger rawUserId.
    originalSessionId := CoPharoCopilotLogger instVarNamed: #sessionId.
    originalStartedAt := CoPharoCopilotLogger instVarNamed: #sessionStartedAt.
    originalArchived := CoPharoCopilotLogger instVarNamed: #sessionArchived.
    originalSettings := CopilotSettings settingsSnapshot.

    [
            CopilotSettings recordResearchTelemetryConsentAccepted: true.
            CopilotSettings loggingEnabled: true.
            CoPharoCopilotLogger rawLogsDirectoryReference: tempDir.
            CoPharoCopilotLogger rawSessionDirectoryReference: sessionDir.
            CoPharoCopilotLogger evaluationLogFileReference: tempFile.
            CoPharoCopilotLogger rawUserId: 'user-test'.
            evaluator savePersistentStats.
            jsonLine := tempFile readStreamDo: [ :stream | stream nextLine ].
            parsed := STONJSON fromString: jsonLine.
		self assert: (parsed at: 'userId') equals: 'user-test'.
		self assert: (parsed at: 'sessionId') equals: sessionDir basename.
		self assert: (parsed at: 'rejectedCount') equals: 0.
		self assert: ((parsed at: 'sessionStats') isKindOf: Dictionary).
		self assert: ((parsed at: 'sessionStats') includesKey: 'totalSuggestions').
		self assert: ((parsed at: 'timestamp') isKindOf: String).
		self assert: ((parsed at: 'modelName') isKindOf: String) ] ensure: [
			tempFile exists ifTrue: [ tempFile ensureDelete ].
			CoPharoCopilotLogger rawLogsDirectoryReference: originalLogsRef.
			CoPharoCopilotLogger rawSessionDirectoryReference: originalSessionRef.
			CoPharoCopilotLogger rawSessionArchiveFileReference: originalArchiveRef.
			CoPharoCopilotLogger rawLogFileReference: originalLogRef.
			CoPharoCopilotLogger evaluationLogFileReference: originalReference.
			CoPharoCopilotLogger rawUserId: originalUserId.
			CoPharoCopilotLogger instVarNamed: #sessionId put: originalSessionId.
			CoPharoCopilotLogger instVarNamed: #sessionStartedAt put: originalStartedAt.
			CoPharoCopilotLogger instVarNamed: #sessionArchived put: originalArchived.
			CopilotSettings restoreSettingsFromSnapshot: originalSettings ]
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testUpdateLengthStatsLongSuggestion [
	| entry |
	entry := CoPCEvaluationEntry new.
	entry suggestion: (CoCopilotEntry contents: (String new: 100 withAll: $a)).
	entry action: #accepted.
	
	evaluator updateStats: entry.
	
	self assert: (((evaluator sessionStats at: #lengthStats) at: #long) at: #accepted) equals: 1
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testUpdateLengthStatsMediumSuggestion [
	| entry |
	entry := CoPCEvaluationEntry new.
	entry suggestion: (CoCopilotEntry contents: (String new: 30 withAll: $a)).
	entry action: #accepted.
	
	evaluator updateStats: entry.
	
	self assert: (((evaluator sessionStats at: #lengthStats) at: #medium) at: #accepted) equals: 1
]

{ #category : 'running' }
CoSuggestionEvaluatorTest >> testUpdateLengthStatsShortSuggestion [
	| entry |
	entry := CoPCEvaluationEntry new.
	entry suggestion: (CoCopilotEntry contents: 'short').
	entry action: #accepted.
	
	evaluator updateStats: entry.
	
	self assert: (((evaluator sessionStats at: #lengthStats) at: #short) at: #accepted) equals: 1
]
