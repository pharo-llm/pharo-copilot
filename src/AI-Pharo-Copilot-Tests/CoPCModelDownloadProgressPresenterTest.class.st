Class {
	#name : 'CoPCModelDownloadProgressPresenterTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoPCModelDownloadProgressPresenterTest >> testOverallPercentageCombinesCompletedModelsAndCurrentPercent [

	self
		assert: (CoPCModelDownloadProgressPresenter
			overallPercentageForCompleted: 1
			total: 4
			currentPercent: 50)
		equals: 38
]

{ #category : 'tests' }
CoPCModelDownloadProgressPresenterTest >> testPullEventPercentAcceptsStringKeysAndStringNumbers [

	| event |
	event := Dictionary new
		at: 'total' put: '1000';
		at: 'completed' put: '250';
		yourself.

	self
		assert: (CoPCModelDownloadProgressPresenter pullEventPercentFrom: event)
		equals: 25
]

{ #category : 'tests' }
CoPCModelDownloadProgressPresenterTest >> testPullEventPercentAcceptsSymbolKeys [

	| event |
	event := Dictionary new
		at: #total put: 200;
		at: #completed put: 50;
		yourself.

	self
		assert: (CoPCModelDownloadProgressPresenter pullEventPercentFrom: event)
		equals: 25
]

{ #category : 'tests' }
CoPCModelDownloadProgressPresenterTest >> testPullEventPercentReturnsHundredForSuccessStatus [

	| event |
	event := Dictionary new
		at: #status put: 'success';
		yourself.

	self
		assert: (CoPCModelDownloadProgressPresenter pullEventPercentFrom: event)
		equals: 100
]

{ #category : 'tests' }
CoPCModelDownloadProgressPresenterTest >> testPullEventStatusAcceptsStringKey [

	| event |
	event := Dictionary new
		at: 'status' put: 'pulling manifest';
		yourself.

	self
		assert: (CoPCModelDownloadProgressPresenter pullEventStatusFrom: event)
		equals: 'pulling manifest'
]
