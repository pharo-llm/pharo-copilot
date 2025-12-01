Class {
	#name : 'MockObjectsTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
MockObjectsTest >> testHttpTransportMockBasicFunctionality [ 
	| mock result |
	mock := OAHttpTransportMock new.
	
	result := mock getJsonAt: 'test/path'.
	self assert: mock lastPath equals: 'test/path'.
	self assert: (result isKindOf: Dictionary).
	
	result := mock postJsonAt: 'post/path' body: { #key -> 'value' } asDictionary.
	self assert: mock lastPath equals: 'post/path'.
	self assert: mock lastBody equals: { #key -> 'value' } asDictionary
]

{ #category : 'tests' }
MockObjectsTest >> testHttpTransportMockErrorHandling [
	| mock |
	mock := OAHttpTransportMockExtended new.
	mock configureToThrowError.
	
	self should: [ mock getJsonAt: 'test' ] raise: Error.
	self should: [ mock postJsonAt: 'test' body: Dictionary new ] raise: Error
]

{ #category : 'tests' }
MockObjectsTest >> testHttpTransportMockExtendedFeatures [
	| mock |
	mock := OAHttpTransportMockExtended new.
	
	"Test call counting"
	self assert: mock callCount equals: 0.
	mock getJsonAt: 'test'.
	self assert: mock callCount equals: 1.
	mock postJsonAt: 'test' body: Dictionary new.
	self assert: mock callCount equals: 2.
	
	"Test custom response"
	mock mockResponse: { #custom -> 'response' } asDictionary.
	self assert: (mock getJsonAt: 'test') equals: { #custom -> 'response' } asDictionary
]
