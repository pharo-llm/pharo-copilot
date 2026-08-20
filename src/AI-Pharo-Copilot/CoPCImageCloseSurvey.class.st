"
I ask a short feedback form when the Pharo image is about to quit.
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
CoPCImageCloseSurvey class >> askOptionalCommentUsing: uiManager [

	| comment |
	uiManager ifNil: [ ^ nil ].
	(uiManager respondsTo: #multiLineRequest:initialAnswer:answerHeight:) ifTrue: [
		comment := uiManager
			multiLineRequest: self optionalCommentQuestionTitle
			initialAnswer: ''
			answerHeight: self optionalCommentAnswerHeight.
		^ self validatedOptionalComment: comment ].
	(uiManager respondsTo: #request:initialAnswer:title:) ifFalse: [ ^ nil ].

	comment := uiManager
		request: self optionalCommentQuestionTitle
		initialAnswer: ''
		title: self optionalCommentWindowTitle.

	^ self validatedOptionalComment: comment
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
CoPCImageCloseSurvey class >> askSurveyFormUsing: uiManager [

	| presenterClass |
	uiManager ifNil: [ ^ nil ].

	(uiManager respondsTo: #imageCloseSurveyFormWithSpec:) ifTrue: [
		^ uiManager imageCloseSurveyFormWithSpec: self surveyFormSpec ].

	presenterClass := self singleFormPresenterClass.
	presenterClass ifNil: [
		^ self collectSurveyResponseSequentiallyUsing: uiManager ].

	^ [
		presenterClass openAndWait
	] on: Error do: [ :ex |
		self logSurveyError: ex.
		self collectSurveyResponseSequentiallyUsing: uiManager ]
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

{ #category : 'survey' }
CoPCImageCloseSurvey class >> collectSurveyResponseSequentiallyUsing: uiManager [

	| ratings tasks userProfile feedbackComment |
	ratings := self collectRatingsUsing: uiManager.
	ratings ifNil: [ ^ nil ].
	tasks := self collectTasksUsing: uiManager.
	userProfile := self collectUserProfileUsing: uiManager.
	feedbackComment := self askOptionalCommentUsing: uiManager.

	^ Dictionary new
		at: #ratings put: ratings;
		at: #tasks put: tasks;
		at: #userProfile put: userProfile;
		at: #feedbackComment put: feedbackComment;
		yourself
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> collectSurveyResponseUsing: uiManager [

	^ self validatedSurveyResponse: (self askSurveyFormUsing: uiManager)
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

	| response ratings tasks userProfile feedbackComment |
	response := self collectSurveyResponseUsing: uiManager.
	response ifNil: [ ^ nil ].
	ratings := response at: #ratings.
	tasks := response at: #tasks.
	userProfile := response at: #userProfile.
	feedbackComment := response at: #feedbackComment.
	self
		recordRatings: ratings
		tasks: tasks
		userProfile: userProfile
		feedbackComment: feedbackComment.
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
CoPCImageCloseSurvey class >> requiredQuestionTitle: aString [

	^ aString , ' *'
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> optionalCommentAnswerHeight [

	^ 180
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> optionalCommentFormTitle [

	^ 'Additional feedback (optional)'
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> optionalCommentQuestionTitle [

	^ 'Do you have any thoughts or feedback to share, positive or negative? (Optional - you can leave this blank and continue.)'
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> optionalCommentWindowTitle [

	^ 'Pharo Copilot feedback'
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
CoPCImageCloseSurvey class >> ratingHighAnchorLabel [

	^ 'Extremely useful'
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> ratingLowAnchorLabel [

	^ 'Not useful at all'
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

	self
		recordRatings: ratingsDictionary
		tasks: taskCollection
		userProfile: userProfileDictionary
		feedbackComment: nil
]

{ #category : 'logging' }
CoPCImageCloseSurvey class >> recordRatings: ratingsDictionary tasks: taskCollection userProfile: userProfileDictionary feedbackComment: feedbackComment [

	CoPharoCopilotLogger loggingEnabled ifFalse: [ ^ self ].
	CoPharoCopilotLogger
		appendEvaluationEvent: 'image-close-survey'
		data: (self
			surveyPayloadForRatings: ratingsDictionary
			tasks: taskCollection
			userProfile: userProfileDictionary
			feedbackComment: feedbackComment)
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

{ #category : 'private' }
CoPCImageCloseSurvey class >> singleFormPresenterClass [

	^ Smalltalk globals
		at: #CoPCImageCloseSurveyPresenter
		ifAbsent: [ nil ]
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

	^ self
		surveyPayloadForRatings: aDictionary
		tasks: taskCollection
		userProfile: userProfileDictionary
		feedbackComment: nil
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> surveyPayloadForRatings: aDictionary tasks: taskCollection userProfile: userProfileDictionary feedbackComment: feedbackComment [

	| payload |
	payload := Dictionary new
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
		yourself.
	feedbackComment ifNotNil: [
		payload at: #feedbackComment put: feedbackComment ].
	^ payload
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> surveyFormDescription [

	^ 'Questions marked * are required. Comment is optional.'
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> surveyFormSpec [

	^ Dictionary new
		at: #title put: self surveyFormWindowTitle;
		at: #heading put: self surveyFormTitle;
		at: #description put: self surveyFormDescription;
		at: #questions put: self surveyQuestions;
		at: #ratingValues put: self ratingValues;
		at: #ratingLowLabel put: self ratingLowAnchorLabel;
		at: #ratingHighLabel put: self ratingHighAnchorLabel;
		at: #taskQuestion put: (self requiredQuestionTitle: self taskQuestionTitle);
		at: #taskChoices put: self taskChoices;
		at: #experienceQuestion put: (self requiredQuestionTitle: self userExperienceQuestionTitle);
		at: #experienceChoices put: self userExperienceChoices;
		at: #commentQuestion put: self optionalCommentFormTitle;
		at: #requiredMessage put: self surveyRequiredMessage;
		yourself
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> surveyFormTitle [

	^ 'Pharo-Copilot feedback'
]

{ #category : 'survey' }
CoPCImageCloseSurvey class >> surveyFormWindowTitle [

	^ 'Pharo-Copilot Feedback'
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
CoPCImageCloseSurvey class >> surveyRequiredMessage [

	^ 'Please answer every question marked with * before submitting.'
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

{ #category : 'private' }
CoPCImageCloseSurvey class >> taskValueFromSurveyResponse: aDictionary [

	| task tasks |
	task := aDictionary at: #task ifAbsent: [ nil ].
	task ifNotNil: [ ^ task ].

	tasks := aDictionary at: #tasks ifAbsent: [ #() ].
	(tasks respondsTo: #isEmpty) ifFalse: [ ^ nil ].
	tasks isEmpty ifTrue: [ ^ nil ].
	^ tasks first
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

{ #category : 'private' }
CoPCImageCloseSurvey class >> userExperienceValueFromSurveyResponse: aDictionary [

	| experience userProfile |
	experience := aDictionary at: #experienceYears ifAbsent: [ nil ].
	experience ifNotNil: [ ^ experience ].

	userProfile := aDictionary at: #userProfile ifAbsent: [ nil ].
	(userProfile respondsTo: #at:ifAbsent:) ifFalse: [ ^ nil ].
	^ userProfile at: #experienceYears ifAbsent: [ nil ]
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
CoPCImageCloseSurvey class >> validatedOptionalComment: anObject [

	anObject ifNil: [ ^ nil ].
	(anObject respondsTo: #asString) ifFalse: [ ^ nil ].
	^ anObject asString
]

{ #category : 'private' }
CoPCImageCloseSurvey class >> validatedSurveyResponse: anObject [

	| ratingsInput ratings rating task experience profile comment |
	anObject ifNil: [ ^ nil ].
	(anObject respondsTo: #at:ifAbsent:) ifFalse: [ ^ nil ].

	ratingsInput := anObject at: #ratings ifAbsent: [ nil ].
	(ratingsInput respondsTo: #at:ifAbsent:) ifFalse: [ ^ nil ].

	ratings := Dictionary new.
	self surveyQuestions do: [ :question |
		rating := self validatedRating:
			(ratingsInput at: question key ifAbsent: [ nil ]).
		rating ifNil: [ ^ nil ].
		ratings at: question key put: rating ].

	task := self validatedTask:
		(self taskValueFromSurveyResponse: anObject).
	task ifNil: [ ^ nil ].

	experience := self validatedUserExperience:
		(self userExperienceValueFromSurveyResponse: anObject).
	experience ifNil: [ ^ nil ].

	profile := Dictionary new
		at: #experienceYears put: experience;
		yourself.
	comment := self validatedOptionalComment:
		(anObject at: #feedbackComment ifAbsent: [ '' ]).

	^ Dictionary new
		at: #ratings put: ratings;
		at: #tasks put: { task };
		at: #userProfile put: profile;
		at: #feedbackComment put: (comment ifNil: [ '' ]);
		yourself
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
