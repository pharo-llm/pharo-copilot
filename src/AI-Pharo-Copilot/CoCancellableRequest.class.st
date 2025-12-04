Class {
	#name : 'CoCancellableRequest',
	#superclass : 'Object',
	#instVars : [
		'id',
		'process',
		'cancelled',
		'contextInfo'
	],
	#classInstVars : [
		'NextId'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'accessing' }
CoCancellableRequest class >> nextId [

        NextId ifNil: [ NextId := 0 ].
        NextId := NextId + 1.
        ^ NextId
]

{ #category : 'accessing' }
CoCancellableRequest class >> withContext: aDictionary [

        ^ self new
                contextInfo: aDictionary;
                yourself
]

{ #category : 'evaluating' }
CoCancellableRequest >> cancelWithReason: aString [

        cancelled ifTrue: [ ^ self ].
        cancelled := true.
        process ifNotNil: [ process terminate ].
        CoCopilotLogger
                logBackEndEvent: 'Cancelled completion request'
                details: (Dictionary new
                                         at: #requestId put: self id;
                                         at: #reason put: (aString ifNil: [ 'unspecified' ]);
                                         at: #requestContext put: (self contextInfo ifNil: [ Dictionary new ]);
                                         yourself).
        CoCancellableRequestRegistry remove: self
]

{ #category : 'evaluating' }
CoCancellableRequest >> cancelled [

        ^ cancelled = true
]

{ #category : 'evaluating' }
CoCancellableRequest >> contextInfo [

        ^ contextInfo ifNil: [ Dictionary new ]
]

{ #category : 'evaluating' }
CoCancellableRequest >> contextInfo: aDictionary [

        contextInfo := aDictionary ifNil: [ Dictionary new ] ifNotNil: [ aDictionary ]
]

{ #category : 'evaluating' }
CoCancellableRequest >> id [

        ^ id
]

{ #category : 'evaluating' }
CoCancellableRequest >> initialize [

        super initialize.
        id := self class nextId.
        cancelled := false.
        contextInfo := Dictionary new.
        process := nil
]

{ #category : 'evaluating' }
CoCancellableRequest >> process [

        ^ process
]

{ #category : 'evaluating' }
CoCancellableRequest >> process: aProcess [

        process := aProcess
]

{ #category : 'evaluating' }
CoCancellableRequest >> registerCompletion [

        CoCancellableRequestRegistry remove: self
]
