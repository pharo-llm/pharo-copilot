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
		  spacing: 10;
		  borderWidth: 14;
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
PharoCopilotSetupPresenter >> handleScreenRecordingAccepted [

	CopilotSettings recordScreenRecordingConsentAccepted: true
]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> handleScreenRecordingDeclined [

	CopilotSettings recordScreenRecordingConsentAccepted: false
]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> continueSetupAfterConsentDecision [

	self showDownloadStep.
	statusLabel label: (CopilotSettings researchTelemetryAccepted
		ifTrue: [ 'Authorizing server connection...' ]
		ifFalse: [ 'Anonymous research telemetry disabled. Continuing local setup.' ]).
	self startSetupDownloads
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> initializePresenters [

	super initializePresenters.

	titleLabel := self newLabel
		label: 'Welcome to Pharo-Copilot';
		yourself.

	descriptionLabel := self newLabel
		label: '';
		yourself.

	statusLabel := self newLabel
		label: '';
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

	self showWelcomeStep
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.

	aWindowPresenter
		title: 'Pharo-Copilot Setup';
		initialExtent: 560 @ 420;
		centered.

]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> performSetupDownloads [

	| response missingModels failedModels |

	self setupProgressPercentage: 0.
	self deferUI: [ statusLabel label: '' ].

	response := CopilotSettings listModelsForSetupAfterLaunchingOllamaIfNeeded.

	response ifNil: [
		self setupProgressPercentage: 0.
		^ self deferUI: [
			statusLabel label: 'Cannot continue. Ollama is required.'.
			self showMissingOllamaStep
		]
	].

	missingModels := CopilotSettings missingSetupModelNamesFrom: response.

	missingModels isEmpty ifTrue: [
		[ CoPCModelRegistry refresh ] on: Error do: [ :ignored | ].
		CopilotSettings ensureDefaultCompletionModelSelected.
		CopilotSettings installCompletionEngineIfAvailable.
		self setupProgressPercentage: 100.
		^ self deferUI: [
			statusLabel label: 'OKAY! Pharo-Copilot setup is complete.'.
			CopilotSettings notifyUser: 'OKAY! Pharo-Copilot setup is complete.'.
			self window close
		]
	].

	self deferUI: [
		self
			beginIndeterminateProgressForIndex: 1
			total: missingModels size.
		descriptionLabel label:
			('Downloading {1} model(s):'
				format: { missingModels size }).
		statusLabel label:
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
			statusLabel label:
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
			statusLabel label:
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
				CopilotSettings installCompletionEngineIfAvailable.
				self setupProgressPercentage: 100.
				statusLabel label: 'Pharo-Copilot setup is complete.'.
				CopilotSettings notifyUser: 'Pharo-Copilot setup is complete.'.
				self window close ]
			ifFalse: [
				statusLabel label:
					('Setup finished with {1}/{2} model(s) not available in Ollama. Check the message above, Ollama logs, and ''ollama list''.'
						format: { failedModels size. missingModels size }) ]
	]
]

