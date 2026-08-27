"
Builds a single-session telemetry summary from session-info.json,
copilot-evaluation-log.jsonl, and completions/*.json.
"
Class {
	#name : 'CoPCSessionTelemetryAnalyzer',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'writing' }
CoPCSessionTelemetryAnalyzer class >> writeSummaryForSessionDirectory: sessionDirectory archiveFile: archiveFile sessionId: sessionId userId: userId [

	^ self
		writeSummaryForSessionDirectory: sessionDirectory
		outputDirectory: archiveFile asFileReference parent
		archiveFile: archiveFile
		sessionId: sessionId
		userId: userId
]

{ #category : 'writing' }
CoPCSessionTelemetryAnalyzer class >> writeSummaryForSessionDirectory: sessionDirectory outputDirectory: outputDirectory archiveFile: archiveFile sessionId: sessionId userId: userId [

	| file payload |
	file := self
		summaryFileReferenceForDirectory: outputDirectory
		sessionId: sessionId.
	payload := self
		payloadForSessionDirectory: sessionDirectory
		archiveFile: archiveFile
		sessionId: sessionId
		userId: userId.

	file parent ifNotNil: [ :parent | parent ensureCreateDirectory ].
	file writeStreamDo: [ :stream |
		stream nextPutAll: (STONJSON toString: payload) ].
	^ file
]

{ #category : 'writing' }
CoPCSessionTelemetryAnalyzer class >> summaryFileReferenceForArchiveFile: archiveFile sessionId: sessionId [

	^ self
		summaryFileReferenceForDirectory: archiveFile asFileReference parent
		sessionId: sessionId
]

{ #category : 'writing' }
CoPCSessionTelemetryAnalyzer class >> summaryFileReferenceForDirectory: directory sessionId: sessionId [

	| safeSessionId |
	safeSessionId := (sessionId ifNil: [ 'unknown-session' ] ifNotNil: [ sessionId asString ]) asFileName.
	^ directory asFileReference / (safeSessionId , '-telemetry.json')
]

{ #category : 'building' }
CoPCSessionTelemetryAnalyzer class >> payloadForSessionDirectory: sessionDirectory archiveFile: archiveFile sessionId: sessionId userId: userId [

	| sessionInfo completions evaluation summary |
	sessionInfo := self readJsonFile: sessionDirectory / 'session-info.json'.
	completions := self completionSummaryForSessionDirectory: sessionDirectory.
	evaluation := self evaluationSummaryForSessionDirectory: sessionDirectory.
	summary := self summaryFromCompletionSummary: completions evaluationSummary: evaluation.

	^ Dictionary new
		at: #event put: 'pharo-copilot-session-telemetry';
		at: #generatedAt put: DateAndTime now asString;
		at: #sessionId put: sessionId;
		at: #userId put: userId;
		at: #archiveFile put: (archiveFile ifNil: [ nil ] ifNotNil: [ archiveFile asFileReference basename ]);
		at: #sessionDirectory put: (sessionDirectory ifNil: [ nil ] ifNotNil: [ sessionDirectory basename ]);
		at: #session put: sessionInfo;
		at: #summary put: summary;
		at: #completionFiles put: (completions at: #completionFiles);
		at: #evaluation put: evaluation;
		yourself
]

{ #category : 'building' }
CoPCSessionTelemetryAnalyzer class >> summaryFromCompletionSummary: completions evaluationSummary: evaluation [

	| requests acceptedRequests rejectedRequests ignoredRequests suggestionCandidates suggestionChars acceptedChars suggestionLines acceptedLines logprobTokens logprobSum logprobCompletions avgLogprob tokenAttempts hits misses evaluated acceptedSuggestions rejectedSuggestions ignoredSuggestions outcomeAccepted outcomeRejected outcomeIgnored outcomeDecided complishonReroutes completionAttempts recordedComplishonRequests unrecordedComplishonReroutes selfReceiverLogprobTokens selfReceiverAvgLogprob environmentAvgLogprob environmentAvgConfidence inspectorLogprobTokens inspectorAvgLogprob rerouteEnvironmentCounts oldCompletionLookups oldLookupEnvironmentCounts latencyStats latencyByPathStats |
	requests := completions at: #completionRequests.
	acceptedRequests := completions at: #acceptedRequests.
	rejectedRequests := completions at: #nullCompletionRequests.
	ignoredRequests := completions at: #unresolvedCompletionRequests.
	suggestionCandidates := completions at: #suggestionCandidates.
	suggestionChars := completions at: #suggestionChars.
	acceptedChars := completions at: #acceptedChars.
	suggestionLines := completions at: #suggestionLines.
	acceptedLines := completions at: #acceptedLines.
	logprobTokens := completions at: #logprobTokens.
	logprobSum := completions at: #logprobSum.
	logprobCompletions := completions at: #logprobCompletions.
	avgLogprob := logprobTokens = 0
		ifTrue: [ nil ]
		ifFalse: [ self round: logprobSum / logprobTokens digits: 4 ].
	selfReceiverLogprobTokens := completions at: #selfReceiverLogprobTokens.
	selfReceiverAvgLogprob := self
		averageLogprobFromSum: (completions at: #selfReceiverLogprobSum)
		tokenCount: selfReceiverLogprobTokens.
	environmentAvgLogprob := self
		averageLogprobByKeyFromTokens: (completions at: #completionEnvironmentLogprobTokens)
		sums: (completions at: #completionEnvironmentLogprobSum).
	environmentAvgConfidence := self
		confidenceByKeyFromAverageLogprob: environmentAvgLogprob
		tokens: (completions at: #completionEnvironmentLogprobTokens).
	inspectorLogprobTokens := (completions at: #completionEnvironmentLogprobTokens) at: 'inspector' ifAbsent: [ 0 ].
	inspectorAvgLogprob := environmentAvgLogprob at: 'inspector' ifAbsent: [ nil ].
	tokenAttempts := completions at: #tokenCountAttempts.
	hits := completions at: #cacheHits.
	misses := completions at: #cacheMisses.
	acceptedSuggestions := evaluation at: #acceptedSuggestions.
	rejectedSuggestions := evaluation at: #rejectedSuggestions.
	ignoredSuggestions := evaluation at: #ignoredSuggestions.
	evaluated := acceptedSuggestions + rejectedSuggestions + ignoredSuggestions.
	outcomeRejected := ((rejectedRequests max: rejectedSuggestions) min: requests) max: 0.
	outcomeAccepted := ((acceptedRequests max: acceptedSuggestions)
		min: ((requests - outcomeRejected) max: 0)) max: 0.
	outcomeIgnored := (requests - outcomeAccepted - outcomeRejected) max: 0.
	outcomeDecided := outcomeAccepted + outcomeRejected.
	complishonReroutes := evaluation at: #complishonReroutes.
	recordedComplishonRequests := (completions at: #completionPathCounts)
		at: 'complishon'
		ifAbsent: [ 0 ].
	unrecordedComplishonReroutes := (complishonReroutes - recordedComplishonRequests) max: 0.
	completionAttempts := requests + unrecordedComplishonReroutes.
	rerouteEnvironmentCounts := self
		resolvedRerouteEnvironmentCounts: (evaluation at: #complishonRerouteEnvironmentCounts)
		completionEnvironmentCounts: (completions at: #completionEnvironmentCounts).
	oldCompletionLookups := (evaluation at: #oldCompletionLookups) max: complishonReroutes.
	oldLookupEnvironmentCounts := self
		resolvedRerouteEnvironmentCounts: (evaluation at: #oldCompletionLookupEnvironmentCounts)
		completionEnvironmentCounts: (completions at: #completionEnvironmentCounts).
	oldLookupEnvironmentCounts isEmpty ifTrue: [
		oldLookupEnvironmentCounts := rerouteEnvironmentCounts copy ].
	latencyStats := self latencyStatsFor: (completions at: #completionLatenciesMs).
	latencyByPathStats := self latencyStatsByPathFor: (completions at: #completionLatenciesByPath).

	^ Dictionary new
		at: #completion_requests put: requests;
		at: #completion_attempts put: completionAttempts;
		at: #complishon_reroute_count put: complishonReroutes;
		at: #complishon_reroute_rate put: (self pct: complishonReroutes total: completionAttempts);
		at: #old_completion_fallback_requests put: complishonReroutes;
		at: #old_completion_fallback_rate put: (self pct: complishonReroutes total: completionAttempts);
		at: #old_completion_lookup_requests put: oldCompletionLookups;
		at: #old_completion_lookups_per_attempt put: (self average: oldCompletionLookups count: completionAttempts);
		at: #accepted_requests put: acceptedRequests;
		at: #rejected_requests put: rejectedRequests;
		at: #ignored_requests put: ignoredRequests;
		at: #acceptance_rate put: (self pct: outcomeAccepted total: outcomeDecided);
		at: #rejection_rate put: (self pct: outcomeRejected total: outcomeDecided);
		at: #ignored_rate put: (self pct: outcomeIgnored total: requests);
		at: #self_receiver_completion_requests put: (completions at: #selfReceiverCompletionRequests);
		at: #self_receiver_completion_rate put: (self pct: (completions at: #selfReceiverCompletionRequests) total: requests);
		at: #self_receiver_logprob_completions put: (completions at: #selfReceiverLogprobCompletions);
		at: #self_receiver_logprob_tokens put: selfReceiverLogprobTokens;
		at: #self_receiver_logprob_sum put: (self round: (completions at: #selfReceiverLogprobSum) digits: 4);
		at: #self_receiver_avg_logprob put: selfReceiverAvgLogprob;
		at: #self_receiver_avg_confidence put: (self confidenceFromAvgLogprob: selfReceiverAvgLogprob tokenCount: selfReceiverLogprobTokens);
		at: #suggestion_candidates put: suggestionCandidates;
		at: #suggestion_chars put: suggestionChars;
		at: #accepted_chars put: acceptedChars;
		at: #accepted_char_rate put: (self pct: acceptedChars total: suggestionChars);
		at: #avg_chars_per_accept put: (self average: acceptedChars count: acceptedRequests);
		at: #suggestion_lines put: suggestionLines;
		at: #accepted_lines put: acceptedLines;
		at: #accepted_line_rate put: (self pct: acceptedLines total: suggestionLines);
		at: #avg_lines_per_accept put: (self average: acceptedLines count: acceptedRequests);
		at: #multiline_suggestion_candidates put: (completions at: #multilineSuggestionCandidates);
		at: #multiline_suggestion_rate put: (self pct: (completions at: #multilineSuggestionCandidates) total: suggestionCandidates);
		at: #multiline_accepted_suggestions put: (completions at: #multilineAcceptedSuggestions);
		at: #suggestion_type_counts put: (completions at: #suggestionTypeCounts) copy;
		at: #suggestion_ast_signal_counts put: Dictionary new;
		at: #accepted_suggestions put: outcomeAccepted;
		at: #rejected_suggestions put: outcomeRejected;
		at: #ignored_suggestions put: outcomeIgnored;
		at: #evaluated_suggestions put: evaluated;
		at: #evaluated_accepted_suggestions put: acceptedSuggestions;
		at: #evaluated_rejected_suggestions put: rejectedSuggestions;
		at: #evaluated_ignored_suggestions put: ignoredSuggestions;
		at: #evaluated_acceptance_rate put: (self pct: acceptedSuggestions total: evaluated);
		at: #evaluated_rejection_rate put: (self pct: rejectedSuggestions total: evaluated);
		at: #evaluated_ignored_rate put: (self pct: ignoredSuggestions total: evaluated);
		at: #evaluation_coverage_rate put: (self pct: (evaluated min: requests) total: requests);
		at: #backend_rejection_payloads put: (completions at: #backendRejectionPayloads);
		at: #backend_rejection_requests put: (completions at: #backendRejectionRequests);
		at: #backend_rejection_rate put: (self pct: (completions at: #backendRejectionRequests) total: requests);
		at: #recorded_close_rejections put: (completions at: #nullCompletionRequests);
		at: #unresolved_completion_requests put: ignoredRequests;
		at: #logprob_completions put: logprobCompletions;
		at: #logprob_coverage_rate put: (self pct: logprobCompletions total: requests);
		at: #logprob_attempts put: (completions at: #logprobAttempts);
		at: #logprob_tokens put: logprobTokens;
		at: #logprob_sum put: (self round: logprobSum digits: 4);
		at: #avg_logprob put: avgLogprob;
		at: #avg_confidence put: (self confidenceFromAvgLogprob: avgLogprob tokenCount: logprobTokens);
		at: #completion_environment_logprob_completions put: (completions at: #completionEnvironmentLogprobCompletions) copy;
		at: #completion_environment_logprob_attempts put: (completions at: #completionEnvironmentLogprobAttempts) copy;
		at: #completion_environment_logprob_tokens put: (completions at: #completionEnvironmentLogprobTokens) copy;
		at: #completion_environment_logprob_sum put: (completions at: #completionEnvironmentLogprobSum) copy;
		at: #completion_environment_avg_logprob put: environmentAvgLogprob;
		at: #completion_environment_avg_confidence put: environmentAvgConfidence;
		at: #inspector_logprob_completions put: ((completions at: #completionEnvironmentLogprobCompletions) at: 'inspector' ifAbsent: [ 0 ]);
		at: #inspector_logprob_tokens put: inspectorLogprobTokens;
		at: #inspector_logprob_sum put: (self round: ((completions at: #completionEnvironmentLogprobSum) at: 'inspector' ifAbsent: [ 0.0 ]) digits: 4);
		at: #inspector_avg_logprob put: inspectorAvgLogprob;
		at: #inspector_avg_confidence put: (self confidenceFromAvgLogprob: inspectorAvgLogprob tokenCount: inspectorLogprobTokens);
		at: #token_count_completions put: (completions at: #tokenCountCompletions);
		at: #token_count_attempts put: tokenAttempts;
		at: #prompt_tokens put: (completions at: #promptTokens);
		at: #completion_tokens put: (completions at: #completionTokens);
		at: #avg_prompt_tokens_per_attempt put: (self average: (completions at: #promptTokens) count: tokenAttempts);
		at: #avg_completion_tokens_per_attempt put: (self average: (completions at: #completionTokens) count: tokenAttempts);
		at: #token_count_coverage_rate put: (self pct: (completions at: #tokenCountCompletions) total: requests);
		at: #cache_hit_rate put: (self pct: hits total: hits + misses);
		at: #completion_latency_p50_ms put: (latencyStats at: #p50_ms);
		at: #completion_latency_p90_ms put: (latencyStats at: #p90_ms);
		at: #completion_latency_p95_ms put: (latencyStats at: #p95_ms);
		at: #completion_under_200ms_rate put: (latencyStats at: #under_200ms_rate);
		at: #completion_under_500ms_rate put: (latencyStats at: #under_500ms_rate);
		at: #completion_under_1000ms_rate put: (latencyStats at: #under_1000ms_rate);
		at: #completion_path_counts put: (completions at: #completionPathCounts) copy;
		at: #completion_latency_by_path put: latencyByPathStats;
		at: #avg_local_context_chars put: (self averageCollection: (completions at: #localContextChars));
		at: #avg_global_context_chars put: (self averageCollection: (completions at: #globalContextChars));
		at: #completion_environment_counts put: (completions at: #completionEnvironmentCounts) copy;
		at: #complishon_reroute_environment_counts put: rerouteEnvironmentCounts;
		at: #old_completion_environment_counts put: rerouteEnvironmentCounts copy;
		at: #old_completion_lookup_environment_counts put: oldLookupEnvironmentCounts;
		at: #first_activity put: (completions at: #firstActivity);
		at: #last_activity put: (completions at: #lastActivity);
		at: #usage_hours put: 0.0;
		at: #privacy_consent put: (evaluation at: #privacyConsent);
		at: #data_collection_consent put: (evaluation at: #dataCollectionConsent);
		at: #screen_recording_consent put: (evaluation at: #screenRecordingConsent);
		at: #tasks_done put: (evaluation at: #tasksDone) copy;
		at: #survey_ratings put: (evaluation at: #surveyRatings) copy;
		at: #survey_feedback_comment put: (evaluation at: #feedbackComment ifAbsent: [ '' ]);
		yourself
]

{ #category : 'completion parsing' }
CoPCSessionTelemetryAnalyzer class >> completionSummaryForSessionDirectory: sessionDirectory [

	| files summary |
	files := self completionJsonFilesForSessionDirectory: sessionDirectory.
	summary := Dictionary new
		at: #completionRequests put: files size;
		at: #completionFiles put: (files collect: [ :each | each basename ]) asArray;
		at: #acceptedRequests put: 0;
		at: #nullCompletionRequests put: 0;
		at: #unresolvedCompletionRequests put: 0;
		at: #backendRejectionPayloads put: 0;
		at: #backendRejectionRequests put: 0;
		at: #selfReceiverCompletionRequests put: 0;
		at: #suggestionCandidates put: 0;
		at: #suggestionChars put: 0;
		at: #acceptedChars put: 0;
		at: #suggestionLines put: 0;
		at: #acceptedLines put: 0;
		at: #multilineSuggestionCandidates put: 0;
		at: #multilineAcceptedSuggestions put: 0;
		at: #suggestionTypeCounts put: Dictionary new;
		at: #logprobCompletions put: 0;
		at: #logprobAttempts put: 0;
		at: #logprobTokens put: 0;
		at: #logprobSum put: 0.0;
		at: #selfReceiverLogprobCompletions put: 0;
		at: #selfReceiverLogprobTokens put: 0;
		at: #selfReceiverLogprobSum put: 0.0;
		at: #completionEnvironmentLogprobCompletions put: Dictionary new;
		at: #completionEnvironmentLogprobAttempts put: Dictionary new;
		at: #completionEnvironmentLogprobTokens put: Dictionary new;
		at: #completionEnvironmentLogprobSum put: Dictionary new;
		at: #tokenCountCompletions put: 0;
		at: #tokenCountAttempts put: 0;
		at: #promptTokens put: 0;
		at: #completionTokens put: 0;
		at: #cacheHits put: 0;
		at: #cacheMisses put: 0;
		at: #completionPathCounts put: Dictionary new;
		at: #completionLatenciesMs put: OrderedCollection new;
		at: #completionLatenciesByPath put: Dictionary new;
		at: #completionEnvironmentCounts put: Dictionary new;
		at: #localContextChars put: OrderedCollection new;
		at: #globalContextChars put: OrderedCollection new;
		at: #activityTimestamps put: OrderedCollection new;
		at: #firstActivity put: '';
		at: #lastActivity put: '';
		yourself.

	files do: [ :file | self addCompletionFile: file toSummary: summary ].
	self finalizeActivityTimestampsIn: summary.
	^ summary
]

{ #category : 'completion parsing' }
CoPCSessionTelemetryAnalyzer class >> completionJsonFilesForSessionDirectory: sessionDirectory [

	| directory files |
	directory := sessionDirectory / 'completions'.
	(directory exists and: [ directory isDirectory ]) ifFalse: [ ^ #() ].
	files := directory children select: [ :each |
		each isFile and: [ each basename endsWith: '.json' ] ].
	^ (files asSortedCollection: [ :a :b | a basename <= b basename ]) asArray
]

{ #category : 'completion parsing' }
CoPCSessionTelemetryAnalyzer class >> completionEnvironmentFrom: data [

	| environment |
	environment := self dictionaryAt: #completionEnvironment from: data.
	environment isEmpty ifFalse: [ ^ environment ].
	^ self dictionaryAt: #environment from: data
]

{ #category : 'completion parsing' }
CoPCSessionTelemetryAnalyzer class >> completionEnvironmentKindFrom: environment [

	| kind |
	kind := self stringAt: #kind from: environment.
	kind isEmpty ifTrue: [ ^ 'unknown' ].
	^ kind
]

{ #category : 'completion parsing' }
CoPCSessionTelemetryAnalyzer class >> addCompletionFile: file toSummary: summary [

	| data fim context cache environment environmentKind prefix suffix classContext fullSource suggestions acceptedText rejectedItems nullCompletion logprobStats tokenStats hits misses isSelfReceiver completionPath processingDuration |
	data := self readJsonFile: file.
	data isEmpty ifTrue: [ ^ self ].
	fim := self dictionaryAt: #fim from: data.
	context := self dictionaryAt: #context from: data.
	cache := self dictionaryAt: #cache from: data.
	environment := self completionEnvironmentFrom: data.
	environmentKind := self completionEnvironmentKindFrom: environment.
	prefix := self stringAt: #prefix from: fim.
	suffix := self stringAt: #suffix from: fim.
	classContext := self stringAt: #classContext from: context.
	fullSource := self stringAt: #fullSource from: context.
	suggestions := self completionSuggestionTextsFrom: data.
	acceptedText := self stringAt: #accepted from: data.
	rejectedItems := self arrayAt: #rejected from: data.
	completionPath := self completionPathFrom: data.
	processingDuration := self completionDurationFrom: data key: #processingDurationMs.

	isSelfReceiver := self isSelfReceiverCompletionPrefix: prefix.
	isSelfReceiver ifTrue: [
		self increment: #selfReceiverCompletionRequests in: summary ].
	self
		increment: environmentKind
		in: (summary at: #completionEnvironmentCounts).
	self increment: completionPath in: (summary at: #completionPathCounts).
	processingDuration ifNotNil: [
		(summary at: #completionLatenciesMs) add: processingDuration.
		self
			addLatency: processingDuration
			path: completionPath
			toSummary: summary ].
	self addSuggestions: suggestions prefix: prefix suffix: suffix toSummary: summary.
	acceptedText isEmpty ifFalse: [
		self increment: #acceptedRequests in: summary.
		self add: acceptedText size to: #acceptedChars in: summary.
		self add: (self lineCountOf: acceptedText) to: #acceptedLines in: summary.
		(self lineCountOf: acceptedText) > 1 ifTrue: [
			self increment: #multilineAcceptedSuggestions in: summary ] ].

	nullCompletion := self booleanAt: #nullCompletion from: data.
	nullCompletion ifTrue: [ self increment: #nullCompletionRequests in: summary ].
	((acceptedText isEmpty and: [ nullCompletion not ]) and: [ rejectedItems isEmpty ]) ifTrue: [
		self increment: #unresolvedCompletionRequests in: summary ].

	self add: rejectedItems size to: #backendRejectionPayloads in: summary.
	rejectedItems isEmpty ifFalse: [ self increment: #backendRejectionRequests in: summary ].

	logprobStats := self logprobStatsFromCompletion: data.
	((logprobStats at: #tokens) > 0) ifTrue: [
		self increment: #logprobCompletions in: summary.
		self add: (logprobStats at: #attempts) to: #logprobAttempts in: summary.
		self add: (logprobStats at: #tokens) to: #logprobTokens in: summary.
		self add: (logprobStats at: #sum) to: #logprobSum in: summary.
		isSelfReceiver ifTrue: [
			self increment: #selfReceiverLogprobCompletions in: summary.
			self add: (logprobStats at: #tokens) to: #selfReceiverLogprobTokens in: summary.
			self add: (logprobStats at: #sum) to: #selfReceiverLogprobSum in: summary ].
		self increment: environmentKind in: (summary at: #completionEnvironmentLogprobCompletions).
		self add: (logprobStats at: #attempts) to: environmentKind in: (summary at: #completionEnvironmentLogprobAttempts).
		self add: (logprobStats at: #tokens) to: environmentKind in: (summary at: #completionEnvironmentLogprobTokens).
		self add: (logprobStats at: #sum) to: environmentKind in: (summary at: #completionEnvironmentLogprobSum) ].

	tokenStats := self tokenStatsFromCompletion: data.
	((tokenStats at: #attempts) > 0) ifTrue: [
		self increment: #tokenCountCompletions in: summary.
		self add: (tokenStats at: #attempts) to: #tokenCountAttempts in: summary.
		self add: (tokenStats at: #promptTokens) to: #promptTokens in: summary.
		self add: (tokenStats at: #completionTokens) to: #completionTokens in: summary ].

	hits := self nonNegativeNumberAt: #hits from: cache.
	misses := self nonNegativeNumberAt: #misses from: cache.
	summary at: #cacheHits put: ((summary at: #cacheHits) max: hits).
	summary at: #cacheMisses put: ((summary at: #cacheMisses) max: misses).
	(summary at: #localContextChars) add: prefix size + suffix size.
	(summary at: #globalContextChars) add: classContext size.
	(self stringAt: #timestamp from: data) ifNotEmpty: [ :timestamp |
		(summary at: #activityTimestamps) add: timestamp ]
]

{ #category : 'completion parsing' }
CoPCSessionTelemetryAnalyzer class >> addLatency: duration path: pathString toSummary: summary [

	| byPath samples |
	byPath := summary at: #completionLatenciesByPath.
	samples := byPath
		at: pathString
		ifAbsentPut: [ OrderedCollection new ].
	samples add: duration
]

{ #category : 'completion parsing' }
CoPCSessionTelemetryAnalyzer class >> addSuggestions: suggestions prefix: prefix suffix: suffix toSummary: summary [

	| typeCounts |
	typeCounts := summary at: #suggestionTypeCounts.
	suggestions do: [ :suggestion |
		| lineCount type |
		lineCount := self lineCountOf: suggestion.
		self increment: #suggestionCandidates in: summary.
		self add: suggestion size to: #suggestionChars in: summary.
		self add: lineCount to: #suggestionLines in: summary.
		lineCount > 1 ifTrue: [ self increment: #multilineSuggestionCandidates in: summary ].
		type := self completionTypeForPrefix: prefix suggestion: suggestion suffix: suffix.
		self increment: type in: typeCounts ]
]

{ #category : 'completion parsing' }
CoPCSessionTelemetryAnalyzer class >> completionDurationFrom: data key: key [

	| value telemetry number |
	value := self valueAt: key from: data default: nil.
	value ifNil: [
		telemetry := self dictionaryAt: #telemetry from: data.
		value := self valueAt: key from: telemetry default: nil ].

	number := self numberOrNil: value.
	number ifNil: [ ^ nil ].
	^ number max: 0
]

{ #category : 'completion parsing' }
CoPCSessionTelemetryAnalyzer class >> completionPathFrom: data [

	| path telemetry |
	path := self stringAt: #completionPath from: data.
	path isEmpty ifFalse: [ ^ path ].

	telemetry := self dictionaryAt: #telemetry from: data.
	path := self stringAt: #completionPath from: telemetry.
	path isEmpty ifFalse: [ ^ path ].

	^ 'unknown'
]

{ #category : 'completion parsing' }
CoPCSessionTelemetryAnalyzer class >> completionSuggestionTextsFrom: data [

	| suggestions generated |
	suggestions := OrderedCollection new.
	self addSuggestionText: (self stringAt: #accepted from: data) to: suggestions.
	generated := self dictionaryAt: #generated from: data.
	(self arrayAt: #suggestions from: generated) do: [ :each |
		self addSuggestionText: each to: suggestions ].
	(self arrayAt: #attempts from: generated) do: [ :attempt |
		| attemptDictionary |
		attemptDictionary := self dictionaryFrom: attempt.
		attemptDictionary ifNotNil: [
			self addSuggestionText: (self stringAt: #suggestion from: attemptDictionary) to: suggestions ] ].
	^ suggestions asArray
]

{ #category : 'completion parsing' }
CoPCSessionTelemetryAnalyzer class >> addSuggestionText: value to: suggestions [

	| text |
	text := self stringValue: value.
	text isEmpty ifTrue: [ ^ self ].
	(suggestions includes: text) ifFalse: [ suggestions add: text ]
]

{ #category : 'classification' }
CoPCSessionTelemetryAnalyzer class >> completionTypeForPrefix: prefix suggestion: suggestion suffix: suffix [

	| text combined |
	text := suggestion trimBoth.
	combined := prefix , text , suffix.
	text isEmpty ifTrue: [ ^ #unknown_completion ].
	((prefix includesSubstring: '^') or: [ text beginsWith: '^' ]) ifTrue: [ ^ #return_completion ].
	((prefix includesSubstring: ':=') or: [ text includesSubstring: ':=' ]) ifTrue: [ ^ #assignment_completion ].
	((text includesSubstring: '[') or: [ text includesSubstring: ']' ]) ifTrue: [ ^ #block_completion ].
	((text includesSubstring: ';') or: [ combined includesSubstring: ';' ]) ifTrue: [ ^ #cascade_completion ].
	(self looksLikeLiteralCompletion: text) ifTrue: [ ^ #literal_completion ].
	((self receiverBeforeCompletionIn: prefix) isEmpty not or: [ text includesSubstring: ':' ]) ifTrue: [ ^ #message_send_completion ].
	((text includes: Character lf) or: [ text includes: $. ]) ifTrue: [ ^ #statement_completion ].
	(self isIdentifier: text) ifTrue: [ ^ #variable_completion ].
	^ #unknown_completion
]

{ #category : 'classification' }
CoPCSessionTelemetryAnalyzer class >> isSelfReceiverCompletionPrefix: prefix [

	| receiver |
	receiver := self receiverAtCurrentStatementStartIn: prefix.
	receiver = 'self' ifTrue: [ ^ true ].
	^ receiver size >= 3 and: [ 'self' beginsWith: receiver ]
]

{ #category : 'classification' }
CoPCSessionTelemetryAnalyzer class >> receiverAtCurrentStatementStartIn: prefix [

	| source separatorIndex statement start stop |
	source := (self stringValue: prefix) trimRight.
	source isEmpty ifTrue: [ ^ '' ].

	separatorIndex := source size.
	[ separatorIndex > 0 and: [ (source at: separatorIndex) ~= $. ] ] whileTrue: [
		separatorIndex := separatorIndex - 1 ].
	statement := separatorIndex = source size
		ifTrue: [ '' ]
		ifFalse: [ source copyFrom: separatorIndex + 1 to: source size ].
	statement := statement trimBoth.
	[ statement isEmpty not and: [ statement first = $^ ] ] whileTrue: [
		statement size = 1 ifTrue: [ ^ '' ].
		statement := (statement copyFrom: 2 to: statement size) trimBoth ].
	statement isEmpty ifTrue: [ ^ '' ].

	start := 1.
	[ start <= statement size and: [ (self isWordChar: (statement at: start)) not ] ] whileTrue: [
		start := start + 1 ].
	start > statement size ifTrue: [ ^ '' ].
	stop := start.
	[ stop <= statement size and: [ self isWordChar: (statement at: stop) ] ] whileTrue: [
		stop := stop + 1 ].
	^ statement copyFrom: start to: stop - 1
]

{ #category : 'classification' }
CoPCSessionTelemetryAnalyzer class >> receiverBeforeCompletionIn: prefix [

	| source token base end start receiverEnd receiverStart |
	source := self stringValue: prefix.
	source isEmpty ifTrue: [ ^ '' ].
	token := self trailingWordFragmentIn: source.
	base := source.
	(token isEmpty not and: [ base size >= token size ]) ifTrue: [
		((base copyFrom: base size - token size + 1 to: base size) = token) ifTrue: [
			base := base size = token size
				ifTrue: [ '' ]
				ifFalse: [ base copyFrom: 1 to: base size - token size ] ] ].
	base := base trimRight.
	base isEmpty ifTrue: [ ^ '' ].
	end := base size.
	[ end > 0 and: [ (self isWordChar: (base at: end)) not ] ] whileTrue: [
		end := end - 1 ].
	end = 0 ifTrue: [ ^ '' ].
	receiverEnd := end.
	start := receiverEnd.
	[ start > 0 and: [ self isWordChar: (base at: start) ] ] whileTrue: [
		start := start - 1 ].
	receiverStart := start + 1.
	^ base copyFrom: receiverStart to: receiverEnd
]

{ #category : 'classification' }
CoPCSessionTelemetryAnalyzer class >> trailingWordFragmentIn: text [

	| index |
	text isEmpty ifTrue: [ ^ '' ].
	index := text size.
	[ index > 0 and: [ self isWordChar: (text at: index) ] ] whileTrue: [
		index := index - 1 ].
	^ index = text size
		ifTrue: [ '' ]
		ifFalse: [ text copyFrom: index + 1 to: text size ]
]

{ #category : 'classification' }
CoPCSessionTelemetryAnalyzer class >> isIdentifier: text [

	text isEmpty ifTrue: [ ^ false ].
	(self isWordChar: text first) ifFalse: [ ^ false ].
	^ text allSatisfy: [ :character | self isWordChar: character ]
]

{ #category : 'classification' }
CoPCSessionTelemetryAnalyzer class >> looksLikeLiteralCompletion: text [

	| trimmed first |
	trimmed := text trimBoth.
	trimmed isEmpty ifTrue: [ ^ false ].
	(#('true' 'false' 'nil') includes: trimmed) ifTrue: [ ^ true ].
	first := trimmed first.
	^ (first = $# or: [
		first = ${ or: [
		first = $[ or: [
		first = $( or: [
		first = $' or: [
		first isDigit or: [
		first = $- and: [ trimmed size > 1 and: [ (trimmed at: 2) isDigit ] ] ] ] ] ] ] ])
]

{ #category : 'classification' }
CoPCSessionTelemetryAnalyzer class >> isWordChar: character [

	character ifNil: [ ^ false ].
	^ character isLetter or: [ character isDigit or: [ character = $_ ] ]
]

{ #category : 'completion parsing' }
CoPCSessionTelemetryAnalyzer class >> logprobStatsFromCompletion: data [

	| generated attempts attemptCount tokenCount total |
	generated := self dictionaryAt: #generated from: data.
	attempts := self arrayAt: #attempts from: generated.
	attemptCount := 0.
	tokenCount := 0.
	total := 0.0.
	attempts do: [ :attempt |
		| attemptDictionary response values |
		attemptDictionary := self dictionaryFrom: attempt.
		attemptDictionary ifNotNil: [
			response := self dictionaryAt: #response from: attemptDictionary.
			values := self logprobValuesFromResponse: response.
			values isEmpty ifFalse: [
				attemptCount := attemptCount + 1.
				tokenCount := tokenCount + values size.
				total := total + (self sumCollection: values) ] ] ].
	^ Dictionary new
		at: #attempts put: attemptCount;
		at: #tokens put: tokenCount;
		at: #sum put: total;
		yourself
]

{ #category : 'completion parsing' }
CoPCSessionTelemetryAnalyzer class >> logprobValuesFromResponse: response [

	| values |
	values := OrderedCollection new.
	#(#logprobs #token_logprobs) do: [ :key |
		(self arrayAt: key from: response) do: [ :item |
			| itemDictionary number |
			itemDictionary := self dictionaryFrom: item.
			number := itemDictionary
				ifNil: [ self numberOrNil: item ]
				ifNotNil: [ self numberOrNil: (self valueAt: #logprob from: itemDictionary default: nil) ].
			number ifNotNil: [ values add: number ] ] ].
	^ values asArray
]

{ #category : 'completion parsing' }
CoPCSessionTelemetryAnalyzer class >> tokenStatsFromCompletion: data [

	| generated attempts attemptCount promptTokens completionTokens |
	generated := self dictionaryAt: #generated from: data.
	attempts := self arrayAt: #attempts from: generated.
	attemptCount := 0.
	promptTokens := 0.
	completionTokens := 0.
	attempts do: [ :attempt |
		| attemptDictionary response prompt completion |
		attemptDictionary := self dictionaryFrom: attempt.
		attemptDictionary ifNotNil: [
			response := self dictionaryAt: #response from: attemptDictionary.
			prompt := self nonNegativeIntegerAt: #prompt_eval_count from: response.
			completion := self nonNegativeIntegerAt: #eval_count from: response.
			(prompt > 0 or: [ completion > 0 ]) ifTrue: [
				attemptCount := attemptCount + 1.
				promptTokens := promptTokens + prompt.
				completionTokens := completionTokens + completion ] ] ].
	^ Dictionary new
		at: #attempts put: attemptCount;
		at: #promptTokens put: promptTokens;
		at: #completionTokens put: completionTokens;
		yourself
]

{ #category : 'evaluation parsing' }
CoPCSessionTelemetryAnalyzer class >> resolvedRerouteEnvironmentCounts: rerouteCounts completionEnvironmentCounts: completionCounts [

	| resolved unresolved knownEnvironments |
	resolved := Dictionary new.
	unresolved := 0.
	rerouteCounts keysAndValuesDo: [ :key :count |
		((key = 'unknown') or: [ key = 'not recorded' ])
			ifTrue: [ unresolved := unresolved + count ]
			ifFalse: [ self add: count to: key in: resolved ] ].

	unresolved = 0 ifTrue: [ ^ resolved ].
	knownEnvironments := completionCounts keys select: [ :key |
		((key = 'unknown') or: [ key = 'not recorded' ]) not
			and: [ (completionCounts at: key) > 0 ] ].
	knownEnvironments size = 1 ifTrue: [
		self add: unresolved to: knownEnvironments anyOne in: resolved ].
	^ resolved
]

{ #category : 'evaluation parsing' }
CoPCSessionTelemetryAnalyzer class >> evaluationSummaryForSessionDirectory: sessionDirectory [

	| file summary latestStats latestRow directAccepted directRejected directIgnored |
	file := sessionDirectory / 'copilot-evaluation-log.jsonl'.
	summary := Dictionary new
		at: #acceptedSuggestions put: 0;
		at: #rejectedSuggestions put: 0;
		at: #ignoredSuggestions put: 0;
		at: #complishonReroutes put: 0;
		at: #complishonRerouteEnvironmentCounts put: Dictionary new;
		at: #oldCompletionLookups put: 0;
		at: #oldCompletionLookupEnvironmentCounts put: Dictionary new;
		at: #privacyConsent put: 'unknown';
		at: #dataCollectionConsent put: 'unknown';
		at: #screenRecordingConsent put: 'unknown';
		at: #tasksDone put: #();
		at: #surveyRatings put: Dictionary new;
		at: #feedbackComment put: '';
		yourself.
	(file exists and: [ file isFile ]) ifFalse: [ ^ summary ].
	latestStats := nil.
	latestRow := nil.
	directAccepted := 0.
	directRejected := 0.
	directIgnored := 0.

	file readStreamDo: [ :stream |
		[ stream atEnd ] whileFalse: [
			| line row data event action stats |
			line := stream nextLine.
			row := self jsonFromString: line.
			row isEmpty ifFalse: [
				data := self dictionaryAt: #data from: row.
				event := self stringAt: #event from: row.
				event = 'research-telemetry-consent' ifTrue: [
					summary at: #privacyConsent put: (self stringValue: (self valueAt: #accepted from: data default: 'unknown')).
					summary at: #dataCollectionConsent put: (self stringValue: (self valueAt: #consentState from: data default: 'unknown')) ].
				event = 'privacy-policy-consent' ifTrue: [
					summary at: #privacyConsent put: (self stringValue: (self valueAt: #accepted from: data default: 'unknown')) ].
				event = 'screen-recording-consent' ifTrue: [
					summary at: #screenRecordingConsent put: (self stringValue: (self valueAt: #consentState from: data default: 'unknown')) ].
				event = 'image-close-survey' ifTrue: [
					summary at: #tasksDone put: (self arrayAt: #tasks from: data).
					summary at: #surveyRatings put: (self dictionaryAt: #ratings from: data).
					summary at: #feedbackComment put: (self stringAt: #feedbackComment from: data) ].
				event = 'completion-rerouted-to-complishon' ifTrue: [
					self increment: #complishonReroutes in: summary.
					self
						increment: (self completionEnvironmentKindFrom: (self completionEnvironmentFrom: data))
						in: (summary at: #complishonRerouteEnvironmentCounts) ].
				event = 'old-completion-lookup' ifTrue: [
					self increment: #oldCompletionLookups in: summary.
					self
						increment: (self completionEnvironmentKindFrom: (self completionEnvironmentFrom: data))
						in: (summary at: #oldCompletionLookupEnvironmentCounts) ].
				action := (self stringAt: #action from: row) asLowercase.
				action isEmpty ifTrue: [ action := (self stringAt: #action from: data) asLowercase ].
				action = 'accepted' ifTrue: [ directAccepted := directAccepted + 1 ].
				action = 'rejected' ifTrue: [ directRejected := directRejected + 1 ].
				action = 'ignored' ifTrue: [ directIgnored := directIgnored + 1 ].
				stats := self dictionaryAt: #sessionStats from: row.
				stats isEmpty ifFalse: [
					latestStats := stats.
					latestRow := row ] ] ] ].

	self
		addEvaluationStats: latestStats
		row: latestRow
		directAccepted: directAccepted
		directRejected: directRejected
		directIgnored: directIgnored
		toSummary: summary.
	^ summary
]

{ #category : 'evaluation parsing' }
CoPCSessionTelemetryAnalyzer class >> addEvaluationStats: stats row: row directAccepted: directAccepted directRejected: directRejected directIgnored: directIgnored toSummary: summary [

	| modelStats modelAccepted modelRejected modelIgnored accepted rejected total ignored |
	stats ifNil: [
		summary
			at: #acceptedSuggestions put: directAccepted;
			at: #rejectedSuggestions put: directRejected;
			at: #ignoredSuggestions put: directIgnored.
		^ self ].

	modelStats := self dictionaryAt: #modelStats from: stats.
	modelAccepted := 0.
	modelRejected := 0.
	modelIgnored := 0.
	modelStats valuesDo: [ :each |
		| values |
		values := self dictionaryFrom: each.
		values ifNotNil: [
			modelAccepted := modelAccepted + (self nonNegativeIntegerAt: #accepted from: values).
			modelRejected := modelRejected + (self nonNegativeIntegerAt: #rejected from: values).
			modelIgnored := modelIgnored + (self nonNegativeIntegerAt: #ignored from: values) ] ].

	accepted := ((self nonNegativeIntegerAt: #totalAccepted from: stats)
		max: (self nonNegativeIntegerAt: #acceptedCount from: row))
		max: modelAccepted.
	rejected := ((self nonNegativeIntegerAt: #totalRejected from: stats)
		max: (self nonNegativeIntegerAt: #rejectedCount from: row))
		max: modelRejected.
	total := (self nonNegativeIntegerAt: #totalSuggestions from: stats)
		max: accepted + rejected + modelIgnored.
	ignored := modelIgnored max: (total - accepted - rejected max: 0).

	accepted := accepted max: directAccepted.
	rejected := rejected max: directRejected.
	ignored := ignored max: directIgnored.
	total := total max: accepted + rejected + ignored.
	ignored := ignored max: (total - accepted - rejected max: 0).

	summary
		at: #acceptedSuggestions put: accepted;
		at: #rejectedSuggestions put: rejected;
		at: #ignoredSuggestions put: ignored
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> finalizeActivityTimestampsIn: summary [

	| timestamps sorted |
	timestamps := summary at: #activityTimestamps.
	timestamps isEmpty ifTrue: [ ^ self ].
	sorted := timestamps asSortedCollection asArray.
	summary
		at: #firstActivity put: sorted first;
		at: #lastActivity put: sorted last
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> readJsonFile: file [

	(file exists and: [ file isFile ]) ifFalse: [ ^ Dictionary new ].
	^ self jsonFromString: file contents
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> jsonFromString: string [

	^ [
		| value |
		value := STONJSON fromString: (string ifNil: [ '' ]).
		(value isKindOf: Dictionary)
			ifTrue: [ value ]
			ifFalse: [ Dictionary new ] ]
		on: Error
		do: [ Dictionary new ]
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> valueAt: key from: dictionary default: default [

	| alternate |
	dictionary ifNil: [ ^ default ].
	(dictionary includesKey: key) ifTrue: [ ^ dictionary at: key ].
	key isSymbol ifTrue: [
		alternate := key asString.
		(dictionary includesKey: alternate) ifTrue: [ ^ dictionary at: alternate ] ].
	key isString ifTrue: [
		alternate := key asSymbol.
		(dictionary includesKey: alternate) ifTrue: [ ^ dictionary at: alternate ] ].
	^ default
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> dictionaryAt: key from: dictionary [

	^ (self dictionaryFrom: (self valueAt: key from: dictionary default: nil))
		ifNil: [ Dictionary new ]
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> dictionaryFrom: value [

	^ (value isKindOf: Dictionary)
		ifTrue: [ value ]
		ifFalse: [ nil ]
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> arrayAt: key from: dictionary [

	| value |
	value := self valueAt: key from: dictionary default: #().
	(value isString or: [ value isKindOf: Dictionary ]) ifTrue: [ ^ #() ].
	(value isCollection) ifTrue: [ ^ value asArray ].
	^ #()
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> stringAt: key from: dictionary [

	^ self stringValue: (self valueAt: key from: dictionary default: '')
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> stringValue: value [

	(value isNil or: [ value = false ]) ifTrue: [ ^ '' ].
	^ value asString
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> booleanAt: key from: dictionary [

	| value |
	value := self valueAt: key from: dictionary default: false.
	value = true ifTrue: [ ^ true ].
	^ value asString asLowercase = 'true'
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> nonNegativeIntegerAt: key from: dictionary [

	^ (self nonNegativeNumberAt: key from: dictionary) rounded max: 0
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> nonNegativeNumberAt: key from: dictionary [

	^ (self numberOrNil: (self valueAt: key from: dictionary default: 0)) ifNil: [ 0 ]
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> numberOrNil: value [

	value isNil ifTrue: [ ^ nil ].
	(value isNumber and: [ self numberIsFinite: value ]) ifTrue: [ ^ value ].
	^ [
		| number |
		number := value asString asNumber.
		(self numberIsFinite: number) ifTrue: [ number ] ifFalse: [ nil ] ]
		on: Error
		do: [ nil ]
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> increment: key in: dictionary [

	self add: 1 to: key in: dictionary
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> add: value to: key in: dictionary [

	dictionary at: key put: ((dictionary at: key ifAbsent: [ 0 ]) + value)
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> lineCountOf: text [

	| value count |
	value := self stringValue: text.
	value isEmpty ifTrue: [ ^ 0 ].
	count := 1.
	value do: [ :character |
		character = Character lf ifTrue: [ count := count + 1 ] ].
	^ count
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> averageCollection: values [

	values isEmpty ifTrue: [ ^ 0.0 ].
	^ self average: (self sumCollection: values) count: values size
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> latencyStatsByPathFor: latencyDictionary [

	| result |
	result := Dictionary new.
	latencyDictionary keysAndValuesDo: [ :path :values |
		result at: path put: (self latencyStatsFor: values) ].
	^ result
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> latencyStatsFor: values [

	^ Dictionary new
		at: #count put: values size;
		at: #p50_ms put: (self percentile: 50 of: values);
		at: #p90_ms put: (self percentile: 90 of: values);
		at: #p95_ms put: (self percentile: 95 of: values);
		at: #under_200ms_rate put: (self under: 200 rateFor: values);
		at: #under_500ms_rate put: (self under: 500 rateFor: values);
		at: #under_1000ms_rate put: (self under: 1000 rateFor: values);
		yourself
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> percentile: percentileNumber of: values [

	| sorted position lowerIndex upperIndex lowerValue upperValue fraction |
	values isEmpty ifTrue: [ ^ nil ].
	sorted := values asSortedCollection asArray.
	sorted size = 1 ifTrue: [
		^ self round: sorted first digits: 2 ].

	position := 1 + ((percentileNumber / 100.0) * (sorted size - 1)).
	lowerIndex := position floor.
	upperIndex := position ceiling.
	lowerValue := sorted at: lowerIndex.
	upperValue := sorted at: upperIndex.
	lowerIndex = upperIndex ifTrue: [
		^ self round: lowerValue digits: 2 ].

	fraction := position - lowerIndex.
	^ self
		round: lowerValue + ((upperValue - lowerValue) * fraction)
		digits: 2
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> sumCollection: values [

	^ values inject: 0.0 into: [ :total :each | total + each ]
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> numberIsFinite: number [

	^ (number respondsTo: #isFinite)
		ifTrue: [ number isFinite ]
		ifFalse: [ true ]
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> confidenceFromAvgLogprob: avgLogprob tokenCount: tokenCount [

	(avgLogprob isNil or: [ tokenCount = 0 ]) ifTrue: [ ^ nil ].
	^ [
		self round: avgLogprob exp * 100 digits: 2
	] on: Error do: [ nil ]
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> averageLogprobFromSum: sum tokenCount: tokenCount [

	tokenCount = 0 ifTrue: [ ^ nil ].
	^ self round: sum / tokenCount digits: 4
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> averageLogprobByKeyFromTokens: tokenCounts sums: sums [

	| result |
	result := Dictionary new.
	tokenCounts keysAndValuesDo: [ :key :tokenCount |
		result
			at: key
			put: (self
				averageLogprobFromSum: (sums at: key ifAbsent: [ 0.0 ])
				tokenCount: tokenCount) ].
	^ result
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> confidenceByKeyFromAverageLogprob: averageLogprobs tokens: tokenCounts [

	| result |
	result := Dictionary new.
	averageLogprobs keysAndValuesDo: [ :key :avgLogprob |
		result
			at: key
			put: (self
				confidenceFromAvgLogprob: avgLogprob
				tokenCount: (tokenCounts at: key ifAbsent: [ 0 ])) ].
	^ result
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> average: total count: count [

	count = 0 ifTrue: [ ^ 0.0 ].
	^ self round: total / count digits: 2
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> pct: value total: total [

	total = 0 ifTrue: [ ^ 0.0 ].
	^ self round: (100.0 * value / total) digits: 2
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> round: value digits: digits [

	| scale |
	value ifNil: [ ^ nil ].
	scale := 10 raisedTo: digits.
	^ (value * scale) rounded / scale asFloat
]

{ #category : 'private' }
CoPCSessionTelemetryAnalyzer class >> under: threshold rateFor: values [

	| count |
	values isEmpty ifTrue: [ ^ 0.0 ].
	count := values count: [ :each | each <= threshold ].
	^ self pct: count total: values size
]
