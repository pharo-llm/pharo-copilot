"
A short, optional image-close feedback prompt with one dropdown.
"
Class {
	#name : 'CoPCImageCloseSurveyPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'titleLabel',
		'descriptionLabel',
		'feedbackDropList',
		'statusLabel',
		'submitButton',
		'skipButton',
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
	worldMorphClass := Smalltalk globals at: #WorldMorph ifAbsent: [ nil ].
	(worldMorphClass notNil and: [ worldMorphClass respondsTo: #doOneCycle ]) ifTrue: [
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
	self window ifNotNil: [ :windowPresenter | windowPresenter close ]
]

{ #category : 'layout' }
CoPCImageCloseSurveyPresenter >> defaultLayout [

	| buttons |
	buttons := SpBoxLayout newLeftToRight
		spacing: 8;
		add: statusLabel expand: true;
		add: skipButton expand: false;
		add: submitButton expand: false;
		yourself.

	^ SpBoxLayout newTopToBottom
		spacing: 12;
		borderWidth: 16;
		add: titleLabel expand: false;
		add: descriptionLabel expand: false;
		add: feedbackDropList expand: false;
		add: buttons expand: false;
		yourself
]

{ #category : 'initialization' }
CoPCImageCloseSurveyPresenter >> initializePresenters [

	super initializePresenters.
	done := false.
	result := nil.

	titleLabel := self newLabel
		label: 'Quick feedback';
		yourself.
	descriptionLabel := self newLabel
		label: 'How was this session? (rating only; no code sent)';
		yourself.
	feedbackDropList := self newDropList
		items: CoPCImageCloseSurvey feedbackChoices;
		display: [ :choice | choice value ];
		whenSelectedItemChangedDo: [ :ignored | self updateSubmitButtonState ];
		yourself.
	feedbackDropList resetSelection.
	statusLabel := self newLabel label: 'Optional — you can skip this.'; yourself.
	submitButton := self newButton
		label: 'Send feedback';
		action: [ self submit ];
		enabled: false;
		yourself.
	skipButton := self newButton
		label: 'Skip';
		action: [ self cancel ];
		yourself
]

{ #category : 'initialization' }
CoPCImageCloseSurveyPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'Pharo-Copilot feedback';
		initialExtent: 480 @ 250;
		centered.
	(aWindowPresenter respondsTo: #whenClosedDo:) ifTrue: [
		aWindowPresenter whenClosedDo: [
			done ifFalse: [ result := nil. done := true ] ] ]
]

{ #category : 'testing' }
CoPCImageCloseSurveyPresenter >> isComplete [

	^ feedbackDropList notNil and: [ feedbackDropList selectedItem notNil ]
]

{ #category : 'testing' }
CoPCImageCloseSurveyPresenter >> isDone [

	^ done = true
]

{ #category : 'accessing' }
CoPCImageCloseSurveyPresenter >> result [

	^ result
]

{ #category : 'actions' }
CoPCImageCloseSurveyPresenter >> submit [

	| selection |
	selection := feedbackDropList selectedItem.
	selection ifNil: [ ^ self ].
	result := Dictionary new
		at: #rating put: selection key;
		at: #feedbackLabel put: selection value;
		yourself.
	done := true.
	self window ifNotNil: [ :windowPresenter | windowPresenter close ]
]

{ #category : 'private' }
CoPCImageCloseSurveyPresenter >> updateSubmitButtonState [

	submitButton ifNotNil: [ submitButton enabled: self isComplete ]
]
