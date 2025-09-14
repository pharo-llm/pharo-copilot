Class {
	#name : 'OAHttpTransportMockExtended',
	#superclass : 'OAHttpTransportMock',
	#instVars : [
		'mockResponse',
		'shouldThrowError',
		'callCount'
	],
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
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
OAHttpTransportMockExtended >> postJsonAt: aPath body: aDictionary [
	callCount := self callCount + 1.
	lastPath := aPath.
	lastBody := aDictionary.
	
	shouldThrowError ifTrue: [ 
		Error signal: 'Mock network error' ].
		
	^ mockResponse ifNil: [ Dictionary new ]
]
