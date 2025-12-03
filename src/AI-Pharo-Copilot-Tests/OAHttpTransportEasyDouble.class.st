Class {
	#name : 'OAHttpTransportEasyDouble',
	#superclass : 'Object',
	#classInstVars : [
		'client'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
OAHttpTransportEasyDouble class >> client [
        client ifNil: [ client := OAHttpTransportClientDouble new ].
        ^ client
]

{ #category : 'class initialization' }
OAHttpTransportEasyDouble class >> reset [
<script>
        client := nil.
        OAHttpTransportClientDouble reset
]
