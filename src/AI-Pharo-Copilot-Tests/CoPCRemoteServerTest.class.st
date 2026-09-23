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
