Class {
	#name : 'CoPCImageCloseSurveyTest',
	#superclass : 'CopilotMockModelTestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'support' }
CoPCImageCloseSurveyTest >> withIsolatedLoggerSessionDo: aBlock [

	| tempDir tempEvalFile sessionDir archiveFile originalDirRef originalLogRef originalEvalRef originalSessionRef originalArchiveRef originalUploader originalUserId originalSessionId originalStartedAt originalArchived |
	tempDir := FileLocator temp / ('copilot-image-close-session-test-' , UUID new asString).
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

	[
		tempDir exists ifTrue: [ tempDir ensureDeleteAll ].
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
		tempDir exists ifTrue: [ tempDir ensureDeleteAll ].
		CoPharoCopilotLogger rawLogsDirectoryReference: originalDirRef.
		CoPharoCopilotLogger rawSessionDirectoryReference: originalSessionRef.
		CoPharoCopilotLogger rawSessionArchiveFileReference: originalArchiveRef.
		CoPharoCopilotLogger rawSessionArchiveUploader: originalUploader.
		CoPharoCopilotLogger rawLogFileReference: originalLogRef.
		CoPharoCopilotLogger rawEvaluationLogFileReference: originalEvalRef.
		CoPharoCopilotLogger rawUserId: originalUserId.
		CoPharoCopilotLogger instVarNamed: #sessionId put: originalSessionId.
		CoPharoCopilotLogger instVarNamed: #sessionStartedAt put: originalStartedAt.
		CoPharoCopilotLogger instVarNamed: #sessionArchived put: originalArchived ]
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testArchiveCurrentSessionUploadsZipAfterWritingIt [

	CopilotSettings withDefaultSettingsDo: [
		self withIsolatedLoggerSessionDo: [ :tempDir :tempEvalFile :sessionDir :archiveFile |
			| uploadedArchive uploadedSession uploadedUser uploadSawExistingArchive uploadSawZipArchive |
			sessionDir ensureCreateDirectory.
			(sessionDir / 'marker.txt') writeStreamDo: [ :stream |
				stream nextPutAll: 'session marker' ].
			CoPharoCopilotLogger rawSessionArchiveUploader: [ :archive :session :user |
				uploadedArchive := archive.
				uploadedSession := session.
				uploadedUser := user.
				uploadSawExistingArchive := archive exists.
				uploadSawZipArchive := ZipArchive isZipArchive: archive ].

			CoPharoCopilotLogger archiveCurrentSession.

			self assert: uploadedArchive equals: archiveFile.
			self assert: uploadedSession equals: sessionDir basename.
			self assert: uploadedUser equals: 'user-test'.
			self assert: uploadSawExistingArchive.
			self assert: uploadSawZipArchive ] ]
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
				self assert: (ui requests size) equals: (CoPCImageCloseSurvey surveyQuestions size + 2) * 2.
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
			ratings := CoPCImageCloseSurvey promptAndRecordUsing: ui.

			self assert: ui requests size equals: CoPCImageCloseSurvey surveyQuestions size + 2.
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
			self assert: ((data at: #availableTasks) includesKey: #codeCompletion).
			self deny: (data includesKey: #availableUserRoles).
			self assert: ((data at: #availableUserExperience) includesKey: '5').
			self assert: ((data at: #questions) includesKey: #overall).
			self assert: (data includesKey: #timestamp).
			self assert: (data includesKey: #modelName)
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
				self assert: (ui requests size) equals: CoPCImageCloseSurvey surveyQuestions size + 2.
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
