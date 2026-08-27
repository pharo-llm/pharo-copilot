Class {
	#name : 'CoPCTestRecentCodeChanges',
	#superclass : 'CoPCRecentCodeChanges',
	#instVars : [
		'recentChanges'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
CoPCTestRecentCodeChanges >> recentChanges [

	^ recentChanges ifNil: [ #() ]
]

{ #category : 'accessing' }
CoPCTestRecentCodeChanges >> recentChanges: aCollection [

	recentChanges := aCollection
]
