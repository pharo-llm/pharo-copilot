Class {
	#name : 'OAHttpTransportMockExtended',
	#superclass : 'OAHttpTransportMock',
	#instVars : [
		'mockResponse',
		'shouldThrowError',
		'callCount',
		'streamingLines',
		'lastTimeoutSeconds'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
OAHttpTransportMockExtended >> callCount [
	^ callCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
OAHttpTransportMockExtended >> configureToThrowError [
	shouldThrowError := true
]

{ #category : 'accessing' }
OAHttpTransportMockExtended >> getJsonAt: aPath [
	callCount := self callCount + 1.
	lastPath := aPath.
	
	shouldThrowError ifTrue: [ 
		Error signal: 'Mock network error' ].
		
	^ mockResponse ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
OAHttpTransportMockExtended >> initialize [
	super initialize.
	callCount := 0.
	shouldThrowError := false.
	mockResponse := Dictionary new
]

{ #category : 'accessing' }
OAHttpTransportMockExtended >> mockResponse: aDictionary [
	mockResponse := aDictionary
]

{ #category : 'accessing' }
OAHttpTransportMockExtended >> lastTimeoutSeconds [

	^ lastTimeoutSeconds
]

{ #category : 'accessing' }
OAHttpTransportMockExtended >> postJsonAt: aPath body: aDictionary [
	callCount := self callCount + 1.
	lastPath := aPath.
	lastBody := aDictionary.
	
	shouldThrowError ifTrue: [ 
		Error signal: 'Mock network error' ].
		
	^ mockResponse ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
OAHttpTransportMockExtended >> postJsonAt: aPath body: aDictionary timeoutSeconds: timeoutSeconds [

	lastTimeoutSeconds := timeoutSeconds.
	^ self postJsonAt: aPath body: aDictionary
]

{ #category : 'accessing' }
OAHttpTransportMockExtended >> postStreamingAt: aPath body: aDictionary timeoutSeconds: timeoutSeconds linesDo: aBlock [

	callCount := self callCount + 1.
	lastPath := aPath.
	lastBody := aDictionary.
	lastTimeoutSeconds := timeoutSeconds.

	shouldThrowError ifTrue: [
		Error signal: 'Mock network error' ].

	(streamingLines ifNil: [ #() ]) do: [ :each |
		aBlock value: each ]
]

{ #category : 'accessing' }
OAHttpTransportMockExtended >> streamingLines: aCollection [

	streamingLines := aCollection
]
