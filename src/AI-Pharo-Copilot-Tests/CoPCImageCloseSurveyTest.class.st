Class {
	#name : 'CoPCImageCloseSurveyTest',
	#superclass : 'CopilotMockModelTestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'support' }
CoPCImageCloseSurveyTest >> withIsolatedLoggerSessionDo: aBlock [

	| rootDir tempDir tempEvalFile sessionDir archiveFile originalDirRef originalLogRef originalEvalRef originalSessionRef originalArchiveRef originalUploader originalUserId originalSessionId originalStartedAt originalArchived originalComplishonRerouteCount |
	rootDir := FileLocator temp / ('copilot-image-close-session-test-' , UUID new asString).
	tempDir := rootDir / CoPharoCopilotLogger pharoCopilotDirectoryName.
	sessionDir := tempDir / 'session-test'.
	tempEvalFile := sessionDir / CoPharoCopilotLogger evaluationLogFileName.
	archiveFile := tempDir / 'session-test.zip'.
	originalDirRef := CoPharoCopilotLogger rawLogsDirectoryReference.
	originalLogRef := CoPharoCopilotLogger rawLogFileReference.
	originalEvalRef := CoPharoCopilotLogger rawEvaluationLogFileReference.
	originalSessionRef := CoPharoCopilotLogger rawSessionDirectoryReference.
	originalArchiveRef := CoPharoCopilotLogger rawSessionArchiveFileReference.
	originalUploader := CoPharoCopilotLogger rawSessionArchiveUploader.
	originalUserId := CoPharoCopilotLogger rawUserId.
	originalSessionId := CoPharoCopilotLogger instVarNamed: #sessionId.
	originalStartedAt := CoPharoCopilotLogger instVarNamed: #sessionStartedAt.
	originalArchived := CoPharoCopilotLogger instVarNamed: #sessionArchived.
	originalComplishonRerouteCount := CoPharoCopilotLogger instVarNamed: #complishonRerouteCount.

	[
		rootDir exists ifTrue: [ rootDir ensureDeleteAll ].
		tempDir ensureCreateDirectory.
		CoPharoCopilotLogger rawLogsDirectoryReference: tempDir.
		CoPharoCopilotLogger rawSessionDirectoryReference: sessionDir.
		CoPharoCopilotLogger rawSessionArchiveFileReference: archiveFile.
		CoPharoCopilotLogger rawSessionArchiveUploader: [ :archive :session :user | nil ].
		CoPharoCopilotLogger rawLogFileReference: sessionDir / CoPharoCopilotLogger logFileName.
		CoPharoCopilotLogger rawEvaluationLogFileReference: tempEvalFile.
		CoPharoCopilotLogger rawUserId: 'user-test'.
		CopilotSettings recordResearchTelemetryConsentAccepted: true.
		tempEvalFile exists ifTrue: [ tempEvalFile ensureDelete ].
		aBlock
			value: tempDir
			value: tempEvalFile
			value: sessionDir
			value: archiveFile
	] ensure: [
		rootDir exists ifTrue: [ rootDir ensureDeleteAll ].
		CoPharoCopilotLogger rawLogsDirectoryReference: originalDirRef.
		CoPharoCopilotLogger rawSessionDirectoryReference: originalSessionRef.
		CoPharoCopilotLogger rawSessionArchiveFileReference: originalArchiveRef.
		CoPharoCopilotLogger rawSessionArchiveUploader: originalUploader.
		CoPharoCopilotLogger rawLogFileReference: originalLogRef.
		CoPharoCopilotLogger rawEvaluationLogFileReference: originalEvalRef.
		CoPharoCopilotLogger rawUserId: originalUserId.
		CoPharoCopilotLogger instVarNamed: #sessionId put: originalSessionId.
		CoPharoCopilotLogger instVarNamed: #sessionStartedAt put: originalStartedAt.
		CoPharoCopilotLogger instVarNamed: #sessionArchived put: originalArchived.
		CoPharoCopilotLogger instVarNamed: #complishonRerouteCount put: originalComplishonRerouteCount ]
]

{ #category : 'support' }
CoPCImageCloseSurveyTest >> writeTelemetryFixtureIn: sessionDir evaluationLog: tempEvalFile [

	| completionsDir response attempt payload ratings evalData evalEvent rerouteEvent1 rerouteEvent2 |
	sessionDir ensureCreateDirectory.
	completionsDir := sessionDir / 'completions'.
	completionsDir ensureCreateDirectory.

	response := Dictionary new
		at: #logprobs put: {
			(Dictionary new at: #logprob put: -0.1; yourself).
			(Dictionary new at: #logprob put: -0.2; yourself) };
		at: #prompt_eval_count put: 10;
		at: #eval_count put: 2;
		yourself.
	attempt := Dictionary new
		at: #suggestion put: 'String';
		at: #response put: response;
		yourself.
	payload := Dictionary new
		at: #timestamp put: '2026-08-11T10:00:00+02:00';
		at: #userId put: 'user-test';
		at: #loggerSessionId put: sessionDir basename;
		at: #cache put: (Dictionary new
			at: #hits put: 2;
			at: #misses put: 3;
			yourself);
		at: #context put: (Dictionary new
			at: #fullSource put: 'example', String cr, String tab, 'self as';
			at: #classContext put: 'Object';
			yourself);
		at: #fim put: (Dictionary new
			at: #prefix put: 'self as';
			at: #suffix put: '';
			yourself);
		at: #generated put: (Dictionary new
			at: #suggestions put: { 'String' };
			at: #attempts put: { attempt };
			yourself);
		at: #completionEnvironment put: (Dictionary new
			at: #kind put: #systemBrowser;
			at: #windowTitle put: 'System Browser';
			yourself);
		at: #accepted put: 'String';
		at: #acceptedAt put: '2026-08-11T10:00:01+02:00';
		at: #nullCompletion put: false;
		at: #rejected put: #();
		yourself.

	(completionsDir / 'completion-1.json') writeStreamDo: [ :stream |
		stream nextPutAll: (STONJSON toString: payload) ].

	ratings := Dictionary new
		at: #overall put: 5;
		at: #suggestionQuality put: 4;
		at: #speed put: 5;
		at: #usefulness put: 4;
		yourself.
	evalData := Dictionary new
		at: #tasks put: #(#codeCompletion);
		at: #ratings put: ratings;
		yourself.
	evalEvent := Dictionary new
		at: #event put: 'image-close-survey';
		at: #timestamp put: '2026-08-11T10:01:00+02:00';
		at: #userId put: 'user-test';
		at: #sessionId put: sessionDir basename;
		at: #data put: evalData;
		at: #sessionStats put: (Dictionary new
			at: #totalSuggestions put: 1;
			at: #totalAccepted put: 1;
			at: #totalRejected put: 0;
			yourself);
		yourself.
	rerouteEvent1 := Dictionary new
		at: #event put: 'completion-rerouted-to-complishon';
		at: #timestamp put: '2026-08-11T10:00:10+02:00';
		at: #userId put: 'user-test';
		at: #sessionId put: sessionDir basename;
		at: #data put: (Dictionary new
			at: #oldEngine put: #Complishon;
			at: #reason put: #standaloneScriptingContext;
			at: #rerouteCount put: 1;
			at: #completionEnvironment put: (Dictionary new
				at: #kind put: #playground;
				at: #windowTitle put: 'Playground';
				yourself);
			yourself);
		yourself.
	rerouteEvent2 := Dictionary new
		at: #event put: 'completion-rerouted-to-complishon';
		at: #timestamp put: '2026-08-11T10:00:20+02:00';
		at: #userId put: 'user-test';
		at: #sessionId put: sessionDir basename;
		at: #data put: (Dictionary new
			at: #oldEngine put: #Complishon;
			at: #reason put: #standaloneScriptingContext;
			at: #rerouteCount put: 2;
			at: #completionEnvironment put: (Dictionary new
				at: #kind put: #playground;
				at: #windowTitle put: 'Playground';
				yourself);
			yourself);
		yourself.
	tempEvalFile writeStreamDo: [ :stream |
		{ rerouteEvent1. rerouteEvent2. evalEvent } do: [ :event |
			stream
				nextPutAll: (STONJSON toString: event);
				nextPut: Character lf ] ]
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testArchiveCurrentSessionDoesNotUploadZip [

	CopilotSettings withDefaultSettingsDo: [
		self withIsolatedLoggerSessionDo: [ :tempDir :tempEvalFile :sessionDir :archiveFile |
			| spy |
			sessionDir ensureCreateDirectory.
			(sessionDir / 'marker.txt') writeStreamDo: [ :stream |
				stream nextPutAll: 'session marker' ].
			spy := CoPCSessionArchiveUploaderSpy new.
			CoPharoCopilotLogger rawSessionArchiveUploader: spy.

			CoPharoCopilotLogger archiveCurrentSession.

			self assert: archiveFile exists.
			self assert: (ZipArchive isZipArchive: archiveFile).
			self assert: spy uploadedArchive isNil.
			self deny: spy uploadSawExistingArchive.
			self deny: spy uploadSawZipArchive ] ]
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testArchiveCurrentSessionWritesJsonToJsonDirectoryAndUploadsOnlyIt [

	CopilotSettings withDefaultSettingsDo: [
		self withIsolatedLoggerSessionDo: [ :tempDir :tempEvalFile :sessionDir :archiveFile |
			| spy summaryFile payload session summary environmentCounts rerouteEnvironmentCounts |
			self writeTelemetryFixtureIn: sessionDir evaluationLog: tempEvalFile.
			spy := CoPCSessionArchiveUploaderSpy new.
			CoPharoCopilotLogger rawSessionArchiveUploader: spy.

			CoPharoCopilotLogger archiveCurrentSession.

			summaryFile := CoPharoCopilotLogger telemetryJsonDirectoryReference / (sessionDir basename , '-telemetry.json').
			self assert: archiveFile exists.
			self assert: summaryFile exists.
			self assert: (summaryFile fullName includesSubstring: CoPharoCopilotLogger telemetryJsonDirectoryName).
			self assert: spy uploadedArchive isNil.
			self assert: spy uploadedTelemetrySummary fullName equals: summaryFile fullName.
			self assert: spy telemetrySession equals: sessionDir basename.
			self assert: spy telemetryUser equals: 'user-test'.
			self deny: spy uploadSawExistingArchive.
			self deny: spy uploadSawZipArchive.
			self assert: spy uploadSawExistingTelemetrySummary.

			payload := spy telemetryPayload.
			session := payload at: #session.
			summary := payload at: #summary.
			self assert: (payload at: #event) equals: 'pharo-copilot-session-telemetry'.
			self assert: (payload at: #sessionId) equals: sessionDir basename.
			self assert: (payload at: #archiveFile) equals: archiveFile basename.
			self assert: ((payload at: #completionFiles) includes: 'completion-1.json').
			self assert: (session at: #sessionId) equals: sessionDir basename.
			self assert: (summary at: #completion_requests) equals: 1.
			self assert: (summary at: #completion_attempts) equals: 3.
			self assert: (summary at: #complishon_reroute_count) equals: 2.
			self assert: (summary at: #complishon_reroute_rate) equals: 66.67.
			self assert: (summary at: #accepted_requests) equals: 1.
			self assert: (summary at: #suggestion_candidates) equals: 1.
			self assert: (summary at: #self_receiver_completion_requests) equals: 1.
			self assert: (summary at: #logprob_tokens) equals: 2.
			self assert: (summary at: #prompt_tokens) equals: 10.
			self assert: (summary at: #completion_tokens) equals: 2.
			self assert: (summary at: #cache_hit_rate) equals: 40.0.
			environmentCounts := summary at: #completion_environment_counts.
			rerouteEnvironmentCounts := summary at: #complishon_reroute_environment_counts.
			self assert: (environmentCounts at: 'systemBrowser') equals: 1.
			self assert: (rerouteEnvironmentCounts at: 'playground') equals: 2 ] ]
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testCancellingSurveyDoesNotWriteEvaluationEvent [

	CopilotSettings withDefaultSettingsDo: [
		self withIsolatedLoggerSessionDo: [ :tempDir :tempEvalFile :sessionDir :archiveFile |
			| ui result |
			ui := CoPCImageCloseSurveyUIManagerDouble new.
			ui ratings: #().
			result := CoPCImageCloseSurvey promptAndRecordUsing: ui.

			self assert: result isNil.
			self deny: tempEvalFile exists ] ]
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testPromptBeforeImageQuitAppendsEveryCloseAttempt [

	CopilotSettings withDefaultSettingsDo: [
		self withIsolatedLoggerSessionDo: [ :tempDir :tempEvalFile :sessionDir :archiveFile |
			| ui firstLine secondLine thirdLine firstEvent secondEvent |
			[
				CoPCImageCloseSurvey resetPromptState.

				ui := CoPCImageCloseSurveyUIManagerDouble new.
				ui ratings: {
					5. 5. 4. 5. #codeCompletion. 2.
					4. 4. 4. 4. #debugging. 5 }.
				ui comments: { 'First session feedback'. 'Second session feedback' }.
				CoPCImageCloseSurvey promptBeforeImageQuitUsing: ui.
				CoPCImageCloseSurvey promptBeforeImageQuitUsing: ui.

				tempEvalFile readStreamDo: [ :stream |
					firstLine := stream nextLine.
					secondLine := stream nextLine.
					thirdLine := stream nextLine ].

				firstEvent := STONJSON fromString: firstLine.
				secondEvent := STONJSON fromString: secondLine.

				self assert: firstLine isNotNil.
				self assert: secondLine isNotNil.
				self assert: thirdLine isNil.
				self assert: (firstEvent at: #event) equals: 'image-close-survey'.
				self assert: (secondEvent at: #event) equals: 'image-close-survey'.
				self assert: (ui requests size) equals: (CoPCImageCloseSurvey surveyQuestions size + 3) * 2.
				self assert: archiveFile exists
			] ensure: [
			CoPCImageCloseSurvey resetPromptState ] ] ]
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testPromptAndRecordWritesImageCloseSurveyEvent [

	CopilotSettings withDefaultSettingsDo: [
		self withIsolatedLoggerSessionDo: [ :tempDir :tempEvalFile :sessionDir :archiveFile |
			| ui ratings jsonLine parsed data storedRatings storedTasks userProfile |
			ui := CoPCImageCloseSurveyUIManagerDouble new.
			ui ratings: { 4. 3. 5. 4. #codeCompletion. 5 }.
			ui comments: { 'Useful overall, but speed varied.' }.
			ratings := CoPCImageCloseSurvey promptAndRecordUsing: ui.

			self assert: ui requests size equals: CoPCImageCloseSurvey surveyQuestions size + 3.
			self assert: (ui requests last at: #answerHeight) equals: CoPCImageCloseSurvey optionalCommentAnswerHeight.
			self assert: (ratings at: #overall) equals: 4.
			self assert: (ratings at: #suggestionQuality) equals: 3.

			jsonLine := tempEvalFile readStreamDo: [ :stream | stream nextLine ].
			parsed := STONJSON fromString: jsonLine.
			data := parsed at: #data.
			storedRatings := data at: #ratings.
			storedTasks := data at: #tasks.
			userProfile := data at: #userProfile.

			self assert: (parsed at: #event) equals: 'image-close-survey'.
			self assert: (parsed at: #userId) equals: 'user-test'.
			self assert: (parsed at: #sessionId) equals: sessionDir basename.
			self assert: (storedRatings at: #overall) equals: 4.
			self assert: (storedRatings at: #suggestionQuality) equals: 3.
			self assert: (storedRatings at: #speed) equals: 5.
			self assert: (storedRatings at: #usefulness) equals: 4.
			self assert: (storedTasks includes: #codeCompletion).
			self assert: storedTasks size equals: 1.
			self deny: (userProfile includesKey: #role).
			self assert: (userProfile at: #experienceYears) equals: 5.
			self assert: (data at: #feedbackComment) equals: 'Useful overall, but speed varied.'.
			self assert: ((data at: #availableTasks) includesKey: #codeCompletion).
			self deny: (data includesKey: #availableUserRoles).
			self assert: ((data at: #availableUserExperience) includesKey: '5').
			self assert: ((data at: #questions) includesKey: #overall).
			self assert: (data includesKey: #timestamp).
			self assert: (data includesKey: #modelName)
		] ]
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testPromptAndRecordContinuesWithBlankOptionalComment [

	CopilotSettings withDefaultSettingsDo: [
		self withIsolatedLoggerSessionDo: [ :tempDir :tempEvalFile :sessionDir :archiveFile |
			| ui ratings jsonLine parsed data |
			ui := CoPCImageCloseSurveyUIManagerDouble new.
			ui ratings: { 5. 5. 5. 5. #codeCompletion. 2 }.
			ui comments: { '' }.
			ratings := CoPCImageCloseSurvey promptAndRecordUsing: ui.

			self assert: ratings isNotNil.
			jsonLine := tempEvalFile readStreamDo: [ :stream | stream nextLine ].
			parsed := STONJSON fromString: jsonLine.
			data := parsed at: #data.

			self assert: (data at: #feedbackComment) equals: ''
		] ]
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testPromptBeforeImageQuitWritesOnceAndSkipsShutdownFallback [

	CopilotSettings withDefaultSettingsDo: [
		self withIsolatedLoggerSessionDo: [ :tempDir :tempEvalFile :sessionDir :archiveFile |
			| ui firstLine secondLine |
			[
				CoPCImageCloseSurvey resetPromptState.

				ui := CoPCImageCloseSurveyUIManagerDouble new.
				ui ratings: { 5. 5. 4. 5. #codeCompletion. 10 }.
				CoPCImageCloseSurvey promptBeforeImageQuitUsing: ui.
				CoPCImageCloseSurvey shutDown: true.

				tempEvalFile readStreamDo: [ :stream |
					firstLine := stream nextLine.
					secondLine := stream nextLine ].

				self assert: firstLine isNotNil.
				self assert: secondLine isNil.
				self assert: (ui requests size) equals: CoPCImageCloseSurvey surveyQuestions size + 3.
				self assert: archiveFile exists
			] ensure: [
			CoPCImageCloseSurvey resetPromptState ] ] ]
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testPromptBeforeImageQuitZipsSessionFolder [

	CopilotSettings withDefaultSettingsDo: [
		self withIsolatedLoggerSessionDo: [ :tempDir :tempEvalFile :sessionDir :archiveFile |
			| ui archive memberNames |
			[
				CoPCImageCloseSurvey resetPromptState.
				sessionDir ensureCreateDirectory.
				(sessionDir / 'marker.txt') writeStreamDo: [ :stream |
					stream nextPutAll: 'session marker' ].

				ui := CoPCImageCloseSurveyUIManagerDouble new.
				ui ratings: { 5. 5. 5. 5. #codeCompletion. 2 }.
				CoPCImageCloseSurvey promptBeforeImageQuitUsing: ui.

				self assert: archiveFile exists.
				self assert: (ZipArchive isZipArchive: archiveFile).
				archive := ZipArchive new.
				[
					archive readFrom: archiveFile.
					memberNames := archive memberNames.
					self assert: (memberNames includes: sessionDir basename , '/marker.txt').
					self assert: (memberNames includes: sessionDir basename , '/session-info.json').
					self assert: (memberNames includes: sessionDir basename , '/copilot-evaluation-log.jsonl')
				] ensure: [
					archive close ]
			] ensure: [
				CoPCImageCloseSurvey resetPromptState ] ] ]
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testLoggerCreatesStableUserIdAndNewSessionIds [

	CopilotSettings withDefaultSettingsDo: [
		self withIsolatedLoggerSessionDo: [ :tempDir :tempEvalFile :sessionDir :archiveFile |
			| firstUser firstSession secondUser secondSession userIdFile firstSessionDir secondSessionDir |
			CoPharoCopilotLogger rawUserId: nil.
			firstUser := CoPharoCopilotLogger userId.
			firstSession := CoPharoCopilotLogger currentSessionId.
			firstSessionDir := CoPharoCopilotLogger rawSessionDirectoryReference.

			CoPharoCopilotLogger startNewSession.

			secondUser := CoPharoCopilotLogger userId.
			secondSession := CoPharoCopilotLogger currentSessionId.
			secondSessionDir := CoPharoCopilotLogger rawSessionDirectoryReference.
			userIdFile := tempDir / CoPharoCopilotLogger userIdFileName.

			self assert: firstUser equals: secondUser.
			self deny: firstSession equals: secondSession.
			self deny: firstSessionDir equals: secondSessionDir.
			self assert: userIdFile exists.
			self assert: userIdFile contents trimBoth equals: firstUser.
			self assert: (firstUser beginsWith: 'user-') ] ]
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testSurveyEnabledSettingIsPersistedInSnapshots [

	CopilotSettings withDefaultSettingsDo: [
		| snapshot serializable |
		CopilotSettings imageCloseSurveyEnabled: false.
		snapshot := CopilotSettings settingsSnapshot.
		serializable := CopilotSettings serializableSettingsSnapshot.

		self deny: (snapshot at: #imageCloseSurveyEnabled).
		self deny: (serializable at: #imageCloseSurveyEnabled).

		CopilotSettings imageCloseSurveyEnabled: true.
		CopilotSettings restoreSettingsFromSnapshot: snapshot.
		self deny: CopilotSettings imageCloseSurveyEnabled.

		CopilotSettings imageCloseSurveyEnabled: true.
		CopilotSettings restoreSettingsFromSerializableSnapshot: serializable.
		self deny: CopilotSettings imageCloseSurveyEnabled ]
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testSurveyRegistersAsSessionHandler [

	| wasRegistered |
	wasRegistered := CoPCImageCloseSurvey isSessionHandlerRegistered.
	[
		self assert: CoPCImageCloseSurvey registerSessionHandler.
		self assert: CoPCImageCloseSurvey isSessionHandlerRegistered
	] ensure: [
		wasRegistered ifFalse: [ CoPCImageCloseSurvey unregisterSessionHandler ] ]
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testValidatedRatingAcceptsOnlyOneToFive [

	self assert: (CoPCImageCloseSurvey validatedRating: 1) equals: 1.
	self assert: (CoPCImageCloseSurvey validatedRating: '4') equals: 4.
	self assert: (CoPCImageCloseSurvey validatedRating: 5) equals: 5.
	self assert: (CoPCImageCloseSurvey validatedRating: 0) isNil.
	self assert: (CoPCImageCloseSurvey validatedRating: 6) isNil.
	self assert: (CoPCImageCloseSurvey validatedRating: 'bad') isNil
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testTaskLabelsDoNotIncludeDone [

	self deny: (CoPCImageCloseSurvey taskLabels includes: 'Done').
	self deny: (CoPCImageCloseSurvey taskValues includes: #done)
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testValidatedTaskAcceptsOnlyAvailableTasks [

	self assert: (CoPCImageCloseSurvey validatedTask: #codeCompletion) equals: #codeCompletion.
	self assert: (CoPCImageCloseSurvey validatedTask: 'debugging') equals: #debugging.
	self assert: (CoPCImageCloseSurvey validatedTask: #done) isNil.
	self assert: (CoPCImageCloseSurvey validatedTask: #unknown) isNil.
	self assert: (CoPCImageCloseSurvey validatedTask: nil) isNil
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testValidatedUserExperienceAcceptsConfiguredBuckets [

	self assert: (CoPCImageCloseSurvey validatedUserExperience: 0) equals: 0.
	self assert: (CoPCImageCloseSurvey validatedUserExperience: '2') equals: 2.
	self assert: (CoPCImageCloseSurvey validatedUserExperience: 5) equals: 5.
	self assert: (CoPCImageCloseSurvey validatedUserExperience: 10) equals: 10.
	self assert: (CoPCImageCloseSurvey validatedUserExperience: -1) isNil.
	self assert: (CoPCImageCloseSurvey validatedUserExperience: '3') isNil.
	self assert: (CoPCImageCloseSurvey validatedUserExperience: 11) isNil.
	self assert: (CoPCImageCloseSurvey validatedUserExperience: 'bad') isNil
]
