Class {
	#name : 'CoCompletionDebouncerTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoCompletionDebouncerTest >> testCancelsPendingRequestWhenRescheduled [

	| debouncer semaphore counter |
	debouncer := CoCompletionDebouncer new.
	debouncer delayMilliseconds: 30.
	semaphore := Semaphore new.
	counter := 0.

	debouncer schedule: [
			counter := counter + 1.
			semaphore signal ].
	debouncer schedule: [
			counter := counter + 10.
			semaphore signal ].

	semaphore waitTimeoutMilliseconds: 300.

	self assert: counter equals: 10
]

{ #category : 'tests' }
CoCompletionDebouncerTest >> testConfigurableDelayOverridesDefault [

        | debouncer |
        debouncer := CoCompletionDebouncer new.
        debouncer delayMilliseconds: 10.
        self assert: debouncer delayMilliseconds equals: 10
]

{ #category : 'tests' }
CoCompletionDebouncerTest >> testDefaultDelayIs150Milliseconds [


        | debouncer |
        debouncer := CoCompletionDebouncer new.
        self assert: debouncer delayMilliseconds equals: 150

]

{ #category : 'tests' }
CoCompletionDebouncerTest >> testImmediateBypassRunsWithoutDelay [

	| debouncer semaphore start elapsed |
	debouncer := CoCompletionDebouncer new.
	debouncer delayMilliseconds: 250.
	semaphore := Semaphore new.
	start := Time millisecondClockValue.

	debouncer schedule: [ semaphore signal ] bypass: true.
	semaphore waitTimeoutMilliseconds: 100.
	elapsed := Time millisecondClockValue - start.

	self assert: elapsed < debouncer delayMilliseconds
]
