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
		'progressBar',
		'downloadProcess',
		'setupProgress',
		'progressIsIndeterminate',
		'indeterminateProgressStart',
		'indeterminateProgressEnd'
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

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> beginIndeterminateProgressForIndex: index total: totalModels [

	| start end |
	totalModels <= 0 ifTrue: [ ^ self setupProgressPercentage: 0 ].

	start := (((index - 1) asFloat / totalModels) max: 0) min: 1.
	end := ((index asFloat / totalModels) max: start) min: 1.

	indeterminateProgressStart := start.
	indeterminateProgressEnd := end.
	setupProgress ifNil: [ setupProgress := start ].
	progressIsIndeterminate := true
]

{ #category : 'layout' }
PharoCopilotSetupPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 6;
		  borderWidth: 8;
		  add: titleLabel expand: false;
		  add: descriptionLabel height: 60;
		  add: contentContainer expand: true;
		  add: statusLabel height: 48;
		  yourself
]

{ #category : 'layout' }
PharoCopilotSetupPresenter >> consentLayoutWith: buttons [

	^ SpBoxLayout newTopToBottom
		spacing: 12;
		add: buttons expand: false;
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

	self continueSetupAfterConsentDecision
]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> handleResearchTelemetryAccepted [

	CopilotSettings recordResearchTelemetryConsentAccepted: true
]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> handleResearchTelemetryDeclined [

	CopilotSettings recordResearchTelemetryConsentAccepted: false
]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> continueSetupAfterConsentDecision [

	self showDownloadStep.
	statusLabel text: (CopilotSettings remoteEnabled
		ifTrue: [ 'Connecting to your completion server...' ]
		ifFalse: [ CopilotSettings researchTelemetryAccepted
		ifTrue: [ 'Authorizing server connection...' ]
		ifFalse: [ 'Anonymous research telemetry disabled. Continuing local setup.' ] ]).
	self startSetupDownloads
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> initializePresenters [

	super initializePresenters.

	titleLabel := self newLabel
		label: 'Welcome to Pharo-Copilot';
		yourself.

	descriptionLabel := self newText
		beNotEditable;
		beWrapWord;
		text: '';
		yourself.

	statusLabel := self newText
		beNotEditable;
		beWrapWord;
		text: '';
		yourself.

	setupProgress := 0.
	progressIsIndeterminate := false.
	indeterminateProgressStart := 0.
	indeterminateProgressEnd := 1.
	progressBar := self newProgressBar.
	progressBar
		progress: [ self progressBarValue ]
		every: 0.1 second.

	contentContainer := SpPresenter new.

	self showConnectionChoiceStep
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> showConnectionChoiceStep [
	| cloudButton localButton |
	titleLabel label: 'Welcome to Pharo-Copilot'.
	descriptionLabel text: 'Choose where to run your completion model.'.
	statusLabel text: ''.
	cloudButton := self newButton
		label: 'Use cloud (access token required)';
		action: [ self showAccessTokenStep ];
		yourself.
	localButton := self newButton
		label: 'Use local model (no token needed)';
		action: [ self handleLocalModelSelected ];
		yourself.
	contentContainer layout: (SpBoxLayout newTopToBottom
		spacing: 12;
		add: (self newLabel label: 'Cloud: use a token supplied by your administrator.') expand: false;
		add: cloudButton expand: false;
		add: (self newLabel label: 'Local: check Ollama and download missing models.') expand: false;
		add: localButton expand: false;
		yourself).
	self layout: self defaultLayout
]

{ #category : 'actions' }
PharoCopilotSetupPresenter >> handleLocalModelSelected [

	CopilotSettings useLocalModels.
	self showResearchTelemetryConsentChoiceStep
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> showAccessTokenStep [
	| tokenInput connectButton backButton |
	titleLabel label: 'Connect to Pharo-Copilot cloud'.
	descriptionLabel text: 'Cloud access requires a token from your administrator.'.
	statusLabel text: ''.
	tokenInput := self newTextInput.
	connectButton := self newButton
		label: 'Connect';
		action: [
			| configured |
			configured := [
				CopilotSettings
					configureHostedServer: (CopilotSettings remoteEnabled
						ifTrue: [ CopilotSettings host ] ifFalse: [ '193.49.213.153' ])
					accessToken: tokenInput text trimBoth
					model: 'pharo-llm/Qwen2.5-Coder-SFT:q4_K_M'
					secure: (CopilotSettings remoteEnabled
						ifTrue: [ CopilotSettings remoteServerSecure ] ifFalse: [ false ]).
				true
			] on: Error do: [ :error |
				statusLabel text: 'Could not save the token. Check the token and try again.'.
				false ].
			configured ifTrue: [
				tokenInput text: ''.
				self showResearchTelemetryConsentChoiceStep ] ];
		yourself.
	backButton := self newButton
		label: 'Back';
		action: [ self showConnectionChoiceStep ];
		yourself.
	contentContainer layout: (SpBoxLayout newTopToBottom
		spacing: 12;
		add: tokenInput expand: false;
		add: connectButton expand: false;
		add: backButton expand: false;
		yourself).
	self layout: self defaultLayout
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.

	aWindowPresenter
		title: 'Pharo-Copilot Setup';
		initialExtent: 460 @ 340;
		centered.

]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> performSetupDownloads [

	| response missingModels failedModels |

	CopilotSettings remoteEnabled ifTrue: [
		^ self performRemoteSetup ].

	self setupProgressPercentage: 0.
	self deferUI: [ statusLabel text: '' ].

	response := CopilotSettings listModelsForSetupAfterLaunchingOllamaIfNeeded.

	response ifNil: [
		self setupProgressPercentage: 0.
		^ self deferUI: [
			statusLabel text: 'Cannot continue. Ollama is required.'.
			self showMissingOllamaStep
		]
	].

	missingModels := CopilotSettings missingSetupModelNamesFrom: response.

	missingModels isEmpty ifTrue: [
		[ CoPCModelRegistry refresh ] on: Error do: [ :ignored | ].
		CopilotSettings ensureDefaultCompletionModelSelected.
		CopilotSettings copilotEnabled: true.
		CopilotSettings installCompletionEngineIfAvailable.
		self setupProgressPercentage: 100.
		^ self deferUI: [
			statusLabel text: 'OKAY! Pharo-Copilot setup is complete.'.
			CopilotSettings notifyUser: 'OKAY! Pharo-Copilot setup is complete.'.
			self window ifNotNil: [ :window | window close ]
		]
	].

	self deferUI: [
		self
			beginIndeterminateProgressForIndex: 1
			total: missingModels size.
		descriptionLabel text:
			('Downloading {1} model(s):'
				format: { missingModels size }).
		statusLabel text:
			('Downloading 1/{1}: {2}'
				format: { missingModels size. missingModels first })
	].

	failedModels := OrderedCollection new.

	missingModels doWithIndex: [ :modelName :index |

		| installed verified |
		self deferUI: [
			self
				beginIndeterminateProgressForIndex: index
				total: missingModels size.
			statusLabel text:
				(self
					setupDownloadingMessageFor: modelName
					index: index
					total: missingModels size)
		].

		installed := CopilotSettings
			installModelNamedForSetup: modelName
			progress: [ :event |
				self
					showPullEvent: event
					forModel: modelName
					index: index
					total: missingModels size ].

		verified := installed and: [
				CopilotSettings
					refreshModelsAfterInstallOf: modelName
					usingInitialResponse: response ].

		verified ifFalse: [ failedModels add: modelName ].

		self deferUI: [
			self setupProgressPercentage: ((index / missingModels size) * 100) rounded.
			statusLabel text:
				(verified
					ifTrue: [
						self
							setupDownloadedMessageFor: modelName
							index: index
							total: missingModels size
							nextModel: (missingModels at: index + 1 ifAbsent: [ nil ])
							verified: verified ]
					ifFalse: [
						installed
							ifTrue: [
								self
									setupNotVisibleMessageFor: modelName
									index: index
									total: missingModels size
									nextModel: (missingModels at: index + 1 ifAbsent: [ nil ]) ]
							ifFalse: [
								self
									setupFailedMessageFor: modelName
									index: index
									total: missingModels size
									nextModel: (missingModels at: index + 1 ifAbsent: [ nil ]) ] ])
		]
	].

	[ CoPCModelRegistry refresh ] on: Error do: [ :ignored | ].

	self deferUI: [
		failedModels isEmpty
			ifTrue: [
				CopilotSettings ensureDefaultCompletionModelSelected.
				CopilotSettings copilotEnabled: true.
				CopilotSettings installCompletionEngineIfAvailable.
				self setupProgressPercentage: 100.
				statusLabel text: 'Pharo-Copilot setup is complete.'.
				CopilotSettings notifyUser: 'Pharo-Copilot setup is complete.'.
				self window ifNotNil: [ :window | window close ] ]
			ifFalse: [
				statusLabel text:
					('Setup finished with {1}/{2} model(s) not available in Ollama. Check the message above, Ollama logs, and ''ollama list''.'
						format: { failedModels size. missingModels size }) ]
	]
]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> performSetupPipeline [

	| authorized |
	self setupProgressPercentage: 0.

	"For cloud mode, connect first and ask about retained research data only after
	the hosted completion endpoint has been verified."
	CopilotSettings remoteEnabled ifTrue: [
		self deferUI: [ statusLabel text: 'Connecting to your completion server...' ].
		^ self performSetupDownloads ].

	CopilotSettings researchTelemetryAccepted ifFalse: [
		self deferUI: [ statusLabel text: (CopilotSettings remoteEnabled
			ifTrue: [ 'Connecting to your completion server...' ]
			ifFalse: [ 'Anonymous research telemetry disabled. Continuing local setup.' ]) ].
		(Delay forMilliseconds: 500) wait.
		^ self performSetupDownloads ].

	self deferUI: [ statusLabel text: 'Authorizing server connection...' ].

	authorized := [
		CoPCSessionArchiveUploader ensureInternetUploadUrl.
		CoPCSessionArchiveUploader authorizeConnection
	] on: Error do: [ :ex |
		CoPharoCopilotLogger
			logBackEndEvent: 'Server connection authorization failed'
			details: (Dictionary new
				at: #errorClass put: ex class name;
				at: #error put: ex description;
				yourself).
		false ].

	authorized ifFalse: [
		self deferUI: [
			statusLabel text: 'Connection denied. Continuing setup.'.
			CopilotSettings notifyUser: 'Connection denied. Continuing setup.' ].
		(Delay forMilliseconds: 500) wait.
		^ self performSetupDownloads ].

	self deferUI: [
		statusLabel text: 'Connection authorized. Continuing setup.'.
		CopilotSettings notifyUser: 'Connection authorized. Continuing setup.' ].
	(Delay forMilliseconds: 500) wait.
	self performSetupDownloads
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> progressBarValue [

	progressIsIndeterminate ifTrue: [
		setupProgress := CoPCModelDownloadProgressPresenter
			indeterminateProgressFrom: setupProgress
			start: indeterminateProgressStart
			end: indeterminateProgressEnd
			step: 0.004 ].

	^ setupProgress ifNil: [ 0 ]
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> setupDownloadedMessageFor: modelName index: index total: totalModels nextModel: nextModel verified: verified [

	| message |
	message := 'Done ', index asString, '/', totalModels asString, ': ', modelName.
	verified ifFalse: [
		message := message , String cr , 'Ollama list will refresh shortly.' ].
	nextModel ifNotNil: [
		message := message , String cr , 'Downloading ', (index + 1) asString, '/', totalModels asString, ': ', nextModel ].
	^ message
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> setupDownloadingMessageFor: modelName index: index total: totalModels [

	^ 'Downloading ', index asString, '/', totalModels asString, ': ', modelName
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> setupFailedMessageFor: modelName index: index total: totalModels nextModel: nextModel [

	| message |
	message := 'Failed ', index asString, '/', totalModels asString, ': ', modelName.
	nextModel ifNotNil: [
		message := message , String cr , 'Downloading ', (index + 1) asString, '/', totalModels asString, ': ', nextModel ].
	^ message
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> setupNotVisibleMessageFor: modelName index: index total: totalModels nextModel: nextModel [
	"The pull finished but Ollama did not confirm the model through list/show. This
	usually means another Ollama instance with a different model store answers on the
	configured host and port."

	| message |
	message := 'Done ', index asString, '/', totalModels asString, ': ', modelName,
		String cr,
		'but Ollama did not confirm it. Run ''ollama list'' in a terminal to verify;',
		String cr,
		'another Ollama instance may be serving ',
		CopilotSettings host asString, ':', CopilotSettings port asString, '.'.
	nextModel ifNotNil: [
		message := message , String cr , 'Downloading ', (index + 1) asString, '/', totalModels asString, ': ', nextModel ].
	^ message
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> setupProgressPercentage: aNumber [

	| bounded |
	progressIsIndeterminate := false.
	bounded := (aNumber ifNil: [ 0 ]) max: 0.
	bounded := bounded min: 100.
	setupProgress := bounded / 100.0
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> showDownloadStep [

	titleLabel label: 'Setting up Pharo-Copilot'.
	descriptionLabel text: (CopilotSettings remoteEnabled
		ifTrue: [ 'Connecting to your completion server...' ]
		ifFalse: [ 'Checking Ollama and installed local models...' ]).
	statusLabel text: ''.

	self setupProgressPercentage: 0.

	contentContainer layout: (SpBoxLayout newTopToBottom
		spacing: 12;
		add: progressBar expand: false;
		add: SpNullPresenter new expand: true;
		yourself).

	self layout: self defaultLayout
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> showMissingOllamaStep [

	| messageLabel installButton |
	titleLabel label: 'Ollama Required'.
	descriptionLabel text: 'Pharo-Copilot needs Ollama to continue.'.
	statusLabel text: 'Setup could not continue without Ollama.'.

	messageLabel := self newText
		beNotEditable;
		beWrapWord;
		text: CopilotSettings missingOllamaSetupMessage;
		yourself.

	installButton := self newButton
		label: 'Download Ollama';
		action: [ WebBrowser openOn: CopilotSettings ollamaDownloadPageUrl ];
		yourself.

	contentContainer layout: (SpBoxLayout newTopToBottom
		spacing: 12;
		add: messageLabel expand: true;
		add: installButton expand: false;
		yourself).
	self layout: self defaultLayout
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> showPullEvent: event forModel: modelName index: index total: totalModels [

	| status message percent overall |
	status := CoPCModelDownloadProgressPresenter pullEventStatusFrom: event.
	percent := CoPCModelDownloadProgressPresenter pullEventPercentFrom: event.
	percent ifNotNil: [
		overall := CoPCModelDownloadProgressPresenter
			overallPercentageForCompleted: index - 1
			total: totalModels
			currentPercent: percent ].

	status isEmpty ifTrue: [
		percent ifNotNil: [
			self deferUI: [
				self setupProgressPercentage: overall ] ].
		^ self ].

	message := (CoPCModelDownloadProgressPresenter pullEventStatusIsSuccess: event)
		ifTrue: [
			self
				setupDownloadedMessageFor: modelName
				index: index
				total: totalModels
				nextModel: nil
				verified: true ]
		ifFalse: [
			self setupDownloadingMessageFor: modelName index: index total: totalModels ].

	self deferUI: [
		percent ifNil: [
			self
				beginIndeterminateProgressForIndex: index
				total: totalModels ].
		percent ifNotNil: [
			self setupProgressPercentage: overall ].
		statusLabel text: message ]
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> showResearchTelemetryConsentChoiceStep [

	titleLabel label: 'Optional research data collection'.
	descriptionLabel text: 'May we share session logs, code requests, suggestions and usage data for research? This is optional for both local and cloud models.'.
	statusLabel text: ''.

	contentContainer layout: (self consentLayoutWith: self telemetryButtonRow).

	self layout: self defaultLayout
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> telemetryButtonRow [

	| learnMoreButton noButton yesButton |
	learnMoreButton := self newButton
		label: 'Learn more';
		action: [
			self
				showResearchTelemetryLearnMoreStepReturningTo: [ self showResearchTelemetryConsentChoiceStep ] ];
		yourself.

	noButton := self newButton
		label: 'No, thanks';
		action: [
			self handleResearchTelemetryDeclined.
			self showConsentSummaryStep ];
		yourself.

	yesButton := self newButton
		label: 'Yes, share research data';
		action: [
			self handleResearchTelemetryAccepted.
			self showConsentSummaryStep ];
		yourself.

	^ SpBoxLayout newTopToBottom
		spacing: 10;
		add: learnMoreButton expand: false;
		add: noButton expand: false;
		add: yesButton expand: false;
		yourself
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> showResearchTelemetryLearnMoreStepReturningTo: returnBlock [

	| detailsText backButton buttonRow |
	titleLabel label: 'Anonymous Usage Research'.
	descriptionLabel text: 'Details about the Pharo usage research project.'.
	statusLabel text: 'Use the scroll bar to read the full study information.'.

	detailsText := self newText.
	detailsText
		text: CopilotSettings researchTelemetryLearnMoreText;
		beNotEditable.

	backButton := self newButton
		label: 'Back';
		action: [ returnBlock value ];
		yourself.

	buttonRow := SpBoxLayout newHorizontal
		spacing: 10;
		add: backButton;
		yourself.

	contentContainer layout: (SpBoxLayout newTopToBottom
		spacing: 10;
		add: detailsText expand: true;
		add: buttonRow expand: false;
		yourself).

	self layout: self defaultLayout
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> showConsentSummaryStep [

	| telemetryStatus continueButton |
	titleLabel label: 'You''re ready to go'.
	descriptionLabel text: 'Pharo Copilot setup is ready to continue.'.
	statusLabel text: ''.

	telemetryStatus := self newLabel
		label: 'Research data collection: ', (CopilotSettings researchTelemetryAccepted
			ifTrue: [ 'Enabled' ]
			ifFalse: [ 'Disabled' ]);
		yourself.

	continueButton := self newButton
		label: 'Continue setup';
		action: [ self handleOk ];
		yourself.

	contentContainer layout: (SpBoxLayout newTopToBottom
		spacing: 10;
		add: telemetryStatus expand: false;
		add: continueButton expand: false;
		yourself).

	self layout: self defaultLayout
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> showWelcomeStep [

	| continueButton |
	titleLabel label: 'Welcome to Pharo-Copilot'.
	descriptionLabel text: (CopilotSettings remoteEnabled
		ifTrue: [ 'Code context is sent securely to your completion server.' ]
		ifFalse: [ 'Local AI-powered code completion for Pharo.' ]).
	statusLabel text: ''.

	continueButton := self newButton
		label: 'Continue';
		action: [
			CopilotSettings researchTelemetryNotAsked
				ifTrue: [ self showResearchTelemetryConsentChoiceStep ]
				ifFalse: [ self showConsentSummaryStep ] ];
		yourself.

	contentContainer layout: (SpBoxLayout newTopToBottom
		spacing: 10;
		add: continueButton expand: false;
		yourself).

	self layout: self defaultLayout
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> startSetupDownloads [

	downloadProcess := [
		self performSetupPipeline
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

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> performRemoteSetup [
	| available |
	self deferUI: [ statusLabel text: 'Connecting to your completion server...' ].
	available := [ CopilotSettings activateHostedCompletion ] on: Error do: [ :ex | CopilotSettings recordRemoteConnectionFailure: ex. false ].
	self deferUI: [
		self setupProgressPercentage: (available ifTrue: [ 100 ] ifFalse: [ 0 ]).
		available
			ifTrue: [
				statusLabel text: CopilotSettings hostedSetupSuccessMessage.
				self finishRemoteResearchConsentAccepted: CopilotSettings researchTelemetryAccepted ]
			ifFalse: [ self showRemoteConnectionFailedStep ] ]
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> showRemoteResearchConsentStep [
	| yesButton noButton |
	titleLabel label: 'Optional research data collection'.
	descriptionLabel text: 'Cloud requests send the code context needed to provide a completion. Separately, may we save your requests and suggestions for research? If you agree, usage and timing data are saved too. If you decline, cloud completion still works, but your code and suggestions are not saved for research.'.
	statusLabel text: 'Your cloud connection is ready. Choose whether to share research data.'.
	yesButton := self newButton
		label: 'Yes, share research data';
		action: [ self finishRemoteResearchConsentAccepted: true ];
		yourself.
	noButton := self newButton
		label: 'No, thanks';
		action: [ self finishRemoteResearchConsentAccepted: false ];
		yourself.
	contentContainer layout: (SpBoxLayout newTopToBottom
		spacing: 12;
		add: yesButton expand: false;
		add: noButton expand: false;
		yourself).
	self layout: self defaultLayout
]

{ #category : 'actions' }
PharoCopilotSetupPresenter >> finishRemoteResearchConsentAccepted: accepted [
	| decisionRecorded |
	accepted
		ifTrue: [ self handleResearchTelemetryAccepted ]
		ifFalse: [ self handleResearchTelemetryDeclined ].
	statusLabel text: 'Saving your choice...'.
	decisionRecorded := [
		CoPCSessionArchiveUploader recordResearchConsentAccepted: accepted
	] on: Error do: [ false ].
	self deferUI: [
		decisionRecorded ifFalse: [
			statusLabel text: 'Your choice is saved on this image, but the server could not record it yet. Research collection remains off on the server.'.
			CopilotSettings notifyUser: statusLabel text ].
		self window ifNotNil: [ :window | window close ] ]
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> showRemoteConnectionFailedStep [
	| retryButton tokenButton localButton |
	titleLabel label: 'Cannot connect yet'.
	descriptionLabel text: CopilotSettings remoteConnectionFailure.
	statusLabel text: 'Retry the connection or contact the person who provided your installer.'.
	tokenButton := self newButton
		label: 'Enter access token';
		action: [
			(CopilotSettings promptForHostedServer: CopilotSettings host
				model: CopilotSettings modelName secure: CopilotSettings remoteServerSecure)
				ifTrue: [ self showDownloadStep. self startSetupDownloads ] ];
		yourself.
	retryButton := self newButton
		label: 'Retry connection';
		action: [ self showDownloadStep. self startSetupDownloads ];
		 yourself.
	localButton := self newButton
		label: 'Use local model (no token needed)';
		action: [ self handleLocalModelSelected ];
		yourself.
	contentContainer layout: (SpBoxLayout newTopToBottom
		spacing: 12;
		add: retryButton expand: false;
		add: tokenButton expand: false;
		add: localButton expand: false;
		yourself).
	self layout: self defaultLayout
]
