"
I present the image-close survey as a single form.
"
Class {
	#name : 'CoPCImageCloseSurveyPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'titleLabel',
		'descriptionLabel',
		'statusLabel',
		'ratingQuestionLayouts',
		'ratingSelections',
		'taskLabel',
		'taskDropList',
		'experienceLabel',
		'experienceDropList',
		'commentLabel',
		'commentText',
		'submitButton',
		'cancelButton',
		'result',
		'done'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'instance creation' }
CoPCImageCloseSurveyPresenter class >> openAndWait [

	| presenter |
	presenter := self new.
	presenter open.
	self runUIUntil: [ presenter isDone ].
	^ presenter result
]

{ #category : 'private' }
CoPCImageCloseSurveyPresenter class >> runOneUICycle [

	| worldMorphClass |
	worldMorphClass := Smalltalk globals
		at: #WorldMorph
		ifAbsent: [ nil ].

	(worldMorphClass notNil and: [ worldMorphClass respondsTo: #doOneCycle ])
		ifTrue: [
			[ worldMorphClass doOneCycle ] on: Error do: [ :ignored | ] ]
]

{ #category : 'private' }
CoPCImageCloseSurveyPresenter class >> runUIUntil: conditionBlock [

	[ conditionBlock value ] whileFalse: [
		self runOneUICycle.
		(Delay forMilliseconds: 50) wait ]
]

{ #category : 'actions' }
CoPCImageCloseSurveyPresenter >> cancel [

	result := nil.
	done := true.
	self window ifNotNil: [ :windowPresenter |
		windowPresenter close ]
]

{ #category : 'layout' }
CoPCImageCloseSurveyPresenter >> defaultLayout [

	| layout taskLayout experienceLayout commentLayout buttonLayout |
	layout := SpBoxLayout newTopToBottom
		spacing: 12;
		borderWidth: 18;
		add: titleLabel expand: false;
		add: descriptionLabel expand: false;
		yourself.

	ratingQuestionLayouts do: [ :each |
		layout add: each expand: false ].

	taskLayout := SpBoxLayout newLeftToRight
		spacing: 8;
		add: taskLabel width: 280;
		add: taskDropList expand: true;
		yourself.

	experienceLayout := SpBoxLayout newLeftToRight
		spacing: 8;
		add: experienceLabel width: 280;
		add: experienceDropList expand: true;
		yourself.

	commentLayout := SpBoxLayout newTopToBottom
		spacing: 4;
		add: commentLabel expand: false;
		add: commentText expand: true;
		yourself.

	buttonLayout := SpBoxLayout newLeftToRight
		spacing: 8;
		add: statusLabel expand: true;
		add: cancelButton expand: false;
		add: submitButton expand: false;
		yourself.

	^ layout
		add: taskLayout expand: false;
		add: experienceLayout expand: false;
		add: commentLayout expand: true;
		add: buttonLayout expand: false;
		yourself
]

{ #category : 'private' }
CoPCImageCloseSurveyPresenter >> formResult [

	| ratings profile task experience |
	ratings := Dictionary new.
	CoPCImageCloseSurvey surveyQuestions do: [ :question |
		ratings
			at: question key
			put: (ratingSelections at: question key) ].

	task := self selectedTask.
	experience := self selectedExperience.
	profile := Dictionary new
		at: #experienceYears put: experience;
		yourself.

	^ Dictionary new
		at: #ratings put: ratings;
		at: #task put: task;
		at: #tasks put: { task };
		at: #experienceYears put: experience;
		at: #userProfile put: profile;
		at: #feedbackComment put: self optionalCommentText;
		yourself
]

{ #category : 'initialization' }
CoPCImageCloseSurveyPresenter >> initializePresenters [

	super initializePresenters.

	ratingSelections := Dictionary new.
	ratingQuestionLayouts := OrderedCollection new.
	done := false.
	result := nil.

	titleLabel := self newLabel
		label: CoPCImageCloseSurvey surveyFormTitle;
		yourself.

	descriptionLabel := self newLabel
		label: CoPCImageCloseSurvey surveyFormDescription;
		yourself.

	statusLabel := self newLabel
		label: '';
		yourself.

	CoPCImageCloseSurvey surveyQuestions do: [ :question |
		ratingQuestionLayouts add:
			(self newRatingQuestionLayoutFor: question) ].

	taskLabel := self newLabel
		label: (CoPCImageCloseSurvey requiredQuestionTitle:
			CoPCImageCloseSurvey taskQuestionTitle);
		yourself.

	taskDropList := self newDropList
		items: CoPCImageCloseSurvey taskChoices;
		display: [ :association | association value ];
		whenSelectedItemChangedDo: [ :ignored |
			self updateSubmitButtonState ];
		yourself.
	taskDropList resetSelection.

	experienceLabel := self newLabel
		label: (CoPCImageCloseSurvey requiredQuestionTitle:
			CoPCImageCloseSurvey userExperienceQuestionTitle);
		yourself.

	experienceDropList := self newDropList
		items: CoPCImageCloseSurvey userExperienceChoices;
		display: [ :association | association value ];
		whenSelectedItemChangedDo: [ :ignored |
			self updateSubmitButtonState ];
		yourself.
	experienceDropList resetSelection.

	commentLabel := self newLabel
		label: CoPCImageCloseSurvey optionalCommentFormTitle;
		yourself.

	commentText := self newText
		text: '';
		beEditable;
		yourself.

	submitButton := self newButton
		label: 'Submit';
		action: [ self submit ];
		enabled: false;
		yourself.

	cancelButton := self newButton
		label: 'Cancel';
		action: [ self cancel ];
		yourself
]

{ #category : 'initialization' }
CoPCImageCloseSurveyPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.

	aWindowPresenter
		title: CoPCImageCloseSurvey surveyFormWindowTitle;
		initialExtent: 1000 @ 780;
		centered.

	(aWindowPresenter respondsTo: #whenClosedDo:) ifTrue: [
		aWindowPresenter whenClosedDo: [
			done ifFalse: [
				result := nil.
				done := true ] ] ]
]

{ #category : 'testing' }
CoPCImageCloseSurveyPresenter >> isComplete [

	^ self ratingsAreComplete
		and: [ self selectedTask notNil
		and: [ self selectedExperience notNil ] ]
]

{ #category : 'testing' }
CoPCImageCloseSurveyPresenter >> isDone [

	^ done = true
]

{ #category : 'layout' }
CoPCImageCloseSurveyPresenter >> newRatingQuestionLayoutFor: question [

	| questionLabel scaleLayout buttons |
	ratingSelections at: question key put: nil.

	questionLabel := self newLabel
		label: (CoPCImageCloseSurvey requiredQuestionTitle: question value);
		yourself.

	buttons := OrderedCollection new.
	scaleLayout := SpBoxLayout newLeftToRight
		spacing: 14;
		vAlignCenter;
		add: (self newLabel
			label: CoPCImageCloseSurvey ratingLowAnchorLabel;
			yourself) width: 150;
		yourself.

	CoPCImageCloseSurvey ratingValues do: [ :rating |
		| tile tilePresenter |
		tile := CoPCRatingTileMorph
			value: rating
			action: [ :selectedTile |
				self
					selectRating: rating
					forQuestion: question key.
				buttons do: [ :each | each selected: false ].
				selectedTile selected: true ].
		tilePresenter := self newMorph
			morph: tile;
			yourself.
		buttons add: tile.
		scaleLayout add: tilePresenter width: 104 ].

	scaleLayout add: (self newLabel
		label: CoPCImageCloseSurvey ratingHighAnchorLabel;
		yourself) width: 170.

	^ SpBoxLayout newTopToBottom
		spacing: 8;
		add: questionLabel expand: false;
		add: scaleLayout height: 68;
		yourself
]

{ #category : 'private' }
CoPCImageCloseSurveyPresenter >> optionalCommentText [

	| text |
	text := commentText text.
	^ text ifNil: [ '' ] ifNotNil: [ text asString ]
]

{ #category : 'testing' }
CoPCImageCloseSurveyPresenter >> ratingsAreComplete [

	^ CoPCImageCloseSurvey surveyQuestions allSatisfy: [ :question |
		(ratingSelections at: question key ifAbsent: [ nil ]) notNil ]
]

{ #category : 'accessing' }
CoPCImageCloseSurveyPresenter >> result [

	^ result
]

{ #category : 'private' }
CoPCImageCloseSurveyPresenter >> selectRating: rating forQuestion: questionKey [

	ratingSelections at: questionKey put: rating.
	self updateSubmitButtonState
]

{ #category : 'private' }
CoPCImageCloseSurveyPresenter >> selectedExperience [

	| selected |
	selected := experienceDropList selectedItem.
	selected ifNil: [ ^ nil ].
	^ selected key
]

{ #category : 'private' }
CoPCImageCloseSurveyPresenter >> selectedTask [

	| selected |
	selected := taskDropList selectedItem.
	selected ifNil: [ ^ nil ].
	^ selected key
]

{ #category : 'actions' }
CoPCImageCloseSurveyPresenter >> submit [

	self isComplete ifFalse: [
		statusLabel label: CoPCImageCloseSurvey surveyRequiredMessage.
		self updateSubmitButtonState.
		^ self ].

	result := self formResult.
	done := true.
	self window ifNotNil: [ :windowPresenter |
		windowPresenter close ]
]

{ #category : 'private' }
CoPCImageCloseSurveyPresenter >> updateSubmitButtonState [

	submitButton ifNil: [ ^ self ].
	submitButton enabled: self isComplete.
	self isComplete ifTrue: [
		statusLabel label: '' ]
]
