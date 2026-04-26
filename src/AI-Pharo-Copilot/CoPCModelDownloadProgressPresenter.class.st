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

{ #category : 'layout' }
CoPCModelDownloadProgressPresenter >> downloadModels [

	models doWithIndex: [ :modelName :index |
		self deferUI: [
			statusLabel label:
				('Downloading {1} ({2}/{3})'
					format: { modelName. index. models size }).
			self appendLog: 'Starting ', modelName
		].

		(CopilotSettings installModelNamed: modelName)
			ifFalse: [ failed add: modelName ].

		completed := completed + 1.

		self deferUI: [
			progressBar fixedPercentage: self completedPercentage.
			self appendLog:
				((failed includes: modelName)
					ifTrue: [ 'Failed: ', modelName ]
					ifFalse: [ 'Completed: ', modelName ])
		]
	].

	[ CoPCModelRegistry refresh ] on: Error do: [ :ignored | ].

	self deferUI: [
		failed isEmpty
			ifTrue: [ statusLabel label: 'All setup models downloaded.' ]
			ifFalse: [
				statusLabel label:
					('Finished with {1} failed model(s).'
						format: { failed size }) ].
		progressBar fixedPercentage: 100
	]
]

{ #category : 'initialization' }
CoPCModelDownloadProgressPresenter >> initializePresenters [

	statusLabel := self newLabel.
	statusLabel label: 'Preparing Ollama model downloads...'.

	progressBar := self newProgressBar.
	progressBar fixedPercentage: 0.

	logText := self newText.
	logText beNotEditable.

	completed := 0.
	failed := OrderedCollection new
]

{ #category : 'accessing' }
CoPCModelDownloadProgressPresenter >> models: aCollection [

	models := aCollection asArray
]

{ #category : 'layout' }
CoPCModelDownloadProgressPresenter >> startDownload [

	(models isNil or: [ models isEmpty ]) ifTrue: [
		statusLabel label: 'No setup models need to be downloaded.'.
		progressBar fixedPercentage: 100.
		^ self
	].

	process := [
		self downloadModels
	] forkAt: Processor userBackgroundPriority named: 'Pharo Copilot model download'
]
