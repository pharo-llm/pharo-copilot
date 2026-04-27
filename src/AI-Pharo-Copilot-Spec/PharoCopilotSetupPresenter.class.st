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
		'privacyConsentCheckbox',
		'progressBar',
		'downloadProcess'
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

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> deferUI: aBlock [

	| ui |
	ui := [ UIManager default ] on: Error do: [ nil ].

	(ui notNil and: [ ui respondsTo: #defer: ]) ifTrue: [
		^ ui defer: aBlock
	].

	^ aBlock value
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

	privacyConsentCheckbox state ifFalse: [ statusLabel label: 'You must accept the privacy policy before continuing.'.
		^ self ].

	CopilotSettings recordPrivacyPolicyUserConsentAccepted: true.

self showDownloadStep.
	self startSetupDownloads
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
		
		
		progressBar := self newProgressBar.
	progressBar fixedPercentage: 0.

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
PharoCopilotSetupPresenter >> showDownloadStep [

	| centeredRow centeredColumn |
	titleLabel label: 'Setting up Pharo-Copilot'.
	descriptionLabel label: 'Checking Ollama, launching it if needed, and downloading required models.'.
	statusLabel label: 'Checking if Ollama is running...'.
	progressBar fixedPercentage: 0.

	centeredRow := SpBoxLayout newLeftToRight
		add: SpNullPresenter new expand: true;
		add: (SpBoxLayout newTopToBottom
			spacing: 12;
			add: progressBar expand: false;
			yourself)
		expand: true;
		add: SpNullPresenter new expand: true;
		yourself.

	centeredColumn := SpBoxLayout newTopToBottom
		add: SpNullPresenter new expand: true;
		add: centeredRow expand: false;
		add: SpNullPresenter new expand: true;
		yourself.

	contentContainer layout: centeredColumn.
	self layout: self defaultLayout
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> showMissingOllamaStep [

	| messageLabel installButton centeredRow centeredColumn |
	titleLabel label: 'Ollama Required'.
	descriptionLabel label: 'Pharo-Copilot needs Ollama to continue.'.
	statusLabel label: 'Setup could not continue without Ollama.'.

	messageLabel := self newLabel
		label: CopilotSettings missingOllamaSetupMessage;
		yourself.

	installButton := self newButton
		label: 'Download Ollama';
		icon: (self iconNamed: #glamorousBrowse);
		action: [ WebBrowser openOn: CopilotSettings ollamaDownloadPageUrl ];
		yourself.

	centeredRow := SpBoxLayout newLeftToRight
		add: SpNullPresenter new expand: true;
		add: (SpBoxLayout newTopToBottom
			spacing: 12;
			add: messageLabel expand: false;
			add: installButton expand: false;
			yourself)
		expand: false;
		add: SpNullPresenter new expand: true;
		yourself.

	centeredColumn := SpBoxLayout newTopToBottom
		add: SpNullPresenter new expand: true;
		add: centeredRow expand: false;
		add: SpNullPresenter new expand: true;
		yourself.

	contentContainer layout: centeredColumn.
	self layout: self defaultLayout
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

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> startSetupDownloads [

	downloadProcess := [
		| response missingModels failedModels |

		self deferUI: [ statusLabel label: 'Checking if Ollama is running...' ].
		response := CopilotSettings listModelsForSetupAfterLaunchingOllamaIfNeeded.
		response ifNil: [
			^ self deferUI: [
				statusLabel label: 'Cannot use this tool without downloading Ollama.'.
				self showMissingOllamaStep ] ].

		self deferUI: [ statusLabel label: 'Ollama is running. Checking setup models...' ].
		missingModels := CopilotSettings missingSetupModelNamesFrom: response.
		missingModels isEmpty ifTrue: [
			[ CoPCModelRegistry refresh ] on: Error do: [ :ignored | ].
			^ self deferUI: [
				progressBar fixedPercentage: 100.
				statusLabel label: 'Setup completed. All setup models are already installed.'.
				self window close ] ].

		failedModels := OrderedCollection new.
		missingModels doWithIndex: [ :modelName :index |
			self deferUI: [
				statusLabel label:
					('Downloading {1} ({2}/{3})'
						format: { modelName. index. missingModels size })
			].

			((CopilotSettings installModelNamedForSetup: modelName)
				and: [ CopilotSettings refreshModelsAfterInstallOf: modelName usingInitialResponse: response ])
				ifFalse: [ failedModels add: modelName ].

			self deferUI: [
				progressBar fixedPercentage: ((index / missingModels size) * 100) rounded
			]
		].

		[ CoPCModelRegistry refresh ] on: Error do: [ :ignored | ].

		self deferUI: [
			failedModels isEmpty
				ifTrue: [
					statusLabel label: 'Setup completed. All setup models are available.'.
					self window close ]
				ifFalse: [
					statusLabel label:
						('Some models failed to download ({1}). Please check your internet connection and Ollama logs.'
							format: { failedModels size }) ]
		]
	] forkAt: Processor userBackgroundPriority named: 'Pharo Copilot setup download'
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
