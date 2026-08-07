"
I show the progress of Ollama model downloads: the list of models that will be
installed, which one is currently downloading, its live percentage and byte counts,
and the overall progress across all models.
"
Class {
	#name : 'CoPCModelDownloadProgressPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'models',
		'progressBar',
		'statusLabel',
		'logText',
		'completed',
		'failed',
		'process',
		'statusByModel',
		'lastPercent',
		'currentProgress',
		'progressIsIndeterminate'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'progress' }
CoPCModelDownloadProgressPresenter class >> formatBytes: aNumber [

	| bytes |
	(aNumber isNumber and: [ aNumber >= 0 ]) ifFalse: [ ^ '?' ].
	bytes := aNumber asFloat.
	bytes >= 1e9 ifTrue: [ ^ ((bytes / 1e9) printShowingDecimalPlaces: 2) , ' GB' ].
	bytes >= 1e6 ifTrue: [ ^ ((bytes / 1e6) printShowingDecimalPlaces: 1) , ' MB' ].
	bytes >= 1e3 ifTrue: [ ^ ((bytes / 1e3) printShowingDecimalPlaces: 0) , ' KB' ].
	^ (bytes printShowingDecimalPlaces: 0) , ' B'
]

{ #category : 'progress' }
CoPCModelDownloadProgressPresenter class >> indeterminateProgressFrom: current start: start end: end step: step [

	| boundedStart boundedEnd boundedCurrent next |
	boundedStart := ((start ifNil: [ 0 ]) max: 0) min: 1.
	boundedEnd := ((end ifNil: [ 1 ]) max: boundedStart) min: 1.
	boundedStart = boundedEnd ifTrue: [ ^ boundedStart ].

	boundedCurrent := ((current ifNil: [ boundedStart ]) max: boundedStart) min: boundedEnd.
	next := boundedCurrent + (step ifNil: [ 0.004 ]).
	next >= boundedEnd ifTrue: [ ^ boundedStart ].
	^ next
]

{ #category : 'progress' }
CoPCModelDownloadProgressPresenter class >> numberFromPullEventValue: value [

	| string |
	value ifNil: [ ^ nil ].
	value isNumber ifTrue: [ ^ value ].
	(value respondsTo: #asString) ifFalse: [ ^ nil ].

	string := value asString trimBoth.
	string isEmpty ifTrue: [ ^ nil ].
	^ [ Number readFrom: string readStream ] on: Error do: [ nil ]
]

{ #category : 'instance creation' }
CoPCModelDownloadProgressPresenter class >> openOn: modelNames [

	| presenter |
	presenter := self new.
	presenter models: modelNames asArray.
	presenter open.
	presenter startDownload.
	^ presenter
]

{ #category : 'progress' }
CoPCModelDownloadProgressPresenter class >> overallPercentageForCompleted: completedCount total: modelCount currentPercent: currentModelPercent [

	modelCount <= 0 ifTrue: [ ^ 100 ].
	^ ((((completedCount * 100) + currentModelPercent) / modelCount) rounded min: 100) max: 0
]

{ #category : 'progress' }
CoPCModelDownloadProgressPresenter class >> pullEventNumberAt: key from: event [

	^ self numberFromPullEventValue: (self pullEventValueAt: key from: event)
]

{ #category : 'progress' }
CoPCModelDownloadProgressPresenter class >> pullEventPercentFrom: event [

	| total done |
	(self pullEventStatusIsSuccess: event) ifTrue: [ ^ 100 ].

	total := self pullEventNumberAt: #total from: event.
	done := self pullEventNumberAt: #completed from: event.
	(total isNumber and: [ done isNumber and: [ total > 0 ] ]) ifFalse: [ ^ nil ].

	^ (((done / total) * 100) truncated min: 100) max: 0
]

{ #category : 'progress' }
CoPCModelDownloadProgressPresenter class >> pullEventStatusFrom: event [

	| status |
	status := self pullEventValueAt: #status from: event.
	^ status ifNil: [ '' ] ifNotNil: [ status asString ]
]

{ #category : 'progress' }
CoPCModelDownloadProgressPresenter class >> pullEventStatusIsSuccess: event [

	| status |
	status := self pullEventStatusFrom: event.
	status isEmpty ifTrue: [ ^ false ].
	^ status asLowercase includesSubstring: 'success'
]

{ #category : 'progress' }
CoPCModelDownloadProgressPresenter class >> pullEventValueAt: key from: event [

	(event respondsTo: #at:ifAbsent:) ifFalse: [ ^ nil ].
	^ event
		at: key
		ifAbsent: [ event at: key asString ifAbsent: [ nil ] ]
]

{ #category : 'layout' }
CoPCModelDownloadProgressPresenter >> appendLog: aString [

	logText text:
		(logText text asString
			, aString
			, String cr)
]

{ #category : 'progress' }
CoPCModelDownloadProgressPresenter >> beginIndeterminateProgress [

	currentProgress ifNil: [
		currentProgress := self indeterminateProgressStart ].
	progressIsIndeterminate := true
]

{ #category : 'layout' }
CoPCModelDownloadProgressPresenter >> completedPercentage [

	models isEmptyOrNil ifTrue: [ ^ 100 ].
	^ ((completed / models size) * 100) rounded
]

{ #category : 'layout' }
CoPCModelDownloadProgressPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		spacing: 8;
		borderWidth: 10;
		add: statusLabel expand: false;
		add: progressBar expand: false;
		add: logText;
		yourself
]

{ #category : 'layout' }
CoPCModelDownloadProgressPresenter >> deferUI: aBlock [

	| ui |
	ui := [ UIManager default ] on: Error do: [ nil ].

	(ui notNil and: [ ui respondsTo: #defer: ]) ifTrue: [
		^ ui defer: aBlock
	].

	^ aBlock value
]

{ #category : 'initialization' }
CoPCModelDownloadProgressPresenter >> downloadModels [

	models do: [ :modelName |
		statusByModel at: modelName put: 'waiting' ].
	self deferUI: [ self renderStatusBoard ].

	models doWithIndex: [ :modelName :index |
		| installed verified |
		lastPercent := -1.
		statusByModel at: modelName put: 'downloading...'.

		self deferUI: [
			statusLabel label:
				('Downloading {2}/{3}: {1}'
					format: { modelName. index. models size }).
			self beginIndeterminateProgress.
			self renderStatusBoard
		].

		installed := CopilotSettings
			installModelNamedForSetup: modelName
			progress: [ :event |
				self handlePullEvent: event forModel: modelName ].

		verified := installed and: [
			CopilotSettings
				refreshModelsAfterInstallOf: modelName
				usingInitialResponse: (Dictionary new at: #models put: #(); yourself) ].

		verified ifFalse: [ failed add: modelName ].
		completed := completed + 1.
		statusByModel
			at: modelName
			put: (verified
				ifTrue: [ 'installed' ]
				ifFalse: [
					installed
						ifTrue: [ 'FAILED - not available in Ollama' ]
						ifFalse: [ 'FAILED - check internet connection and Ollama logs' ] ]).

		self deferUI: [
			self progressPercentage: self completedPercentage.
			self renderStatusBoard
		]
	].

	[ CoPCModelRegistry refresh ] on: Error do: [ :ignored | ].

	self deferUI: [
		failed isEmpty
			ifTrue: [ statusLabel label: 'All models installed.' ]
			ifFalse: [
				statusLabel label:
					('Finished with {1} model(s) not available in Ollama. Check the status board, Ollama logs, and ''ollama list''.'
						format: { failed size }) ].

		self progressPercentage: 100
	]
]

{ #category : 'initialization' }
CoPCModelDownloadProgressPresenter >> ensureInternetConnectionAvailable [

	CopilotSettings internetConnectionAvailable ifTrue: [ ^ true ].

	self deferUI: [
		statusLabel label: 'Internet connection required to install models.'.
		self progressPercentage: 0.
		self appendLog: 'No internet connection detected.'.
		self appendLog: 'Models cannot be downloaded without internet access.'
	].

	CopilotSettings notifyUser:
		('Internet connection required.' , String cr ,
		'Pharo Copilot cannot download Ollama models while offline.' , String cr ,
		'Please connect to the internet and try again.').

	^ false
]

{ #category : 'formatting' }
CoPCModelDownloadProgressPresenter >> formatBytes: aNumber [

	^ self class formatBytes: aNumber
]

{ #category : 'initialization' }
CoPCModelDownloadProgressPresenter >> handlePullEvent: event forModel: modelName [
	"React to one streaming status line from an Ollama pull. Updates the UI only when
	the integer percentage changes, to avoid flooding the UI queue."

	| total done percent status statusText |
	status := self class pullEventStatusFrom: event.
	percent := self class pullEventPercentFrom: event.

	percent ifNil: [
		status isEmpty ifTrue: [ ^ self ].
		(statusByModel at: modelName ifAbsent: [ '' ]) = status ifTrue: [ ^ self ].
		statusByModel at: modelName put: status.
		^ self deferUI: [
			self beginIndeterminateProgress.
			statusLabel label:
				('Downloading {2}/{3}: {1}'
					format: { modelName. completed + 1. models size }).
			self renderStatusBoard ] ].

	total := self class pullEventNumberAt: #total from: event.
	done := self class pullEventNumberAt: #completed from: event.
	statusText := (total isNumber and: [ done isNumber ])
		ifTrue: [
			'downloading - {1}% ({2} / {3})'
			format: {
				percent.
				self formatBytes: done.
				self formatBytes: total } ]
		ifFalse: [ 'downloading - ', percent asString, '%' ].

	(percent = lastPercent
		and: [ (statusByModel at: modelName ifAbsent: [ '' ]) = statusText ]) ifTrue: [ ^ self ].
	lastPercent := percent.

	statusByModel at: modelName put: statusText.

	self deferUI: [
		statusLabel label:
			('Downloading {2}/{3}: {1}'
				format: { modelName. completed + 1. models size }).
		self progressPercentage: (self overallPercentageWithCurrent: percent).
		self renderStatusBoard
	]
]

{ #category : 'initialization' }
CoPCModelDownloadProgressPresenter >> initializePresenters [

	statusLabel := self newLabel.
	statusLabel label: 'Preparing Ollama model installation...'.

	currentProgress := 0.
	progressIsIndeterminate := false.
	progressBar := self newProgressBar.
	progressBar
		progress: [ self progressBarValue ]
		every: 0.1 second.

	logText := self newText.
	logText beNotEditable.

	completed := 0.
	failed := OrderedCollection new.
	statusByModel := Dictionary new.
	lastPercent := -1
]

{ #category : 'progress' }
CoPCModelDownloadProgressPresenter >> indeterminateProgressEnd [

	models isEmptyOrNil ifTrue: [ ^ 1 ].
	^ (((completed + 1) asFloat / models size) min: 1) max: 0
]

{ #category : 'progress' }
CoPCModelDownloadProgressPresenter >> indeterminateProgressStart [

	models isEmptyOrNil ifTrue: [ ^ 0 ].
	^ ((completed asFloat / models size) min: 1) max: 0
]

{ #category : 'initialization' }
CoPCModelDownloadProgressPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.

	aWindowPresenter
		title: 'Pharo Copilot — Model Downloads';
		initialExtent: 560 @ 320
]

{ #category : 'accessing' }
CoPCModelDownloadProgressPresenter >> models: aCollection [

	models := aCollection asArray
]

{ #category : 'layout' }
CoPCModelDownloadProgressPresenter >> overallPercentageWithCurrent: currentModelPercent [
	"Overall progress across all models: finished models count fully, the model being
	downloaded contributes its own fraction."

	models isEmptyOrNil ifTrue: [ ^ 100 ].
	^ self class
		overallPercentageForCompleted: completed
		total: models size
		currentPercent: currentModelPercent
]

{ #category : 'progress' }
CoPCModelDownloadProgressPresenter >> progressBarValue [

	progressIsIndeterminate ifTrue: [
		currentProgress := self class
			indeterminateProgressFrom: currentProgress
			start: self indeterminateProgressStart
			end: self indeterminateProgressEnd
			step: 0.004 ].

	^ currentProgress ifNil: [ 0 ]
]

{ #category : 'layout' }
CoPCModelDownloadProgressPresenter >> progressPercentage: aNumber [

	| bounded |
	progressIsIndeterminate := false.
	bounded := (aNumber ifNil: [ 0 ]) max: 0.
	bounded := bounded min: 100.
	currentProgress := bounded / 100.0
]

{ #category : 'layout' }
CoPCModelDownloadProgressPresenter >> renderStatusBoard [
	"Re-render the whole per-model status list."

	logText text: (String streamContents: [ :s |
		s nextPutAll: 'Models to install ('.
		s nextPutAll: models size asString.
		s nextPutAll: '):'; cr.
		models do: [ :modelName |
			s
				nextPutAll: '- ';
				nextPutAll: modelName asString;
				nextPutAll: ': ';
				nextPutAll: (statusByModel at: modelName ifAbsent: [ 'waiting' ]);
				cr ] ])
]

{ #category : 'initialization' }
CoPCModelDownloadProgressPresenter >> startDownload [

	(models isNil or: [ models isEmpty ]) ifTrue: [
		statusLabel label: 'No setup models need to be installed.'.
		self progressPercentage: 100.
		^ self
	].

	process := [
		(self ensureInternetConnectionAvailable)
			ifTrue: [ self downloadModels ]
			ifFalse: [
				self deferUI: [
					self progressPercentage: 0.
					statusLabel label: 'Internet connection required to install models.'
				]
			]
	] forkAt: Processor userBackgroundPriority named: 'Pharo Copilot model download'
]