{ #category : 'accessing' }
PharoCopilotSetupPresenter >> performSetupPipeline [

	| authorized |
	self setupProgressPercentage: 0.

	CopilotSettings researchTelemetryAccepted ifFalse: [
		self deferUI: [ statusLabel label: 'Anonymous research telemetry disabled. Continuing local setup.' ].
		(Delay forMilliseconds: 500) wait.
		^ self performSetupDownloads ].

	self deferUI: [ statusLabel label: 'Authorizing server connection...' ].

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
			statusLabel label: 'Connection denied. Continuing setup.'.
			CopilotSettings notifyUser: 'Connection denied. Continuing setup.' ].
		(Delay forMilliseconds: 500) wait.
		^ self performSetupDownloads ].

	self deferUI: [
		statusLabel label: 'Connection authorized. Continuing setup.'.
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
	descriptionLabel label: 'LOADING .....'.
	statusLabel label: ''.

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

	| messageLabel installButton centeredRow centeredColumn |
	titleLabel label: 'Ollama Required'.
	descriptionLabel label: 'Pharo-Copilot needs Ollama to continue.'.
	statusLabel label: 'Setup could not continue without Ollama.'.

	messageLabel := self newLabel
		label: CopilotSettings missingOllamaSetupMessage;
		yourself.

	installButton := self newButton
		label: 'Download Ollama';
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
		statusLabel label: message ]
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> showResearchTelemetryConsentChoiceStep [

	| learnMoreButton noButton yesButton buttonRow |
	titleLabel label: 'Help improve AI code completion'.
	descriptionLabel label: 'Can we collect anonymous usage data?'.
	statusLabel label: ''.

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
			self showScreenRecordingConsentStep ];
		yourself.

	yesButton := self newButton
		label: 'Yes, share anonymous data';
		action: [
			self handleResearchTelemetryAccepted.
			self showScreenRecordingConsentStep ];
		yourself.

	buttonRow := SpBoxLayout newHorizontal
		spacing: 10;
		add: learnMoreButton;
		add: noButton;
		add: yesButton;
		yourself.

	contentContainer layout: (SpBoxLayout newTopToBottom
		spacing: 12;
		add: buttonRow expand: false;
		yourself).

	self layout: self defaultLayout
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> showResearchTelemetryLearnMoreStepReturningTo: returnBlock [

	| detailsText backButton buttonRow |
	titleLabel label: 'Anonymous Usage Research'.
	descriptionLabel label: 'Details about the Pharo usage research project.'.
	statusLabel label: 'Use the scroll bar to read the full study information.'.

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
PharoCopilotSetupPresenter >> showScreenRecordingConsentStep [

	| learnMoreButton noButton yesButton buttonRow |
	titleLabel label: 'Can we record your screen?'.
	descriptionLabel label: 'Screen recordings help researchers understand how developers work with AI code completion. A recording may capture code visible on your screen.'.
	statusLabel label: ''.

	learnMoreButton := self newButton
		label: 'Learn more';
		action: [
			self
				showScreenRecordingLearnMoreStepReturningTo: [ self showScreenRecordingConsentStep ] ];
		yourself.

	noButton := self newButton
		label: 'No, thanks';
		action: [
			self handleScreenRecordingDeclined.
			self showConsentSummaryStep ];
		yourself.

	yesButton := self newButton
		label: 'Yes, allow recording';
		action: [
			self handleScreenRecordingAccepted.
			self showConsentSummaryStep ];
		yourself.

	buttonRow := SpBoxLayout newHorizontal
		spacing: 10;
		add: learnMoreButton;
		add: noButton;
		add: yesButton;
		yourself.

	contentContainer layout: (SpBoxLayout newTopToBottom
		spacing: 12;
		add: buttonRow expand: false;
		yourself).

	self layout: self defaultLayout
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> showScreenRecordingLearnMoreStepReturningTo: returnBlock [

	| detailsText backButton buttonRow |
	titleLabel label: 'Screen Recording'.
	descriptionLabel label: 'Details about screen recording for research.'.
	statusLabel label: 'Use the scroll bar to read the full information.'.

	detailsText := self newText.
	detailsText
		text: CopilotSettings screenRecordingLearnMoreText;
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

	| telemetryStatus recordingStatus continueButton |
	titleLabel label: 'You''re ready to go'.
	descriptionLabel label: 'Pharo Copilot setup is ready to continue.'.
	statusLabel label: ''.

	telemetryStatus := self newLabel
		label: 'Anonymous usage data: ', (CopilotSettings researchTelemetryAccepted
			ifTrue: [ 'Enabled' ]
			ifFalse: [ 'Disabled' ]);
		yourself.

	recordingStatus := self newLabel
		label: 'Screen recording: ', (CopilotSettings screenRecordingAccepted
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
		add: recordingStatus expand: false;
		add: continueButton expand: false;
		yourself).

	self layout: self defaultLayout
]

{ #category : 'initialization' }
PharoCopilotSetupPresenter >> showWelcomeStep [

	| continueButton |
	titleLabel label: 'Welcome to Pharo-Copilot'.
	descriptionLabel label: 'Local AI-powered code completion for Pharo.'.
	statusLabel label: ''.

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
