"
Utility class that debounces expensive operations (like completion fetches)
to avoid issuing multiple API calls while the user is still typing.
"
Class {
	#name : 'CoCompletionDebouncer',
	#superclass : 'Object',
	#instVars : [
		'delayMilliseconds',
		'pendingProcess'
	],
	#classVars : [
		'DefaultDelayMilliseconds'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'as yet unclassified' }
CoCompletionDebouncer class >> defaultDelayMilliseconds [

    ^ DefaultDelayMilliseconds ifNil: [ DefaultDelayMilliseconds := 150 ]
]

{ #category : 'as yet unclassified' }
CoCompletionDebouncer class >> defaultDelayMilliseconds: aNumber [

    DefaultDelayMilliseconds := aNumber
]

{ #category : 'accessing' }
CoCompletionDebouncer >> cancelPending [

    pendingProcess ifNotNil: [
        pendingProcess terminate.
        pendingProcess := nil ]
]

{ #category : 'accessing' }
CoCompletionDebouncer >> delayMilliseconds [

    ^ delayMilliseconds
]

{ #category : 'accessing' }
CoCompletionDebouncer >> delayMilliseconds: aNumber [

    delayMilliseconds := (aNumber ifNil: [ self class defaultDelayMilliseconds ]) max: 0
]

{ #category : 'accessing' }
CoCompletionDebouncer >> initialize [

    super initialize.
    delayMilliseconds := self class defaultDelayMilliseconds.
    pendingProcess := nil
]

{ #category : 'accessing' }
CoCompletionDebouncer >> isPending [

    ^ pendingProcess notNil
]

{ #category : 'accessing' }
CoCompletionDebouncer >> performImmediately: aBlock [

    self cancelPending.
    ^ aBlock value
]

{ #category : 'accessing' }
CoCompletionDebouncer >> schedule: aBlock [

    ^ self schedule: aBlock bypass: false
]

{ #category : 'accessing' }
CoCompletionDebouncer >> schedule: aBlock bypass: bypassDebounce [

    bypassDebounce ifTrue: [ ^ self performImmediately: aBlock ].
    self cancelPending.
    pendingProcess := [
        (Delay forMilliseconds: self delayMilliseconds) wait.
        aBlock value
    ] ensure: [ pendingProcess := nil ].

    pendingProcess := (pendingProcess respondsTo: #forkAt:)
            ifTrue: [ pendingProcess forkAt: Processor userBackgroundPriority ]
            ifFalse: [ pendingProcess fork ].
    ^ pendingProcess
]
