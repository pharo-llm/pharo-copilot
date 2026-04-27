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
		'process'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'instance creation' }
CoPCModelDownloadProgressPresenter class >> openOn: modelNames [

	| presenter |
	presenter := self new.
	presenter models: modelNames asArray.
	presenter open.
	presenter startDownload.
	^ presenter
]

{ #category : 'layout' }
CoPCModelDownloadProgressPresenter >> appendLog: aString [

	logText text:
		(logText text asString
			, aString
			, String cr)
]

{ #category : 'layout' }
CoPCModelDownloadProgressPresenter >> completedPercentage [

	models isEmptyOrNil ifTrue: [ ^ 100 ].
	^ ((completed / models size) * 100) rounded
]

{ #category : 'layout' }
CoPCModelDownloadProgressPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
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

	models doWithIndex: [ :modelName :index |
		self deferUI: [
			statusLabel label:
				('Installing model {1} ({2}/{3})...'
					format: { modelName. index. models size }).

			progressBar indeterminate.

			self appendLog:
				('Installing model ', modelName, '... Please keep your internet connection active.')
		].

		(CopilotSettings installModelNamedForSetup: modelName)
			ifFalse: [ failed add: modelName ].

		completed := completed + 1.

		self deferUI: [
			progressBar fixedPercentage: self completedPercentage.

			self appendLog:
				((failed includes: modelName)
					ifTrue: [ 'Failed: ', modelName ]
					ifFalse: [ 'Installed: ', modelName ])
		]
	].

	[ CoPCModelRegistry refresh ] on: Error do: [ :ignored | ].

	self deferUI: [
		failed isEmpty
			ifTrue: [ statusLabel label: 'All setup models installed.' ]
			ifFalse: [
				statusLabel label:
					('Finished with {1} failed model(s). Check your internet connection and Ollama logs.'
						format: { failed size }) ].

		progressBar fixedPercentage: 100
	]
]

{ #category : 'initialization' }
CoPCModelDownloadProgressPresenter >> ensureInternetConnectionAvailable [

	CopilotSettings internetConnectionAvailable ifTrue: [ ^ true ].

	self deferUI: [
		statusLabel label: 'Internet connection required to install models.'.
		progressBar fixedPercentage: 0.
		self appendLog: 'No internet connection detected.'.
		self appendLog: 'Models cannot be downloaded without internet access.'
	].

	CopilotSettings notifyUser:
		('Internet connection required.' , String cr ,
		'Pharo Copilot cannot download Ollama models while offline.' , String cr ,
		'Please connect to the internet and try again.').

	^ false
]

{ #category : 'initialization' }
CoPCModelDownloadProgressPresenter >> initializePresenters [

	statusLabel := self newLabel.
	statusLabel label: 'Preparing Ollama model installation...'.

	progressBar := self newProgressBar.
	progressBar indeterminate.

	logText := self newText.
	logText beNotEditable.

	completed := 0.
	failed := OrderedCollection new
]

{ #category : 'accessing' }
CoPCModelDownloadProgressPresenter >> models: aCollection [

	models := aCollection asArray
]

{ #category : 'initialization' }
CoPCModelDownloadProgressPresenter >> startDownload [

	(models isNil or: [ models isEmpty ]) ifTrue: [
		statusLabel label: 'No setup models need to be installed.'.
		progressBar fixedPercentage: 100.
		^ self
	].

	process := [
		(self ensureInternetConnectionAvailable)
			ifTrue: [ self downloadModels ]
			ifFalse: [
				self deferUI: [
					progressBar fixedPercentage: 0.
					statusLabel label: 'Internet connection required to install models.'
				]
			]
	] forkAt: Processor userBackgroundPriority named: 'Pharo Copilot model download'
]
