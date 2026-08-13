"
I show a compact progress window while the current Pharo Copilot session is saved
and its telemetry JSON is uploaded.
"
Class {
	#name : 'CoPCSessionArchiveProgressPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'titleLabel',
		'descriptionLabel',
		'statusLabel',
		'progressBar',
		'archiveProcess',
		'currentProgress',
		'progressIsIndeterminate',
		'archiveFile',
		'finished',
		'completionBlock'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'instance creation' }
CoPCSessionArchiveProgressPresenter class >> openForCurrentSession [

	| presenter |
	presenter := self new.
	presenter open.
	presenter startArchiving.
	^ presenter
]

{ #category : 'instance creation' }
CoPCSessionArchiveProgressPresenter class >> openForCurrentSessionAndWait [

	| presenter done result |
	done := false.
	presenter := self new.
	presenter onCompletion: [ :archive |
		result := archive.
		done := true ].
	presenter open.
	presenter startArchiving.
	self runUIUntil: [ done ].
	^ result
]

{ #category : 'private' }
CoPCSessionArchiveProgressPresenter class >> runOneUICycle [

	| worldMorphClass |
	worldMorphClass := Smalltalk globals
		at: #WorldMorph
		ifAbsent: [ nil ].

	(worldMorphClass notNil and: [ worldMorphClass respondsTo: #doOneCycle ])
		ifTrue: [
			[ worldMorphClass doOneCycle ] on: Error do: [ :ignored | ] ]
]

{ #category : 'private' }
CoPCSessionArchiveProgressPresenter class >> runUIUntil: conditionBlock [

	[ conditionBlock value ] whileFalse: [
		self runOneUICycle.
		(Delay forMilliseconds: 50) wait ]
]

{ #category : 'accessing' }
CoPCSessionArchiveProgressPresenter >> archiveFile [

	^ archiveFile
]

{ #category : 'progress' }
CoPCSessionArchiveProgressPresenter >> beginIndeterminateProgress [

	currentProgress ifNil: [ currentProgress := 0.05 ].
	progressIsIndeterminate := true
]

{ #category : 'private' }
CoPCSessionArchiveProgressPresenter >> closeWindowSoon [

	[
		(Delay forMilliseconds: 700) wait.
		self deferUI: [
			self window ifNotNil: [ :windowPresenter |
				windowPresenter close ] ]
	] forkAt: Processor userBackgroundPriority named: 'Pharo Copilot archive progress close'
]

{ #category : 'layout' }
CoPCSessionArchiveProgressPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		spacing: 10;
		borderWidth: 14;
		add: titleLabel expand: false;
		add: descriptionLabel expand: false;
		add: progressBar expand: false;
		add: statusLabel expand: false;
		yourself
]

{ #category : 'private' }
CoPCSessionArchiveProgressPresenter >> deferUI: aBlock [

	| ui |
	ui := [ UIManager default ] on: Error do: [ nil ].

	(ui notNil and: [ ui respondsTo: #defer: ]) ifTrue: [
		^ ui defer: aBlock ].

	^ aBlock value
]

{ #category : 'progress' }
CoPCSessionArchiveProgressPresenter >> handleArchiveProgressEvent: event [

	| status percent |
	status := event
		at: #status
		ifAbsent: [ event at: 'status' ifAbsent: [ 'Archiving session...' ] ].
	percent := self progressPercentFrom: event.

	self deferUI: [
		statusLabel label: status asString.
		percent
			ifNil: [ self beginIndeterminateProgress ]
			ifNotNil: [ self progressPercentage: percent ] ]
]

{ #category : 'initialization' }
CoPCSessionArchiveProgressPresenter >> initializePresenters [

	titleLabel := self newLabel
		label: 'Saving Pharo-Copilot telemetry';
		yourself.

	descriptionLabel := self newLabel
		label: 'Creating the anonymous research JSON before quitting.';
		yourself.

	statusLabel := self newLabel
		label: 'Preparing session archive...';
		yourself.

	currentProgress := 0.
	progressIsIndeterminate := false.
	finished := false.
	archiveFile := nil.

	progressBar := self newProgressBar.
	progressBar
		progress: [ self progressBarValue ]
		every: 0.1 second
]

{ #category : 'initialization' }
CoPCSessionArchiveProgressPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.

	aWindowPresenter
		title: 'Pharo-Copilot Session Archive';
		initialExtent: 560 @ 170;
		centered
]

{ #category : 'accessing' }
CoPCSessionArchiveProgressPresenter >> isFinished [

	^ finished = true
]

{ #category : 'accessing' }
CoPCSessionArchiveProgressPresenter >> onCompletion: aBlock [

	completionBlock := aBlock
]

{ #category : 'progress' }
CoPCSessionArchiveProgressPresenter >> progressBarValue [

	progressIsIndeterminate ifTrue: [
		currentProgress := CoPCModelDownloadProgressPresenter
			indeterminateProgressFrom: currentProgress
			start: 0.05
			end: 0.95
			step: 0.006 ].

	^ currentProgress ifNil: [ 0 ]
]

{ #category : 'progress' }
CoPCSessionArchiveProgressPresenter >> progressPercentFrom: event [

	| value string |
	value := event
		at: #percent
		ifAbsent: [ event at: 'percent' ifAbsent: [ nil ] ].
	value ifNil: [ ^ nil ].
	value isNumber ifTrue: [ ^ value ].
	(value respondsTo: #asString) ifFalse: [ ^ nil ].

	string := value asString trimBoth.
	string isEmpty ifTrue: [ ^ nil ].
	^ [ Number readFrom: string readStream ] on: Error do: [ nil ]
]

{ #category : 'progress' }
CoPCSessionArchiveProgressPresenter >> progressPercentage: aNumber [

	| bounded |
	progressIsIndeterminate := false.
	bounded := (aNumber ifNil: [ 0 ]) max: 0.
	bounded := bounded min: 100.
	currentProgress := bounded / 100.0
]

{ #category : 'initialization' }
CoPCSessionArchiveProgressPresenter >> startArchiving [

	archiveProcess := [
		| result |
		result := [
			CoPharoCopilotLogger archiveCurrentSessionReportingProgress: [ :event |
				self handleArchiveProgressEvent: event ]
		] on: Error do: [ :ex |
			self deferUI: [
				statusLabel label: 'Could not archive Copilot session.'.
				self progressPercentage: 0 ].
			nil ].

		archiveFile := result.

		self deferUI: [
			result
				ifNil: [
					statusLabel label: 'Could not archive Copilot session.'.
					self progressPercentage: 0 ]
				ifNotNil: [
					statusLabel label: 'Session telemetry JSON is complete.'.
					self progressPercentage: 100 ] ].

		finished := true.
		completionBlock ifNotNil: [
			[ completionBlock value: result ] on: Error do: [ :ignored | ] ].
		result ifNotNil: [ self closeWindowSoon ]
	] forkAt: Processor userBackgroundPriority named: 'Pharo Copilot session archive'
]
