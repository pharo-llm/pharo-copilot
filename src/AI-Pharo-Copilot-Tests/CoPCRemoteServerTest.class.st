Class {
	#name : 'CoPCRemoteServerTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
CoPCRemoteServerTest >> testRemoteModeNeverLaunchesOrInstallsModels [
	CopilotSettings withDefaultSettingsDo: [
		| snapshot |
		snapshot := CopilotSettings settingsSnapshot.
		snapshot at: #remoteEnabled put: true.
		CopilotSettings restoreSettingsFromSnapshot: snapshot.
		self deny: CopilotSettings launchLocalOllamaServiceSilentlyIfPossible.
		self deny: (CopilotSettings installModelNamed: 'anything').
		self deny: (CopilotSettings installModelNamedForSetup: 'anything' progress: nil).
		self should: [ CoPCOAHttpTransport new
			postStreamingAt: 'api/pull' body: Dictionary new
			timeoutSeconds: 1 linesDo: [ :line | ] ] raise: Error ]
]

{ #category : 'tests' }
CoPCRemoteServerTest >> testRejectsURLsInsteadOfHostnames [
	self should: [ CopilotSettings
		useRemoteServer: 'http://example.org' tokenFile: '/missing' ] raise: Error.
	self should: [ CopilotSettings
		useRemoteServer: 'example.org/redirect' tokenFile: '/missing' ] raise: Error
]

{ #category : 'tests' }
CoPCRemoteServerTest >> testRemoteModeSurvivesSettingsRoundTrip [
	CopilotSettings withDefaultSettingsDo: [
		| snapshot |
		snapshot := CopilotSettings serializableSettingsSnapshot.
		snapshot at: #remoteEnabled put: true.
		snapshot at: #remoteTokenFile put: '/private/credential'.
		CopilotSettings restoreSettingsFromSerializableSnapshot: snapshot.
		self assert: CopilotSettings remoteEnabled.
		self assert: (CopilotSettings serializableSettingsSnapshot at: #remoteTokenFile)
			equals: '/private/credential'.
		self deny: (CopilotSettings serializableSettingsSnapshot includesKey: #remoteAccessToken) ]
]

{ #category : 'tests' }
CoPCRemoteServerTest >> testAutomaticSetupEnablesCompletionWhenServerHasModel [
	CopilotSettings withDefaultSettingsDo: [
		| snapshot client |
		snapshot := CopilotSettings settingsSnapshot.
		snapshot at: #remoteEnabled put: true; at: #enabled put: false.
		CopilotSettings restoreSettingsFromSnapshot: snapshot.
		client := OllamaClientStub new.
		CopilotSettings ollamaClientFactory: [ client ].
		self assert: CopilotSettings activateHostedCompletion.
		self assert: CopilotSettings copilotEnabled.
		self assert: client pullCount equals: 0 ]
]

{ #category : 'tests' }
CoPCRemoteServerTest >> testAutomaticSetupDoesNotEnableCompletionWhenModelIsMissing [
	CopilotSettings withDefaultSettingsDo: [
		| snapshot client |
		snapshot := CopilotSettings settingsSnapshot.
		snapshot at: #remoteEnabled put: true; at: #enabled put: false.
		CopilotSettings restoreSettingsFromSnapshot: snapshot.
		client := OllamaClientStub new
			withModelsResponse: (Dictionary new at: #models put: #(); yourself).
		CopilotSettings ollamaClientFactory: [ client ].
		self deny: CopilotSettings activateHostedCompletion.
		self deny: CopilotSettings copilotEnabled.
		self assert: client pullCount equals: 0 ]
]

{ #category : 'tests' }
CoPCRemoteServerTest >> testRemoteUploadsUseCompletionHostOnly [
	CopilotSettings withDefaultSettingsDo: [
		| snapshot |
		snapshot := CopilotSettings settingsSnapshot.
		snapshot at: #remoteEnabled put: true;
			at: #remoteSecure put: false;
			at: #host put: 'copilot.example.org';
			at: #port put: 8080.
		CopilotSettings restoreSettingsFromSnapshot: snapshot.
		self assert: CoPCSessionArchiveUploader uploadUrl
			equals: 'http://copilot.example.org:8080/api/sessions'.
		self assert: CoPCSessionArchiveUploader candidateUploadUrlsForAuthorization
			equals: { 'http://copilot.example.org:8080/api/sessions' }.
		self assert: CoPCSessionArchiveUploader telemetrySummaryUploadUrl
			equals: 'http://copilot.example.org:8080/api/session-telemetry' ]
]

{ #category : 'tests' }
CoPCRemoteServerTest >> testRemoteRequestPreservesPathAndPortForBothSchemes [
	CopilotSettings withDefaultSettingsDo: [
		| credential snapshot |
		credential := FileLocator temp / UUID new asString.
		credential writeStreamDo: [ :stream | stream nextPutAll: (String new: 40 withAll: $a) ].
		[
			#(true false) do: [ :secure |
				snapshot := CopilotSettings settingsSnapshot.
				snapshot at: #remoteEnabled put: true;
					at: #remoteSecure put: secure;
					at: #remoteTokenFile put: credential fullName;
					at: #host put: 'example.org'; at: #port put: 8080.
				CopilotSettings restoreSettingsFromSnapshot: snapshot.
				#('api/tags' 'api/show' 'api/generate' 'api/session/heartbeat' 'api/session/close') do: [ :path |
					| client |
					client := CoPCOAHttpTransport new newJsonClientForPath: path.
					self assert: client request url asString equals:
						((secure ifTrue: [ 'https://' ] ifFalse: [ 'http://' ]), 'example.org:8080/', path).
					self assert: (client request headers at: 'X-Copilot-Session') equals: CoPCRemoteSession identifier ] ]
		] ensure: [ CoPCRemoteSession reset. credential ensureDelete ] ]
]

{ #category : 'tests' }
CoPCRemoteServerTest >> testImageRestartChangesRemoteSessionIdentity [
	| previous |
	[ previous := CoPCRemoteSession identifier.
	  CoPCRemoteSession reset.
	  self deny: CoPCRemoteSession identifier equals: previous
	] ensure: [ CoPCRemoteSession reset ]
]

{ #category : 'tests' }
CoPCRemoteServerTest >> testSavingWithoutQuittingKeepsSession [
	| previous |
	[ previous := CoPCRemoteSession identifier.
	  CoPCRemoteSession shutDown: false.
	  CoPCRemoteSession startUp: false.
	  self assert: CoPCRemoteSession identifier equals: previous.
	  CoPCRemoteSession startUp: true.
	  self deny: CoPCRemoteSession identifier equals: previous
	] ensure: [ CoPCRemoteSession reset ]
]

{ #category : 'tests' }
CoPCRemoteServerTest >> testHttpFailureMessagesDistinguishRoutingAndAccess [
	CopilotSettings recordRemoteConnectionFailure:
		(ZnHttpUnsuccessful new response: (ZnResponse notFound: '/'); yourself).
	self assert: (CopilotSettings remoteConnectionFailure includesSubstring: 'HTTP 404').
	self deny: (CopilotSettings remoteConnectionFailure includesSubstring: 'expired')
]
