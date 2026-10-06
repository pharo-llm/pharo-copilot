"One remote credential belongs to one running image. Never serialize this identity as a setting."
Class {
	#name : 'CoPCRemoteSession',
	#superclass : 'Object',
	#classInstVars : [ 'identifier', 'heartbeatProcess' ],
	#category : 'AI-Pharo-Copilot-Ollama',
	#package : 'AI-Pharo-Copilot-Ollama'
}

{ #category : 'accessing' }
CoPCRemoteSession class >> identifier [
	identifier ifNil: [ identifier := UUID new asString ].
	self ensureHeartbeat.
	^ identifier
]

{ #category : 'private' }
CoPCRemoteSession class >> ensureHeartbeat [
	heartbeatProcess ifNotNil: [
		heartbeatProcess isTerminated ifFalse: [ ^ self ].
		heartbeatProcess := nil ].
	heartbeatProcess := [
		[ CopilotSettings remoteEnabled ] whileTrue: [
			(Delay forSeconds: 30) wait.
			CopilotSettings remoteEnabled ifTrue: [
				[ CoPCOAHttpTransport new
					postJsonAt: 'api/session/heartbeat' body: Dictionary new timeoutSeconds: 5 ]
					on: Error do: [ :ignored | ] ] ]
	] newProcess.
	heartbeatProcess priority: Processor userBackgroundPriority.
	heartbeatProcess resume
]

{ #category : 'session management' }
CoPCRemoteSession class >> close [
	"The caller uploads the final archive before retiring the credential."
	heartbeatProcess ifNotNil: [ heartbeatProcess terminate ].
	[ (CopilotSettings remoteEnabled and: [ identifier notNil ]) ifTrue: [
		[ CoPCOAHttpTransport new
			postJsonAt: 'api/session/close' body: Dictionary new timeoutSeconds: 5 ]
			on: Error do: [ :ignored | ] ]
	] ensure: [ self reset ]
]

{ #category : 'session management' }
CoPCRemoteSession class >> reset [
	heartbeatProcess ifNotNil: [ heartbeatProcess terminate ].
	heartbeatProcess := nil.
	identifier := nil
]

{ #category : 'class initialization' }
CoPCRemoteSession class >> initialize [
	self registerSessionHandler
]

{ #category : 'session management' }
CoPCRemoteSession class >> registerSessionHandler [
	"Start before, and shut down after, the survey and telemetry handlers."
	SessionManager default
		registerUserClassNamed: self name
		atPriority: SessionManager default defaultPriority - 10
]

{ #category : 'session management' }
CoPCRemoteSession class >> startUp: isImageStarting [
	isImageStarting ifTrue: [ self reset ]
]

{ #category : 'session management' }
CoPCRemoteSession class >> shutDown: isImageQuitting [
	isImageQuitting ifTrue: [ self close ]
]
