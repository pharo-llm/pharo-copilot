Class {
	#name : 'CoCancellableRequestRegistryTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
CoCancellableRequestRegistryTest >> setUp [
        super setUp.
        CoCancellableRequestRegistry reset
]

{ #category : 'running' }
CoCancellableRequestRegistryTest >> tearDown [

        CoCancellableRequestRegistry cancelAllActiveRequests.
        super tearDown
]

{ #category : 'running' }
CoCancellableRequestRegistryTest >> testCancellingActiveRequestsMarksAndClearsRegistry [

| requestOne requestTwo |
requestOne := CoCancellableRequest withContext: (Dictionary new).
requestOne process: ([ ] newProcess).
requestTwo := CoCancellableRequest withContext: (Dictionary new).
requestTwo process: ([ ] newProcess).

        CoCancellableRequestRegistry register: requestOne.
        CoCancellableRequestRegistry register: requestTwo.

        self assert: CoCancellableRequestRegistry activeRequestCount equals: 2.

        CoCancellableRequestRegistry cancelAllActiveRequests.

        self assert: requestOne cancelled.
        self assert: requestTwo cancelled.
        self assert: CoCancellableRequestRegistry activeRequestCount equals: 0
]

{ #category : 'running' }
CoCancellableRequestRegistryTest >> testRegisterCompletionRemovesRequest [

        | request |
        request := CoCancellableRequest withContext: (Dictionary new).
        CoCancellableRequestRegistry register: request.

        self assert: CoCancellableRequestRegistry activeRequestCount equals: 1.

        request registerCompletion.

        self assert: CoCancellableRequestRegistry activeRequestCount equals: 0
]
