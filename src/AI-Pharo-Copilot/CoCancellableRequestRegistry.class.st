Class {
	#name : 'CoCancellableRequestRegistry',
	#superclass : 'Object',
	#classInstVars : [
		'ActiveRequests'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'as yet unclassified' }
CoCancellableRequestRegistry class >> activeRequestCount [

        ^ self activeRequests size
]

{ #category : 'as yet unclassified' }
CoCancellableRequestRegistry class >> activeRequests [

        ActiveRequests ifNil: [ ActiveRequests := IdentitySet new ].
        ^ ActiveRequests
]

{ #category : 'as yet unclassified' }
CoCancellableRequestRegistry class >> cancelAllActiveRequests [

        self activeRequests copy do: [ :request | request cancelWithReason: 'Superseded by new request' ].
        ActiveRequests := IdentitySet new
]

{ #category : 'as yet unclassified' }
CoCancellableRequestRegistry class >> register: aCancellableRequest [

        self activeRequests add: aCancellableRequest.
        ^ aCancellableRequest
]

{ #category : 'as yet unclassified' }
CoCancellableRequestRegistry class >> remove: aCancellableRequest [

        self activeRequests remove: aCancellableRequest ifAbsent: [ ].
        ^ aCancellableRequest
]

{ #category : 'as yet unclassified' }
CoCancellableRequestRegistry class >> reset [
		<script>
        ActiveRequests := IdentitySet new
]
