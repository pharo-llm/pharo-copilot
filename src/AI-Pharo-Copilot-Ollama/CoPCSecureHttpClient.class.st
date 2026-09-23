"HTTPS client that validates the TLS peer before sending code or credentials."
Class {
	#name : 'CoPCSecureHttpClient',
	#superclass : 'ZnClient',
	#category : 'AI-Pharo-Copilot-Ollama',
	#package : 'AI-Pharo-Copilot-Ollama'
}

{ #category : 'private' }
CoPCSecureHttpClient >> setupTLSTo: url [
	| session peer |
	super setupTLSTo: url.
	session := self connection sslSession.
	peer := session peerCertificateName.
	(session certificateVerificationState = 0 and: [
		peer notNil and: [ peer asLowercase = url host asLowercase ] ]) ifFalse: [
		self close.
		self error: 'Private server TLS certificate validation failed' ]
]
