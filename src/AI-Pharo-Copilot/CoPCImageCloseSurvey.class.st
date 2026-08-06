"
I ask a short star-rating survey when the Pharo image is about to quit.
Answers are appended to the Copilot evaluation JSONL log.
"
Class {
	#name : 'CoPCImageCloseSurvey',
	#superclass : 'Object',
	#classInstVars : [
		'promptInProgress',
		'promptedForCurrentQuit'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'survey' }
CoPCImageCloseSurvey class >> askQuestion: anAssociation using: uiManager [

	| rating |
	uiManager ifNil: [ ^ nil ].
	(uiManager respondsTo: #chooseFrom:values:title:) ifFalse: [ ^ nil ].

	rating := uiManager
		chooseFrom: self ratingLabels
		values: self ratingValues
		title: anAssociation value.

	^ self validatedRating: rating
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> askTaskUsing: uiManager selectedTasks: selectedTasks [

	| task |
	uiManager ifNil: [ ^ self taskSelectionDoneValue ].
	(uiManager respondsTo: #chooseFrom:values:title:) ifFalse: [ ^ self taskSelectionDoneValue ].

	task := uiManager
		chooseFrom: self taskLabels
		values: self taskValues
		title: (self taskQuestionTitleFor: selectedTasks).

	^ self validatedTask: task
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> availableTaskLabelsByKey [

	| labels |
	labels := Dictionary new.
	self taskChoices do: [ :task |
		labels at: task key put: task value ].
	^ labels
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> collectRatingsUsing: uiManager [

	| ratings rating |
	ratings := Dictionary new.
	self surveyQuestions do: [ :question |
		rating := self askQuestion: question using: uiManager.
		rating ifNil: [ ^ nil ].
		ratings at: question key put: rating ].
	^ ratings
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> collectTasksUsing: uiManager [

	| selected task |
	selected := OrderedCollection new.
	[
		task := self askTaskUsing: uiManager selectedTasks: selected.
		task notNil and: [ task ~= self taskSelectionDoneValue ]
	] whileTrue: [
		(selected includes: task) ifFalse: [ selected add: task ] ].
	^ selected asArray
]

{ #category : 'private' }
CoPCImageCloseSurvey class >> hasInteractiveUI [

	| manager |
	(Smalltalk respondsTo: #isInteractive) ifTrue: [
		Smalltalk isInteractive ifFalse: [ ^ false ] ].

	manager := self uiManager.
	manager ifNil: [ ^ false ].
	manager class name = #NonInteractiveUIManager ifTrue: [ ^ false ].
	^ manager respondsTo: #chooseFrom:values:title:
]

{ #category : 'session management' }
CoPCImageCloseSurvey class >> isSessionHandlerRegistered [

	| sessionManagerClass manager |
	sessionManagerClass := Smalltalk globals at: #SessionManager ifAbsent: [ ^ false ].
	(sessionManagerClass respondsTo: #default) ifFalse: [ ^ false ].
	manager := sessionManagerClass default.
	(manager respondsTo: #hasRegistered:) ifFalse: [ ^ false ].
	^ manager hasRegistered: self name
]

{ #category : 'logging' }
CoPCImageCloseSurvey class >> logSurveyError: anException [

	CoPharoCopilotLogger
		logBackEndEvent: 'Image close survey failed'
		details: (Dictionary new
			at: #errorClass put: anException class name;
			at: #error put: anException description;
			yourself)
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> promptAndRecordUsing: uiManager [

	| ratings tasks |
	ratings := self collectRatingsUsing: uiManager.
	ratings ifNil: [ ^ nil ].
	tasks := self collectTasksUsing: uiManager.
	self recordRatings: ratings tasks: tasks.
	^ ratings
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> promptBeforeImageQuit [

	(self shouldPromptBeforeImageQuit) ifFalse: [ ^ nil ].
	^ self promptBeforeImageQuitUsing: self uiManager
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> promptBeforeImageQuitUsing: uiManager [

	promptInProgress = true ifTrue: [ ^ nil ].
	promptedForCurrentQuit = true ifTrue: [ ^ nil ].

	promptedForCurrentQuit := true.
	promptInProgress := true.
	[
		[
			^ self promptAndRecordUsing: uiManager
		] on: Error do: [ :ex |
			self logSurveyError: ex.
			^ nil ]
	] ensure: [
		promptInProgress := false ]
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> questionLabelsByKey [

	| labels |
	labels := Dictionary new.
	self surveyQuestions do: [ :question |
		labels at: question key put: question value ].
	^ labels
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> ratingLabels [

	^ #(
		'1 star - Poor'
		'2 stars - Fair'
		'3 stars - Good'
		'4 stars - Very good'
		'5 stars - Excellent'
	)
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> ratingValues [

	^ #(1 2 3 4 5)
]

{ #category : 'logging' }
CoPCImageCloseSurvey class >> recordRatings: aDictionary [

	self recordRatings: aDictionary tasks: #()
]

{ #category : 'logging' }
CoPCImageCloseSurvey class >> recordRatings: ratingsDictionary tasks: taskCollection [

	CoPharoCopilotLogger
		appendEvaluationEvent: 'image-close-survey'
		data: (self surveyPayloadForRatings: ratingsDictionary tasks: taskCollection)
]

{ #category : 'session management' }
CoPCImageCloseSurvey class >> registerSessionHandler [

	| sessionManagerClass manager |
	sessionManagerClass := Smalltalk globals at: #SessionManager ifAbsent: [ ^ false ].
	(sessionManagerClass respondsTo: #default) ifFalse: [ ^ false ].
	manager := sessionManagerClass default.
	(manager respondsTo: #registerUserClassNamed:) ifFalse: [ ^ false ].

	manager registerUserClassNamed: self name.
	^ true
]

{ #category : 'session management' }
CoPCImageCloseSurvey class >> shouldPromptForImageQuitting: aBoolean [

	aBoolean ifFalse: [ ^ false ].
	promptedForCurrentQuit = true ifTrue: [ ^ false ].
	^ self shouldPromptBeforeImageQuit
]

{ #category : 'session management' }
CoPCImageCloseSurvey class >> shouldPromptBeforeImageQuit [

	CopilotSettings loggingEnabled ifFalse: [ ^ false ].
	CopilotSettings imageCloseSurveyEnabled ifFalse: [ ^ false ].
	^ self hasInteractiveUI
]

{ #category : 'session management' }
CoPCImageCloseSurvey class >> shutDown: isImageQuitting [

	(self shouldPromptForImageQuitting: isImageQuitting) ifFalse: [ ^ self ].
	promptInProgress = true ifTrue: [ ^ self ].

	promptInProgress := true.
	[
		[
			self promptAndRecordUsing: self uiManager
		] on: Error do: [ :ex |
			self logSurveyError: ex ]
	] ensure: [
		promptInProgress := false ]
]

{ #category : 'session management' }
CoPCImageCloseSurvey class >> startUp: isImageStarting [

	self resetPromptState
]

{ #category : 'private' }
CoPCImageCloseSurvey class >> resetPromptState [

	promptInProgress := false.
	promptedForCurrentQuit := false
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> surveyPayloadForRatings: aDictionary [

	^ self surveyPayloadForRatings: aDictionary tasks: #()
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> surveyPayloadForRatings: aDictionary tasks: taskCollection [

	^ Dictionary new
		at: #timestamp put: DateAndTime now asString;
		at: #modelName put: CopilotSettings modelName;
		at: #questions put: self questionLabelsByKey;
		at: #ratings put: aDictionary;
		at: #availableTasks put: self availableTaskLabelsByKey;
		at: #tasks put: taskCollection asArray;
		yourself
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> surveyQuestions [

	^ {
		#overall -> 'Overall, how would you rate Pharo Copilot this session?'.
		#suggestionQuality -> 'How would you rate the quality of the suggestions?'.
		#speed -> 'How would you rate Copilot response speed?'.
		#usefulness -> 'How useful was Copilot for your coding this session?'
	}
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> taskChoices [

	^ {
		#codeCompletion -> 'Writing code with completions'.
		#debugging -> 'Debugging or fixing errors'.
		#refactoring -> 'Refactoring existing code'.
		#tests -> 'Writing or updating tests'.
		#codeReview -> 'Reviewing or understanding code'.
		#documentation -> 'Writing comments or documentation'.
		#setup -> 'Configuring Copilot or models'.
		#learning -> 'Learning Pharo or APIs'
	}
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> taskLabels [

	^ (self taskChoices collect: [ :task | task value ]) , { 'Done' }
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> taskLabelFor: aSymbol [

	^ self availableTaskLabelsByKey
		at: aSymbol
		ifAbsent: [ aSymbol asString ]
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> taskQuestionTitleFor: selectedTasks [

	| selectedLabels |
	selectedTasks isEmpty ifTrue: [
		^ 'Which tasks did you perform this session? Select one task at a time, then choose Done.' ].

	selectedLabels := String streamContents: [ :stream |
		(selectedTasks collect: [ :task | self taskLabelFor: task ])
			do: [ :label | stream nextPutAll: label ]
			separatedBy: [ stream nextPutAll: ', ' ] ].

	^ 'Which tasks did you perform this session?' , String cr ,
		'Selected: ' , selectedLabels , String cr ,
		'Choose another task, or choose Done.'
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> taskSelectionDoneValue [

	^ #done
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> taskValues [

	^ (self taskChoices collect: [ :task | task key ]) , { self taskSelectionDoneValue }
]

{ #category : 'session management' }
CoPCImageCloseSurvey class >> unregisterSessionHandler [

	| sessionManagerClass manager |
	sessionManagerClass := Smalltalk globals at: #SessionManager ifAbsent: [ ^ false ].
	(sessionManagerClass respondsTo: #default) ifFalse: [ ^ false ].
	manager := sessionManagerClass default.
	(manager respondsTo: #unregisterClassNamed:) ifFalse: [ ^ false ].

	manager unregisterClassNamed: self name.
	^ true
]

{ #category : 'private' }
CoPCImageCloseSurvey class >> uiManager [

	| uiClass |
	uiClass := Smalltalk globals at: #UIManager ifAbsent: [ ^ nil ].
	(uiClass respondsTo: #default) ifFalse: [ ^ nil ].
	^ [ uiClass default ] on: Error do: [ :ex | nil ]
]

{ #category : 'private' }
CoPCImageCloseSurvey class >> validatedRating: anObject [

	| rating |
	anObject ifNil: [ ^ nil ].

	rating := (anObject isNumber)
		ifTrue: [ anObject asInteger ]
		ifFalse: [
			(anObject respondsTo: #asString)
				ifTrue: [ Integer readFrom: anObject asString ifFail: [ nil ] ]
				ifFalse: [ nil ] ].

	rating ifNil: [ ^ nil ].
	^ (self ratingValues includes: rating)
		ifTrue: [ rating ]
		ifFalse: [ nil ]
]

{ #category : 'private' }
CoPCImageCloseSurvey class >> validatedTask: anObject [

	| task |
	anObject ifNil: [ ^ self taskSelectionDoneValue ].
	task := anObject isSymbol
		ifTrue: [ anObject ]
		ifFalse: [
			(anObject respondsTo: #asString)
				ifTrue: [ anObject asString asSymbol ]
				ifFalse: [ self taskSelectionDoneValue ] ].

	^ (self taskValues includes: task)
		ifTrue: [ task ]
		ifFalse: [ self taskSelectionDoneValue ]
]
