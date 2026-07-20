"
Optional remote telemetry sender for Pharo-Copilot.

Telemetry is disabled by default and is only sent after the user explicitly
accepts data sharing in the setup flow. Payloads intentionally avoid source
code, prompts and generated completions.
"
Class {
	#name : 'CoPharoCopilotTelemetry',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'private' }
CoPharoCopilotTelemetry class >> categoryFieldValue [

	| metadata |
	metadata := Dictionary new.
	metadata at: 'category' put: CopilotSettings dataSharingCategory.
	metadata at: 'experienceId' put: CopilotSettings dataSharingExperienceId.
	metadata at: 'participantUUID' put: CopilotSettings dataSharingParticipantUUID.
	metadata at: 'taskOrSurveyId' put: CopilotSettings dataSharingTaskOrSurveyId.
	^ STON toString: metadata
]

{ #category : 'private' }
CoPharoCopilotTelemetry class >> logDeliveryFailure: ex event: eventName [

	CoPharoCopilotLogger
		logBackEndEvent: 'Telemetry delivery failed'
		details: (Dictionary new
			at: #event put: eventName;
			at: #errorClass put: ex class name;
			at: #error put: ex description;
			yourself)
]

{ #category : 'payloads' }
CoPharoCopilotTelemetry class >> payloadForEvent: eventName details: detailsDictionary [

	^ Dictionary new
		at: #schema put: 'pharo-copilot-telemetry-v1';
		at: #event put: eventName asString;
		at: #timestamp put: DateAndTime now asString;
		at: #modelName put: CopilotSettings modelName;
		at: #provider put: CopilotSettings copilotProvider asString;
		at: #pharoVersion put: self pharoVersionString;
		at: #details put: (detailsDictionary ifNil: [ Dictionary new ]);
		yourself
]

{ #category : 'private' }
CoPharoCopilotTelemetry class >> pharoVersionString [

	| systemVersion |
	systemVersion := Smalltalk globals at: #SystemVersion ifAbsent: [ nil ].
	systemVersion ifNil: [ ^ 'unknown' ].
	^ [ systemVersion current version asString ]
		on: Error
		do: [ :ignored | 'unknown' ]
]

{ #category : 'recording' }
CoPharoCopilotTelemetry class >> recordEvent: eventName details: detailsDictionary [

	CopilotSettings dataSharingEnabled ifFalse: [ ^ self ].

	[
		[
			self sendPayload:
				(self payloadForEvent: eventName details: detailsDictionary)
		] on: Error do: [ :ex |
			self logDeliveryFailure: ex event: eventName ]
	] forkAt: Processor userBackgroundPriority named: 'Pharo-Copilot telemetry delivery'
]

{ #category : 'recording' }
CoPharoCopilotTelemetry class >> recordSetupCompleted [

	self
		recordEvent: 'setup-completed'
		details: (Dictionary new
			at: #completionModel put: CopilotSettings modelName;
			at: #endpointUrl put: CopilotSettings dataSharingEndpointUrl;
			yourself)
]

{ #category : 'sending' }
CoPharoCopilotTelemetry class >> sendPayload: payloadDictionary [

	| endpoint bytes client success |
	endpoint := CopilotSettings dataSharingEndpointUrl.
	(endpoint isNil or: [ endpoint asString trimBoth isEmpty ]) ifTrue: [ ^ false ].

	bytes := self serializePayload: payloadDictionary.

	client := ZnEasy client.
	success := false.
	(client respondsTo: #timeout:) ifTrue: [ client timeout: 5 ].

	[
		client
			url: endpoint asZnUrl;
			addPart: (ZnMimePart
				fieldName: 'category'
				value: self categoryFieldValue);
			addPart: (ZnMimePart
				fieldName: 'data'
				entity: (ZnByteArrayEntity
					with: bytes
					type: 'application/octet-stream' asZnMimeType)).
		client put.
		success := (client respondsTo: #isSuccess)
			ifTrue: [ client isSuccess ]
			ifFalse: [ true ]
	] ensure: [
		[ client close ] on: Error do: [ :ignored | ] ].

	^ success
]

{ #category : 'private' }
CoPharoCopilotTelemetry class >> serializePayload: payloadDictionary [

	| string |
	string := STONJSON toString: payloadDictionary.
	^ [ string utf8Encoded ]
		on: Error
		do: [ :ignored | string asByteArray ]
]
