"
Represents an asynchronous request that can be cancelled.
Tracks all active requests globally and logs lifecycle events for debugging.
"
Class {
	#name : 'CoCancellableRequest',
	#superclass : 'Object',
	#instVars : [
		'identifier',
		'process',
		'cancelled',
		'label'
	],
	#classInstVars : [
		'activeRequests'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'accessing' }
CoCancellableRequest class >> activeRequests [

        ^ activeRequests ifNil: [ activeRequests := IdentitySet new ]
]

{ #category : 'accessing' }
CoCancellableRequest class >> activeRequestsSnapshot [

        ^ self activeRequests copy
]

{ #category : 'accessing' }
CoCancellableRequest class >> cancelAll [
		<script>

        self cancelAllLabeled: nil

]

{ #category : 'accessing' }
CoCancellableRequest class >> cancelAllLabeled: aLabelString [

        "Cancel every tracked request matching the given label. If the label is nil,
        cancel everything."

        (self activeRequests copy) do: [ :request |
                (aLabelString isNil or: [ request label = aLabelString ])
                        ifTrue: [ request cancel ] ]
]

{ #category : 'accessing' }
CoCancellableRequest class >> register: aRequest [

        self activeRequests add: aRequest
]

{ #category : 'accessing' }
CoCancellableRequest class >> startNamed: aLabelString priority: aPriority running: aBlockClosure [

        | request |
        request := self new.
        ^ request
                startNamed: aLabelString
                priority: aPriority
                running: aBlockClosure
]

{ #category : 'accessing' }
CoCancellableRequest class >> startNamed: aLabelString running: aBlockClosure [

        ^ self
                startNamed: aLabelString
                priority: Processor userBackgroundPriority
                running: aBlockClosure
]

{ #category : 'accessing' }
CoCancellableRequest class >> unregister: aRequest [ 
        self activeRequests remove: aRequest ifAbsent: [ ]
]

{ #category : 'accessing' }
CoCancellableRequest class >> unregisterAll [

        self activeRequests copy do: [ :request | self unregister: request ]
]

{ #category : 'actions' }
CoCancellableRequest >> cancel [

        cancelled ifTrue: [ ^ self ].
        cancelled := true.
        process ifNotNil: [ process isTerminated ifFalse: [ process terminate ] ].
        self class unregister: self.
        CoCopilotLogger logFrontEndEvent: 'Cancelled request' details: (Dictionary new
                                 at: #requestId put: self identifier;
                                 at: #label put: label;
                                 yourself)
]

{ #category : 'actions' }
CoCancellableRequest >> identifier [

        ^ identifier
]

{ #category : 'initialization' }
CoCancellableRequest >> ifCancelled: aBlock [

        self isCancelled ifTrue: [ aBlock value. ^ true ].
        ^ false
]

{ #category : 'initialization' }
CoCancellableRequest >> initialize [

        super initialize.
        identifier := UUID new asString.
        cancelled := false
]

{ #category : 'initialization' }
CoCancellableRequest >> isCancelled [

        ^ cancelled = true
]

{ #category : 'initialization' }
CoCancellableRequest >> label [

        ^ label ifNil: [ 'request' ]
]

{ #category : 'initialization' }
CoCancellableRequest >> markFinished [ 

        self class unregister: self.
        self isCancelled
                ifFalse: [
                        CoCopilotLogger logFrontEndEvent: 'Completed request' details: (Dictionary new
                                                 at: #requestId put: self identifier;
                                                 at: #label put: self label;
                                                 yourself) ]
]

{ #category : 'initialization' }
CoCancellableRequest >> startNamed: aLabelString priority: aPriority running: aBlockClosure [

        label := aLabelString.
        self class register: self.
        CoCopilotLogger logFrontEndEvent: 'Started cancellable request' details: (Dictionary new
                                 at: #requestId put: self identifier;
                                 at: #label put: self label;
                                 at: #priority put: aPriority;
                                 yourself).
        process := [ [ aBlockClosure value: self ] ensure: [ self markFinished ] ]
                           forkAt: aPriority.
        ^ self
]
