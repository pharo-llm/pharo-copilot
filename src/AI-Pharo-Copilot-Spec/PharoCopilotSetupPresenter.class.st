"
I'm a setup presenter for the Pharo-Copilot 
"
Class {
	#name : 'PharoCopilotSetupPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'titleLabel',
		'descriptionLabel',
		'statusLabel',
		'contentContainer',
		'privacyConsentCheckbox'
	],
	#category : 'AI-Pharo-Copilot-Spec',
	#package : 'AI-Pharo-Copilot-Spec'
}

{ #category : 'instance creation' }
PharoCopilotSetupPresenter class >> open [
	"Open the setup wizard."

	^ self new open
]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> contentContainer [

	^ contentContainer
]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> contentContainer: anObject [

	contentContainer := anObject
]

{ #category : 'layout' }
PharoCopilotSetupPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 16;
		  borderWidth: 20;
		  add: titleLabel expand: false;
		  add: descriptionLabel expand: false;
		  add: contentContainer expand: true;
		  add: statusLabel expand: false;
		  yourself
]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> descriptionLabel [

	^ descriptionLabel
]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> descriptionLabel: anObject [

	descriptionLabel := anObject
]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> handleOk [

	privacyConsentCheckbox state ifFalse: [
		^ self inform: 'You must accept the privacy policy before continuing.' ].

	(CopilotSettings ensureOllamaInstalledBeforeUse) ifFalse: [
		statusLabel label: 'Ollama is required before Pharo-Copilot can be used.'.
		^ self
	].

	CopilotSettings recordPrivacyPolicyUserConsentAccepted: true.
	self window close
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> initializePresenters [

	super initializePresenters.

	titleLabel := self newLabel
		              label: 'Welcome to ChatPharo';
		              yourself.

	descriptionLabel := self newLabel
		                    label: '';
		                    yourself.

	statusLabel := self newLabel
		               label: '';
		               yourself.

	contentContainer := SpPresenter new.

	self showWelcomeStep
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.

	aWindowPresenter
		title: 'Pharo-Copilot Setup';
		initialExtent: 500 @ 400;
		centered.

]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> showWelcomeStep [

	| welcomeContainer privacyLabel privacyDetailLabel termsButton okButton buttonRow |
	titleLabel label: 'Welcome to Pharo-Copilot'.
	descriptionLabel label: 'Your AI code Completion'.
	statusLabel label: ''.

	privacyLabel := self newLabel
		                label: 'Pharo-Copilot is fully private.';
		                yourself.

	privacyDetailLabel := self newLabel
		                      label: 'Your code and interactions stay private.';
		                      yourself.

	privacyConsentCheckbox := self newCheckBox
		                          label: 'I agree with the privacy policy';
		                          state: false;
		                          yourself.

	termsButton := self newButton
		               label: 'Privacy Policy & Terms';
		               icon: (self iconNamed: #glamorousBrowse);
		               action: [ WebBrowser openOn: 'https://pharo-llm.github.io/privacy.html' ];
		               yourself.

	welcomeContainer := SpBoxLayout newTopToBottom
		                    spacing: 16;
		                    add: privacyLabel expand: false;
		                    add: privacyDetailLabel expand: false;
		                    add: termsButton expand: false;
		                    yourself.

	okButton := self newButton
		            label: 'OK';
		            action: [ self handleOk ];
		            yourself.

	buttonRow := SpBoxLayout newHorizontal
		             spacing: 8;
		             add: okButton expand: false;
		             yourself.

	contentContainer layout: (SpBoxLayout newTopToBottom
			 spacing: 12;
			 add: welcomeContainer expand: true;
			 add: privacyConsentCheckbox expand: false;
			 add: buttonRow expand: false;
			 yourself).

	self layout: self defaultLayout
]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> statusLabel [

	^ statusLabel
]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> statusLabel: anObject [

	statusLabel := anObject
]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> titleLabel [

	^ titleLabel
]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> titleLabel: anObject [

	titleLabel := anObject
]
