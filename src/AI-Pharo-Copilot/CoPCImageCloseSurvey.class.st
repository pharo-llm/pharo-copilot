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
CoPCImageCloseSurvey class >> askTaskUsing: uiManager [

	| task |
	uiManager ifNil: [ ^ nil ].
	(uiManager respondsTo: #chooseFrom:values:title:) ifFalse: [ ^ nil ].

	task := uiManager
		chooseFrom: self taskLabels
		values: self taskValues
		title: self taskQuestionTitle.

	^ self validatedTask: task
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> askUserExperienceUsing: uiManager [

	| experience |
	uiManager ifNil: [ ^ nil ].
	(uiManager respondsTo: #chooseFrom:values:title:) ifFalse: [ ^ nil ].

	experience := uiManager
		chooseFrom: self userExperienceLabels
		values: self userExperienceValues
		title: self userExperienceQuestionTitle.

	^ self validatedUserExperience: experience
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
CoPCImageCloseSurvey class >> availableUserExperienceLabelsByValue [

	| labels |
	labels := Dictionary new.
	self userExperienceChoices do: [ :choice |
		labels at: choice key asString put: choice value ].
	^ labels
]

{ #category : 'session management' }
CoPCImageCloseSurvey class >> archiveCurrentSessionAfterPromptUsing: uiManager [

	CoPharoCopilotLogger loggingEnabled ifFalse: [ ^ nil ].

	(self shouldShowArchiveProgressWindowUsing: uiManager) ifFalse: [
		^ CoPharoCopilotLogger archiveCurrentSession ].

	^ [
		CoPCSessionArchiveProgressPresenter openForCurrentSessionAndWait
	] on: Error do: [ :ex |
		self logSurveyError: ex.
		CoPharoCopilotLogger archiveCurrentSession ]
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
CoPCImageCloseSurvey class >> collectUserProfileUsing: uiManager [

	| experience profile |
	profile := Dictionary new.
	experience := self askUserExperienceUsing: uiManager.
	experience ifNotNil: [ profile at: #experienceYears put: experience ].
	^ profile
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> collectTasksUsing: uiManager [

	| task |
	task := self askTaskUsing: uiManager.
	^ task
		ifNil: [ #() ]
		ifNotNil: [ { task } ]
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

	| ratings tasks userProfile |
	ratings := self collectRatingsUsing: uiManager.
	ratings ifNil: [ ^ nil ].
	tasks := self collectTasksUsing: uiManager.
	userProfile := self collectUserProfileUsing: uiManager.
	self recordRatings: ratings tasks: tasks userProfile: userProfile.
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

	promptedForCurrentQuit := true.
	promptInProgress := true.
	[
		[
			^ self promptAndRecordUsing: uiManager
		] on: Error do: [ :ex |
			self logSurveyError: ex.
			^ nil ]
	] ensure: [
		self archiveCurrentSessionAfterPromptUsing: uiManager.
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

	self
		recordRatings: ratingsDictionary
		tasks: taskCollection
		userProfile: Dictionary new
]

{ #category : 'logging' }
CoPCImageCloseSurvey class >> recordRatings: ratingsDictionary tasks: taskCollection userProfile: userProfileDictionary [

	CoPharoCopilotLogger loggingEnabled ifFalse: [ ^ self ].
	CoPharoCopilotLogger
		appendEvaluationEvent: 'image-close-survey'
		data: (self
			surveyPayloadForRatings: ratingsDictionary
			tasks: taskCollection
			userProfile: userProfileDictionary)
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
	promptedForCurrentQuit = true ifTrue: [
		promptedForCurrentQuit := false.
		^ false ].
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

	[
		((self shouldPromptForImageQuitting: isImageQuitting) and: [ promptInProgress ~= true ]) ifTrue: [
			promptedForCurrentQuit := true.
			promptInProgress := true.
			[
				self promptAndRecordUsing: self uiManager
			] on: Error do: [ :ex |
				self logSurveyError: ex ] ]
	] ensure: [
		isImageQuitting ifTrue: [
			self archiveCurrentSessionAfterPromptUsing: self uiManager ].
		promptInProgress := false ]
]

{ #category : 'session management' }
CoPCImageCloseSurvey class >> shouldShowArchiveProgressWindowUsing: uiManager [

	| presenterClass |
	uiManager ifNil: [ ^ false ].
	uiManager class name = #NonInteractiveUIManager ifTrue: [ ^ false ].
	(uiManager respondsTo: #defer:) ifFalse: [ ^ false ].

	presenterClass := Smalltalk globals
		at: #CoPCSessionArchiveProgressPresenter
		ifAbsent: [ nil ].
	^ presenterClass notNil
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

	^ self
		surveyPayloadForRatings: aDictionary
		tasks: taskCollection
		userProfile: Dictionary new
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> surveyPayloadForRatings: aDictionary tasks: taskCollection userProfile: userProfileDictionary [

	^ Dictionary new
		at: #userId put: CoPharoCopilotLogger userId;
		at: #sessionId put: CoPharoCopilotLogger currentSessionId;
		at: #timestamp put: DateAndTime now asString;
		at: #modelName put: CopilotSettings modelName;
		at: #questions put: self questionLabelsByKey;
		at: #ratings put: aDictionary;
		at: #availableTasks put: self availableTaskLabelsByKey;
		at: #tasks put: taskCollection asArray;
		at: #availableUserExperience put: self availableUserExperienceLabelsByValue;
		at: #userProfile put: (userProfileDictionary ifNil: [ Dictionary new ]);
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

	^ self taskChoices collect: [ :task | task value ]
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> taskLabelFor: aSymbol [

	^ self availableTaskLabelsByKey
		at: aSymbol
		ifAbsent: [ aSymbol asString ]
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> taskQuestionTitle [

	^ 'Which task did you perform this session?'
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> taskValues [

	^ self taskChoices collect: [ :task | task key ]
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> userExperienceChoices [

	^ {
		0 -> 'Less than 2 years'.
		2 -> 'Between 2 and 5 years'.
		5 -> 'Between 5 and 10 years'.
		10 -> 'More than 10 years'
	}
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> userExperienceLabels [

	^ self userExperienceChoices collect: [ :choice | choice value ]
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> userExperienceQuestionTitle [

	^ 'How many years of programming experience do you have?'
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> userExperienceValues [

	^ self userExperienceChoices collect: [ :choice | choice key ]
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
	anObject ifNil: [ ^ nil ].
	task := anObject isSymbol
		ifTrue: [ anObject ]
		ifFalse: [
			(anObject respondsTo: #asString)
				ifTrue: [ anObject asString asSymbol ]
				ifFalse: [ nil ] ].

	^ (self taskValues includes: task)
		ifTrue: [ task ]
		ifFalse: [ nil ]
]

{ #category : 'private' }
CoPCImageCloseSurvey class >> validatedUserExperience: anObject [

	| experience |
	anObject ifNil: [ ^ nil ].

	experience := (anObject isNumber)
		ifTrue: [ anObject asInteger ]
		ifFalse: [
			(anObject respondsTo: #asString)
				ifTrue: [ Integer readFrom: anObject asString ifFail: [ nil ] ]
				ifFalse: [ nil ] ].

	experience ifNil: [ ^ nil ].
	^ (self userExperienceValues includes: experience)
		ifTrue: [ experience ]
		ifFalse: [ nil ]
]
