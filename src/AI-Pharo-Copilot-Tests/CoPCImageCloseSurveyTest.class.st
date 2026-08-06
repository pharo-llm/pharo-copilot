Class {
	#name : 'CoPCImageCloseSurveyTest',
	#superclass : 'CopilotMockModelTestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testCancellingSurveyDoesNotWriteEvaluationEvent [

	CopilotSettings withDefaultSettingsDo: [
		| tempDir tempEvalFile originalDirRef originalEvalRef ui result |
		tempDir := FileLocator temp / ('copilot-image-close-survey-cancel-test-' , UUID new asString).
		tempEvalFile := tempDir / CoPharoCopilotLogger evaluationLogFileName.
		originalDirRef := CoPharoCopilotLogger rawLogsDirectoryReference.
		originalEvalRef := CoPharoCopilotLogger rawEvaluationLogFileReference.
		[
			CoPharoCopilotLogger rawLogsDirectoryReference: tempDir.
			CoPharoCopilotLogger rawEvaluationLogFileReference: tempEvalFile.
			tempEvalFile exists ifTrue: [ tempEvalFile ensureDelete ].

			ui := CoPCImageCloseSurveyUIManagerDouble new.
			ui ratings: #().
			result := CoPCImageCloseSurvey promptAndRecordUsing: ui.

			self assert: result isNil.
			self deny: tempEvalFile exists
		] ensure: [
			tempEvalFile exists ifTrue: [ tempEvalFile ensureDelete ].
			tempDir exists ifTrue: [ tempDir ensureDelete ].
			CoPharoCopilotLogger rawLogsDirectoryReference: originalDirRef.
			CoPharoCopilotLogger rawEvaluationLogFileReference: originalEvalRef ] ]
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testPromptAndRecordWritesImageCloseSurveyEvent [

	CopilotSettings withDefaultSettingsDo: [
		| tempDir tempEvalFile originalDirRef originalEvalRef ui ratings jsonLine parsed data storedRatings storedTasks |
		tempDir := FileLocator temp / ('copilot-image-close-survey-test-' , UUID new asString).
		tempEvalFile := tempDir / CoPharoCopilotLogger evaluationLogFileName.
		originalDirRef := CoPharoCopilotLogger rawLogsDirectoryReference.
		originalEvalRef := CoPharoCopilotLogger rawEvaluationLogFileReference.
		[
			CoPharoCopilotLogger rawLogsDirectoryReference: tempDir.
			CoPharoCopilotLogger rawEvaluationLogFileReference: tempEvalFile.
			tempEvalFile exists ifTrue: [ tempEvalFile ensureDelete ].

			ui := CoPCImageCloseSurveyUIManagerDouble new.
			ui ratings: { 4. 3. 5. 4. #codeCompletion }.
			ratings := CoPCImageCloseSurvey promptAndRecordUsing: ui.

			self assert: ui requests size equals: CoPCImageCloseSurvey surveyQuestions size + 1.
			self assert: (ratings at: #overall) equals: 4.
			self assert: (ratings at: #suggestionQuality) equals: 3.

			jsonLine := tempEvalFile readStreamDo: [ :stream | stream nextLine ].
			parsed := STONJSON fromString: jsonLine.
			data := parsed at: #data.
			storedRatings := data at: #ratings.
			storedTasks := data at: #tasks.

			self assert: (parsed at: #event) equals: 'image-close-survey'.
			self assert: (storedRatings at: #overall) equals: 4.
			self assert: (storedRatings at: #suggestionQuality) equals: 3.
			self assert: (storedRatings at: #speed) equals: 5.
			self assert: (storedRatings at: #usefulness) equals: 4.
			self assert: (storedTasks includes: #codeCompletion).
			self assert: storedTasks size equals: 1.
			self assert: ((data at: #availableTasks) includesKey: #codeCompletion).
			self assert: ((data at: #questions) includesKey: #overall).
			self assert: (data includesKey: #timestamp).
			self assert: (data includesKey: #modelName)
		] ensure: [
			tempEvalFile exists ifTrue: [ tempEvalFile ensureDelete ].
			tempDir exists ifTrue: [ tempDir ensureDelete ].
			CoPharoCopilotLogger rawLogsDirectoryReference: originalDirRef.
			CoPharoCopilotLogger rawEvaluationLogFileReference: originalEvalRef ] ]
]

{ #category : 'tests' }
CoPCImageCloseSurveyTest >> testPromptBeforeImageQuitWritesOnceAndSkipsShutdownFallback [

	CopilotSettings withDefaultSettingsDo: [
		| tempDir tempEvalFile originalDirRef originalEvalRef ui firstLine secondLine |
		tempDir := FileLocator temp / ('copilot-image-close-prequit-test-' , UUID new asString).
		tempEvalFile := tempDir / CoPharoCopilotLogger evaluationLogFileName.
		originalDirRef := CoPharoCopilotLogger rawLogsDirectoryReference.
		originalEvalRef := CoPharoCopilotLogger rawEvaluationLogFileReference.
		[
			CoPCImageCloseSurvey resetPromptState.
			CoPharoCopilotLogger rawLogsDirectoryReference: tempDir.
			CoPharoCopilotLogger rawEvaluationLogFileReference: tempEvalFile.
			tempEvalFile exists ifTrue: [ tempEvalFile ensureDelete ].

			ui := CoPCImageCloseSurveyUIManagerDouble new.
			ui ratings: { 5. 5. 4. 5. #codeCompletion }.
			CoPCImageCloseSurvey promptBeforeImageQuitUsing: ui.
			CoPCImageCloseSurvey shutDown: true.

			tempEvalFile readStreamDo: [ :stream |
				firstLine := stream nextLine.
				secondLine := stream nextLine ].

			self assert: firstLine isNotNil.
			self assert: secondLine isNil.
			self assert: (ui requests size) equals: CoPCImageCloseSurvey surveyQuestions size + 1
		] ensure: [
			CoPCImageCloseSurvey resetPromptState.
			tempEvalFile exists ifTrue: [ tempEvalFile ensureDelete ].
			tempDir exists ifTrue: [ tempDir ensureDelete ].
			CoPharoCopilotLogger rawLogsDirectoryReference: originalDirRef.
			CoPharoCopilotLogger rawEvaluationLogFileReference: originalEvalRef ] ]
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
