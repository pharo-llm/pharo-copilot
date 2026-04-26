"
Central configuration for Pharo Copilot with an Ollama backend.

Settings are stored on a singleton instance so System Settings writes update
real instance-side state. Class-side accessors remain as compatibility proxies.
"
Class {
	#name : 'CopilotSettings',
	#superclass : 'Object',
	#instVars : [
		'enabled',
		'provider',
		'modelName',
		'host',
		'port',
		'autoInstallModelScriptEnabled',
		'loggingEnabled',
		'templatesDirectory',
		'completionDebounceMilliseconds',
		'completionIdleMilliseconds',
		'requestTimeoutSeconds',
		'modelInstallTimeoutSeconds',
		'temperature',
		'topP',
		'topK',
		'numPredict',
		'repeatPenalty',
		'numCtx',
		'seed',
		'customParameters',
		'maxInstanceMethods',
		'maxClassMethods',
		'minimumPrefixLength',
		'completionSuggestionsCount',
		'backgroundColor',
		'installModelUserConsent'
	],
	#classInstVars : [
		'modelMetadata',
		'ollamaClientFactory',
		'current'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}
{ #category : 'accessing' }
CopilotSettings class >> current [

	current ifNil: [
		current := self new.
		current initializeDefaults ].
	^ current
]

{ #category : 'accessing' }
CopilotSettings class >> resetCurrent [

	current := self new.
	current initializeDefaults.
	modelMetadata := nil
]

{ #category : 'accessing' }
CopilotSettings class >> initialize [

	super initialize.
	self resetCurrent.
	ollamaClientFactory := [ CoPCOllamaClient new ].
	self loadSettingsFromFile
]

{ #category : 'settings' }
CopilotSettings class >> initializeDefaults [

	self resetCurrent.
	ollamaClientFactory := [ CoPCOllamaClient new ].
	modelMetadata := nil
]

{ #category : 'settings' }
CopilotSettings class >> loadSettingsFromFile [

	"Legacy hook kept for compatibility during class initialization.
	Settings are now managed through the singleton instance and System Settings."
]

{ #category : 'accessing' }
CopilotSettings class >> copilotEnabled [

	^ self current copilotEnabled
]

{ #category : 'accessing' }
CopilotSettings class >> copilotEnabled: aBoolean [

	self current copilotEnabled: aBoolean
]

{ #category : 'accessing' }
CopilotSettings class >> copilotProvider [

	^ self current copilotProvider
]

{ #category : 'accessing' }
CopilotSettings class >> copilotProvider: aSymbol [

	self current copilotProvider: aSymbol
]

{ #category : 'accessing' }
CopilotSettings class >> modelName [

	^ self current modelName
]

{ #category : 'accessing' }
CopilotSettings class >> modelName: aString [

	self current modelName: aString.
	self clearCachedModelMetadata
]

{ #category : 'accessing' }
CopilotSettings class >> host [

	^ self current host
]

{ #category : 'accessing' }
CopilotSettings class >> host: aString [

	self current host: aString.
	self clearCachedModelMetadata
]

{ #category : 'accessing' }
CopilotSettings class >> port [

	^ self current port
]

{ #category : 'accessing' }
CopilotSettings class >> port: aNumberOrString [

	self current port: aNumberOrString.
	self clearCachedModelMetadata
]

{ #category : 'accessing' }
CopilotSettings class >> autoInstallModelScriptEnabled [

	^ self current autoInstallModelScriptEnabled
]

{ #category : 'accessing' }
CopilotSettings class >> autoInstallModelScriptEnabled: aBoolean [

	self current autoInstallModelScriptEnabled: aBoolean
]

{ #category : 'accessing' }
CopilotSettings class >> loggingEnabled [

	^ self current loggingEnabled
]

{ #category : 'accessing' }
CopilotSettings class >> loggingEnabled: aBoolean [

	self current loggingEnabled: aBoolean
]

{ #category : 'accessing' }
CopilotSettings class >> backgroundColor [

	^ self current backgroundColor
]

{ #category : 'accessing' }
CopilotSettings class >> backgroundColor: aColor [

	self current backgroundColor: aColor
]

{ #category : 'accessing' }
CopilotSettings class >> defaultBackgroundColor [

	^ Color veryVeryLightGray
]

{ #category : 'accessing' }
CopilotSettings class >> templatesDirectory [

	^ self current templatesDirectory
]

{ #category : 'accessing' }
CopilotSettings class >> templatesDirectory: aFileReference [

	self current templatesDirectory: aFileReference
]
{ #category : 'settings' }
CopilotSettings class >> completionDebounceMilliseconds [

	^ self current completionDebounceMilliseconds
]

{ #category : 'settings' }
CopilotSettings class >> completionDebounceMilliseconds: anObject [

	self current completionDebounceMilliseconds: anObject
]

{ #category : 'settings' }
CopilotSettings class >> completionIdleMilliseconds [

	^ self current completionIdleMilliseconds
]

{ #category : 'settings' }
CopilotSettings class >> completionIdleMilliseconds: anObject [

	self current completionIdleMilliseconds: anObject
]

{ #category : 'settings' }
CopilotSettings class >> requestTimeoutSeconds [

	^ self current requestTimeoutSeconds
]

{ #category : 'settings' }
CopilotSettings class >> requestTimeoutSeconds: anObject [

	self current requestTimeoutSeconds: anObject
]

{ #category : 'accessing' }
CopilotSettings class >> modelInstallTimeoutSeconds [

	^ self current modelInstallTimeoutSeconds
]

{ #category : 'accessing' }
CopilotSettings class >> modelInstallTimeoutSeconds: anObject [

	self current modelInstallTimeoutSeconds: anObject
]

{ #category : 'settings' }
CopilotSettings class >> completionSuggestionsCount [

	^ self current completionSuggestionsCount
]

{ #category : 'settings' }
CopilotSettings class >> completionSuggestionsCount: anObject [

	self current completionSuggestionsCount: anObject
]
{ #category : 'context' }
CopilotSettings class >> maxInstanceMethods [

	^ self current maxInstanceMethods
]

{ #category : 'context' }
CopilotSettings class >> maxInstanceMethods: anObject [

	self current maxInstanceMethods: anObject
]

{ #category : 'context' }
CopilotSettings class >> maxClassMethods [

	^ self current maxClassMethods
]

{ #category : 'context' }
CopilotSettings class >> maxClassMethods: anObject [

	self current maxClassMethods: anObject
]

{ #category : 'context' }
CopilotSettings class >> minimumPrefixLength [

	^ self current minimumPrefixLength
]

{ #category : 'context' }
CopilotSettings class >> minimumPrefixLength: anObject [

	self current minimumPrefixLength: anObject
]
{ #category : 'ollama' }
CopilotSettings class >> temperature [

	^ self current temperature
]

{ #category : 'ollama' }
CopilotSettings class >> temperature: aNumber [

	self current temperature: aNumber
]

{ #category : 'ollama' }
CopilotSettings class >> topP [

	^ self current topP
]

{ #category : 'ollama' }
CopilotSettings class >> topP: aNumber [

	self current topP: aNumber
]

{ #category : 'ollama' }
CopilotSettings class >> topK [

	^ self current topK
]

{ #category : 'ollama' }
CopilotSettings class >> topK: anInteger [

	self current topK: anInteger
]

{ #category : 'ollama' }
CopilotSettings class >> numPredict [

	^ self current numPredict
]

{ #category : 'ollama' }
CopilotSettings class >> numPredict: anInteger [

	self current numPredict: anInteger
]

{ #category : 'ollama' }
CopilotSettings class >> repeatPenalty [

	^ self current repeatPenalty
]

{ #category : 'ollama' }
CopilotSettings class >> repeatPenalty: aNumber [

	self current repeatPenalty: aNumber
]

{ #category : 'ollama' }
CopilotSettings class >> numCtx [

	^ self current numCtx
]

{ #category : 'ollama' }
CopilotSettings class >> numCtx: anIntegerOrNil [

	self current numCtx: anIntegerOrNil
]

{ #category : 'ollama' }
CopilotSettings class >> seed [

	^ self current seed
]

{ #category : 'ollama' }
CopilotSettings class >> seed: anIntegerOrNil [

	self current seed: anIntegerOrNil
]

{ #category : 'ollama' }
CopilotSettings class >> customParameters [

	^ self current customParameters
]

{ #category : 'ollama' }
CopilotSettings class >> customParameters: aDictionary [

	self current customParameters: aDictionary
]
{ #category : 'accessing' }
CopilotSettings class >> allOllamaOptions [

	| options parameters |
	options := Dictionary new.

	(self temperature notNil and: [ self temperature ~= 0.8 ])
		ifTrue: [ options at: #temperature put: self temperature ].
	(self topP notNil and: [ self topP ~= 0.9 ])
		ifTrue: [ options at: #top_p put: self topP ].
	(self topK notNil and: [ self topK ~= 40 ])
		ifTrue: [ options at: #top_k put: self topK ].
	(self numPredict notNil and: [ self numPredict ~= 128 ])
		ifTrue: [ options at: #num_predict put: self numPredict ].
	(self repeatPenalty notNil and: [ self repeatPenalty ~= 1.1 ])
		ifTrue: [ options at: #repeat_penalty put: self repeatPenalty ].
	(self numCtx notNil and: [ self numCtx ~= 2048 ])
		ifTrue: [ options at: #num_ctx put: self numCtx ].
	(self seed notNil and: [ self seed ~= 0 ])
		ifTrue: [ options at: #seed put: self seed ].

	parameters := self customParameters.
	(parameters notNil and: [ parameters isEmpty not ]) ifTrue: [
		parameters keysAndValuesDo: [ :key :value |
			options at: key put: value ] ].

	^ options
]

{ #category : 'ollama' }
CopilotSettings class >> setCustomParameter: aKey value: aValue [

	self customParameters at: aKey put: aValue.
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> installModelUserConsent [

	^ self current installModelUserConsent
]

{ #category : 'accessing' }
CopilotSettings class >> installModelUserConsent: anObject [

	self current installModelUserConsent: anObject
]
{ #category : 'persistence' }
CopilotSettings class >> serializableSettingsSnapshot [

	| snapshot templatesPath contextSettingsClass |
	contextSettingsClass := Smalltalk globals at: #CoPCContextSettings ifAbsent: [ nil ].
		at: #enabled put: self copilotEnabled;
		at: #provider put: self copilotProvider;
		at: #modelName put: self modelName;
		at: #host put: self host;
		at: #port put: self port;
		at: #autoInstallModelScriptEnabled put: self autoInstallModelScriptEnabled;
		at: #loggingEnabled put: self loggingEnabled;
		at: #completionDebounceMilliseconds put: self completionDebounceMilliseconds;
		at: #completionIdleMilliseconds put: self completionIdleMilliseconds;
		at: #requestTimeoutSeconds put: self requestTimeoutSeconds;
		at: #modelInstallTimeoutSeconds put: self modelInstallTimeoutSeconds;
		at: #temperature put: self temperature;
		at: #topP put: self topP;
		at: #topK put: self topK;
		at: #numPredict put: self numPredict;
		at: #repeatPenalty put: self repeatPenalty;
		at: #numCtx put: self numCtx;
		at: #seed put: self seed;
		at: #customParameters put: self customParameters;
		at: #maxInstanceMethods put: self maxInstanceMethods;
		at: #maxClassMethods put: self maxClassMethods;
		at: #minimumPrefixLength put: self minimumPrefixLength;
		at: #completionSuggestionsCount put: self completionSuggestionsCount;
		at: #backgroundColor put: self backgroundColor;
		at: #installModelUserConsent put: self installModelUserConsent;
		at: #contextMode put: (contextSettingsClass ifNotNil: [ contextSettingsClass mode ]);
		at: #navigationHistoryEnabled put: CoPCContextNavigationHistory enabled;
		yourself.

	self templatesDirectory ifNotNil: [
		templatesPath := [ self templatesDirectory pathString ]
			on: Error
			do: [ nil ].
		templatesPath ifNotNil: [
			snapshot at: #templatesDirectory put: templatesPath ] ].

	^ snapshot
]

{ #category : 'persistence' }
CopilotSettings class >> restoreSettingsFromSerializableSnapshot: aDictionary [

	| contextSettingsClass |
	self resetCurrent.
	self current restoreSettingsFromSerializableSnapshot: aDictionary.
	contextSettingsClass := Smalltalk globals at: #CoPCContextSettings ifAbsent: [ nil ].

	(aDictionary at: #contextMode ifAbsent: [ nil ])
		ifNotNil: [ :savedMode | contextSettingsClass ifNotNil: [ contextSettingsClass mode: savedMode ] ].

	(aDictionary at: #navigationHistoryEnabled ifAbsent: [ nil ])
		ifNotNil: [ :savedFlag | CoPCContextNavigationHistory enabled: savedFlag ]
]

{ #category : 'accessing' }
CopilotSettings class >> settingsSnapshot [

	^ self serializableSettingsSnapshot
]

{ #category : 'accessing' }
CopilotSettings class >> restoreSettingsFromSnapshot: aDictionary [

	self restoreSettingsFromSerializableSnapshot: aDictionary
]
{ #category : 'ui' }
CopilotSettings class >> settingsOn: aBuilder [

	<systemsettings>
	| contextSettingsClass |
	contextSettingsClass := Smalltalk globals at: #CoPCContextSettings ifAbsent: [ nil ].
	(aBuilder setting: #CopilotSettings)
		target: self current;
		parentName: #codeBrowsing;
		selector: #copilotEnabled;
		default: true;
		iconName: #smallConfiguration;
		label: 'Copilot';
		description: 'Configure Pharo Copilot AI completion settings.';
		with: [
			(aBuilder pickOne: #provider)
				order: -1;
				label: 'Provider';
				target: self current;
				getSelector: #copilotProvider;
				setSelector: #copilotProvider:;
				domainValues: self availableProviders.

			(aBuilder pickOne: #modelName)
				label: 'Model';
				target: self current;
				getSelector: #modelName;
				setSelector: #modelName:;
				default: self modelName;
				domainValues: self availableModelNames.

			(aBuilder setting: #loggingEnabled)
				order: 0.3;
				label: 'Enable logging';
				target: self current;
				getSelector: #loggingEnabled;
				setSelector: #loggingEnabled:;
				default: self loggingEnabled;
				description: 'When disabled, Copilot will not record activity or evaluation logs.'.

			(aBuilder setting: #autoInstallModelScriptEnabled)
				order: 0.4;
				label: 'Auto-install Pharo coder model';
				target: self current;
				getSelector: #autoInstallModelScriptEnabled;
				setSelector: #autoInstallModelScriptEnabled:;
				default: self autoInstallModelScriptEnabled;
				description: 'When enabled, Pharo Copilot automatically runs the installation script if the selected model is missing.'.

			(aBuilder setting: #installSelectedModelNowSetting)
				order: 0.45;
				label: 'Install selected model now';
				target: self current;
				getSelector: #installSelectedModelNowSetting;
				setSelector: #installSelectedModelNowSetting:;
				description: 'Manually pull the currently selected Ollama model.'.

			(aBuilder setting: #completionDebounceMilliseconds)
				order: 0.5;
				label: 'Completion debounce (ms)';
				target: self current;
				getSelector: #completionDebounceMilliseconds;
				setSelector: #completionDebounceMilliseconds:;
				default: self completionDebounceMilliseconds;
				description: 'Milliseconds to wait after a boundary before requesting completions (1-60000).'.

			(aBuilder setting: #completionIdleMilliseconds)
				order: 0.6;
				label: 'Completion idle (ms)';
				target: self current;
				getSelector: #completionIdleMilliseconds;
				setSelector: #completionIdleMilliseconds:;
				default: self completionIdleMilliseconds;
				description: 'Milliseconds to wait after typing stops before requesting completions (1-60000).'.

			contextSettingsClass ifNotNil: [
					(aBuilder pickOne: #contextMode)
						order: 0.65;
						label: 'Context mode';
						target: contextSettingsClass;
						getSelector: #mode;
						setSelector: #mode:;
						default: contextSettingsClass mode;
						domainValues: contextSettingsClass availableModes;
						description: 'Controls whether completions use full source or selectors-only class context.'.

					(aBuilder setting: #navigationHistoryEnabled)
						order: 0.655;
						label: 'Include browser navigation history';
						target: contextSettingsClass;
						getSelector: #navigationHistoryEnabled;
						setSelector: #navigationHistoryEnabled:;
						default: contextSettingsClass navigationHistoryEnabled;
						description: 'When enabled, the current Calypso browser selection and recent navigation states are prepended to the class context sent to the model.' ].

			(aBuilder setting: #maxInstanceMethods)
				order: 0.66;
				label: 'Max instance methods in context';
				target: self current;
				getSelector: #maxInstanceMethods;
				setSelector: #maxInstanceMethods:;
				default: self maxInstanceMethods;
				description: 'Maximum number of instance-side methods to include in the class context sent with completions (1-200). Default: 10'.

			(aBuilder setting: #maxClassMethods)
				order: 0.67;
				label: 'Max class methods in context';
				target: self current;
				getSelector: #maxClassMethods;
				setSelector: #maxClassMethods:;
				default: self maxClassMethods;
				description: 'Maximum number of class-side methods to include in the class context sent with completions (1-100). Default: 5'.

			(aBuilder setting: #minimumPrefixLength)
				order: 0.68;
				label: 'Minimum prefix length';
				target: self current;
				getSelector: #minimumPrefixLength;
				setSelector: #minimumPrefixLength:;
				default: self minimumPrefixLength;
				description: 'Minimum number of characters typed before requesting a completion (1-20). Default: 3'.

			(aBuilder setting: #completionSuggestionsCount)
				order: 0.69;
				label: 'Completion suggestions';
				target: self current;
				getSelector: #completionSuggestionsCount;
				setSelector: #completionSuggestionsCount:;
				default: self completionSuggestionsCount;
				description: 'How many completion alternatives to request per trigger (1-10).'.

			(aBuilder setting: #requestTimeoutSeconds)
				order: 0.7;
				label: 'Request timeout (sec)';
				target: self current;
				getSelector: #requestTimeoutSeconds;
				setSelector: #requestTimeoutSeconds:;
				default: self requestTimeoutSeconds;
				description: 'Seconds to wait for Ollama responses before timing out (1-120).'.

			(aBuilder setting: #modelInstallTimeoutSeconds)
				order: 0.75;
				label: 'Model install timeout (sec)';
				target: self current;
				getSelector: #modelInstallTimeoutSeconds;
				setSelector: #modelInstallTimeoutSeconds:;
				default: self modelInstallTimeoutSeconds;
				description: 'Seconds to wait for Ollama model downloads before timing out (30-3600).'.

			(aBuilder setting: #host)
				order: 1;
				label: 'Server host';
				target: self current;
				getSelector: #host;
				setSelector: #host:;
				default: self host.

			(aBuilder setting: #port)
				order: 2;
				label: 'Server port';
				target: self current;
				getSelector: #port;
				setSelector: #port:;
				default: self port.

			(aBuilder setting: #backgroundColor)
				order: 2.5;
				label: 'Background Color';
				target: self current;
				getSelector: #backgroundColor;
				setSelector: #backgroundColor:;
				default: self defaultBackgroundColor;
				description: 'Background color for the Copilot completion popup menu.'.

			(aBuilder group: #ollamaParameters)
				order: 3;
				label: 'Ollama Parameters';
				description: 'Configure Ollama model parameters.';
				with: [
					(aBuilder setting: #temperature)
						order: 1;
						label: 'Temperature';
						target: self current;
						getSelector: #temperature;
						setSelector: #temperature:;
						default: self temperature.

					(aBuilder setting: #topP)
						order: 2;
						label: 'Top P';
						target: self current;
						getSelector: #topP;
						setSelector: #topP:;
						default: self topP.

					(aBuilder setting: #topK)
						order: 3;
						label: 'Top K';
						target: self current;
						getSelector: #topK;
						setSelector: #topK:;
						default: self topK.

					(aBuilder setting: #numPredict)
						order: 4;
						label: 'Max tokens to generate';
						target: self current;
						getSelector: #numPredict;
						setSelector: #numPredict:;
						default: self numPredict.

					(aBuilder setting: #repeatPenalty)
						order: 5;
						label: 'Repeat penalty';
						target: self current;
						getSelector: #repeatPenalty;
						setSelector: #repeatPenalty:;
						default: self repeatPenalty.

					(aBuilder setting: #numCtx)
						order: 6;
						label: 'Context window size';
						target: self current;
						getSelector: #numCtx;
						setSelector: #numCtx:;
						default: self numCtx.

					(aBuilder setting: #seed)
						order: 7;
						label: 'Seed';
						target: self current;
						getSelector: #seed;
						setSelector: #seed:;
						default: self seed ] ]
]
{ #category : 'initialization' }
CopilotSettings >> initializeDefaults [

	enabled := true.
	provider := #ollama.
	modelName := CoPCOllamaClient defaultModelFullName.
	host := '127.0.0.1'.
	port := 11434.
	autoInstallModelScriptEnabled := true.
	loggingEnabled := true.
	templatesDirectory := (FileLocator imageDirectory / 'pharo-copilot' / 'templates') asFileReference.
	completionDebounceMilliseconds := 50.
	completionIdleMilliseconds := 300.
	requestTimeoutSeconds := 500.
	modelInstallTimeoutSeconds := 600.
	temperature := 0.8.
	topP := 0.9.
	topK := 40.
	numPredict := 128.
	repeatPenalty := 1.1.
	numCtx := 2048.
	seed := 0.
	customParameters := Dictionary new.
	maxInstanceMethods := 10.
	maxClassMethods := 5.
	minimumPrefixLength := 3.
	completionSuggestionsCount := 1.
	backgroundColor := CopilotSettings defaultBackgroundColor.
	installModelUserConsent := false
]
{ #category : 'persistence' }
CopilotSettings >> restoreSettingsFromSerializableSnapshot: aDictionary [

	enabled := CopilotSettings valueAt: #enabled from: aDictionary default: enabled.
	provider := CopilotSettings valueAt: #provider from: aDictionary default: provider.
	modelName := CopilotSettings valueAt: #modelName from: aDictionary default: modelName.
	host := CopilotSettings valueAt: #host from: aDictionary default: host.
	port := CopilotSettings valueAt: #port from: aDictionary default: port.
	autoInstallModelScriptEnabled := CopilotSettings valueAt: #autoInstallModelScriptEnabled from: aDictionary default: autoInstallModelScriptEnabled.
	loggingEnabled := CopilotSettings valueAt: #loggingEnabled from: aDictionary default: loggingEnabled.
	completionDebounceMilliseconds := CopilotSettings valueAt: #completionDebounceMilliseconds from: aDictionary default: completionDebounceMilliseconds.
	completionIdleMilliseconds := CopilotSettings valueAt: #completionIdleMilliseconds from: aDictionary default: completionIdleMilliseconds.
	requestTimeoutSeconds := CopilotSettings valueAt: #requestTimeoutSeconds from: aDictionary default: requestTimeoutSeconds.
	modelInstallTimeoutSeconds := CopilotSettings valueAt: #modelInstallTimeoutSeconds from: aDictionary default: modelInstallTimeoutSeconds.
	temperature := CopilotSettings valueAt: #temperature from: aDictionary default: temperature.
	topP := CopilotSettings valueAt: #topP from: aDictionary default: topP.
	topK := CopilotSettings valueAt: #topK from: aDictionary default: topK.
	numPredict := CopilotSettings valueAt: #numPredict from: aDictionary default: numPredict.
	repeatPenalty := CopilotSettings valueAt: #repeatPenalty from: aDictionary default: repeatPenalty.
	numCtx := CopilotSettings valueAt: #numCtx from: aDictionary default: numCtx.
	seed := CopilotSettings valueAt: #seed from: aDictionary default: seed.
	customParameters := CopilotSettings dictionaryValueAt: #customParameters from: aDictionary default: customParameters.
	maxInstanceMethods := CopilotSettings valueAt: #maxInstanceMethods from: aDictionary default: maxInstanceMethods.
	maxClassMethods := CopilotSettings valueAt: #maxClassMethods from: aDictionary default: maxClassMethods.
	minimumPrefixLength := CopilotSettings valueAt: #minimumPrefixLength from: aDictionary default: minimumPrefixLength.
	completionSuggestionsCount := CopilotSettings valueAt: #completionSuggestionsCount from: aDictionary default: completionSuggestionsCount.
	backgroundColor := CopilotSettings valueAt: #backgroundColor from: aDictionary default: backgroundColor.
	installModelUserConsent := CopilotSettings valueAt: #installModelUserConsent from: aDictionary default: installModelUserConsent.

	(aDictionary at: #templatesDirectory ifAbsent: [ nil ])
		ifNotNil: [ :templatesPath | templatesDirectory := templatesPath asFileReference ]
]
{ #category : 'accessing' }
CopilotSettings >> copilotEnabled [ ^ enabled ifNil: [ enabled := true ] ]

{ #category : 'accessing' }
CopilotSettings >> copilotEnabled: aBoolean [
	enabled := aBoolean.
	CopilotSettings autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings >> copilotProvider [ ^ provider ifNil: [ provider := #ollama ] ]

{ #category : 'accessing' }
CopilotSettings >> copilotProvider: aSymbol [
	provider := aSymbol.
	CopilotSettings autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings >> modelName [ ^ modelName ifNil: [ modelName := CoPCOllamaClient defaultModelFullName ] ]

{ #category : 'accessing' }
CopilotSettings >> modelName: aString [
	modelName := aString.
	CopilotSettings clearCachedModelMetadata.
	CopilotSettings autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings >> host [ ^ host ifNil: [ host := '127.0.0.1' ] ]

{ #category : 'accessing' }
CopilotSettings >> host: aString [
	host := aString.
	CopilotSettings clearCachedModelMetadata.
	CopilotSettings autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings >> port [ ^ port ifNil: [ port := 11434 ] ]

{ #category : 'accessing' }
CopilotSettings >> port: aNumberOrString [
	port := aNumberOrString isString
		ifTrue: [ aNumberOrString asNumber ]
		ifFalse: [ aNumberOrString ].
	CopilotSettings clearCachedModelMetadata.
	CopilotSettings autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings >> autoInstallModelScriptEnabled [
	^ autoInstallModelScriptEnabled ifNil: [ autoInstallModelScriptEnabled := true ]
]

{ #category : 'accessing' }
CopilotSettings >> autoInstallModelScriptEnabled: aBoolean [
	autoInstallModelScriptEnabled := aBoolean.
	CopilotSettings autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings >> loggingEnabled [
	^ loggingEnabled ifNil: [ loggingEnabled := true ]
]

{ #category : 'accessing' }
CopilotSettings >> loggingEnabled: aBoolean [
	loggingEnabled := aBoolean.
	CopilotSettings autoSaveSettings
]
{ #category : 'settings' }
CopilotSettings >> completionDebounceMilliseconds [
	^ completionDebounceMilliseconds ifNil: [ completionDebounceMilliseconds := 50 ]
]

{ #category : 'settings' }
CopilotSettings >> completionDebounceMilliseconds: anObject [
	completionDebounceMilliseconds := anObject.
	CopilotSettings autoSaveSettings
]

{ #category : 'settings' }
CopilotSettings >> completionIdleMilliseconds [
	^ completionIdleMilliseconds ifNil: [ completionIdleMilliseconds := 300 ]
]

{ #category : 'settings' }
CopilotSettings >> completionIdleMilliseconds: anObject [
	completionIdleMilliseconds := anObject.
	CopilotSettings autoSaveSettings
]

{ #category : 'settings' }
CopilotSettings >> requestTimeoutSeconds [
	^ requestTimeoutSeconds ifNil: [ requestTimeoutSeconds := 500 ]
]

{ #category : 'settings' }
CopilotSettings >> requestTimeoutSeconds: anObject [
	requestTimeoutSeconds := anObject.
	CopilotSettings autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings >> modelInstallTimeoutSeconds [
	^ modelInstallTimeoutSeconds ifNil: [ modelInstallTimeoutSeconds := 600 ]
]

{ #category : 'accessing' }
CopilotSettings >> modelInstallTimeoutSeconds: anObject [
	modelInstallTimeoutSeconds := anObject.
	CopilotSettings autoSaveSettings
]

{ #category : 'settings' }
CopilotSettings >> completionSuggestionsCount [
	^ completionSuggestionsCount ifNil: [ completionSuggestionsCount := 1 ]
]

{ #category : 'settings' }
CopilotSettings >> completionSuggestionsCount: anObject [
	completionSuggestionsCount := anObject.
	CopilotSettings autoSaveSettings
]
{ #category : 'context' }
CopilotSettings >> maxInstanceMethods [
	^ maxInstanceMethods ifNil: [ maxInstanceMethods := 10 ]
]

{ #category : 'context' }
CopilotSettings >> maxInstanceMethods: anObject [
	maxInstanceMethods := anObject.
	CopilotSettings autoSaveSettings
]

{ #category : 'context' }
CopilotSettings >> maxClassMethods [
	^ maxClassMethods ifNil: [ maxClassMethods := 5 ]
]

{ #category : 'context' }
CopilotSettings >> maxClassMethods: anObject [
	maxClassMethods := anObject.
	CopilotSettings autoSaveSettings
]

{ #category : 'context' }
CopilotSettings >> minimumPrefixLength [
	^ minimumPrefixLength ifNil: [ minimumPrefixLength := 3 ]
]

{ #category : 'context' }
CopilotSettings >> minimumPrefixLength: anObject [
	minimumPrefixLength := anObject.
	CopilotSettings autoSaveSettings
]
{ #category : 'ollama' }
CopilotSettings >> temperature [ ^ temperature ifNil: [ temperature := 0.8 ] ]

{ #category : 'ollama' }
CopilotSettings >> temperature: aNumber [
	temperature := aNumber.
	CopilotSettings autoSaveSettings
]

{ #category : 'ollama' }
CopilotSettings >> topP [ ^ topP ifNil: [ topP := 0.9 ] ]

{ #category : 'ollama' }
CopilotSettings >> topP: aNumber [
	topP := aNumber.
	CopilotSettings autoSaveSettings
]

{ #category : 'ollama' }
CopilotSettings >> topK [ ^ topK ifNil: [ topK := 40 ] ]

{ #category : 'ollama' }
CopilotSettings >> topK: anInteger [
	topK := anInteger.
	CopilotSettings autoSaveSettings
]

{ #category : 'ollama' }
CopilotSettings >> numPredict [ ^ numPredict ifNil: [ numPredict := 128 ] ]

{ #category : 'ollama' }
CopilotSettings >> numPredict: anInteger [
	numPredict := anInteger.
	CopilotSettings autoSaveSettings
]

{ #category : 'ollama' }
CopilotSettings >> repeatPenalty [ ^ repeatPenalty ifNil: [ repeatPenalty := 1.1 ] ]

{ #category : 'ollama' }
CopilotSettings >> repeatPenalty: aNumber [
	repeatPenalty := aNumber.
	CopilotSettings autoSaveSettings
]

{ #category : 'ollama' }
CopilotSettings >> numCtx [ ^ numCtx ifNil: [ numCtx := 2048 ] ]

{ #category : 'ollama' }
CopilotSettings >> numCtx: anIntegerOrNil [
	numCtx := anIntegerOrNil.
	CopilotSettings autoSaveSettings
]

{ #category : 'ollama' }
CopilotSettings >> seed [ ^ seed ifNil: [ seed := 0 ] ]

{ #category : 'ollama' }
CopilotSettings >> seed: anIntegerOrNil [
	seed := anIntegerOrNil.
	CopilotSettings autoSaveSettings
]

{ #category : 'ollama' }
CopilotSettings >> customParameters [
	^ customParameters ifNil: [ customParameters := Dictionary new ]
]

{ #category : 'ollama' }
CopilotSettings >> customParameters: aDictionary [
	customParameters := aDictionary ifNil: [ Dictionary new ].
	CopilotSettings autoSaveSettings
]
{ #category : 'accessing' }
CopilotSettings >> backgroundColor [
	^ backgroundColor ifNil: [ backgroundColor := CopilotSettings defaultBackgroundColor ]
]

{ #category : 'accessing' }
CopilotSettings >> backgroundColor: aColor [
	backgroundColor := aColor.
	CopilotSettings autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings >> templatesDirectory [
	^ templatesDirectory ifNil: [
		templatesDirectory := (FileLocator imageDirectory / 'pharo-copilot' / 'templates') asFileReference ]
]

{ #category : 'accessing' }
CopilotSettings >> templatesDirectory: aFileReference [
	templatesDirectory := aFileReference asFileReference.
	CopilotSettings autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings >> installModelUserConsent [
	^ installModelUserConsent ifNil: [ installModelUserConsent := false ]
]

{ #category : 'accessing' }
CopilotSettings >> installModelUserConsent: anObject [
	installModelUserConsent := anObject.
	CopilotSettings autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings >> installSelectedModelNowSetting [
	^ CopilotSettings installSelectedModelNowSetting
]

{ #category : 'accessing' }
CopilotSettings >> installSelectedModelNowSetting: aBoolean [
	CopilotSettings installSelectedModelNowSetting: aBoolean
]

{ #category : 'settings' }
CopilotSettings class >> recordInstallModelUserConsentForModelNamed: aModelName accepted: aBoolean [

	| consentRecord evalFile |
	consentRecord := Dictionary new
		at: #model put: aModelName;
		at: #accepted put: aBoolean;
		at: #timestamp put: DateAndTime now asString;
		yourself.

	self installModelUserConsent: consentRecord.

	[
		CoPharoCopilotLogger ensureEvaluationLogFileInitialized.
		evalFile := CoPharoCopilotLogger evaluationLogFileReference.
		evalFile writeStreamDo: [ :stream |
			stream setToEnd.
			stream
				nextPutAll: (STONJSON toString: (Dictionary new
					at: #event put: 'model-install-consent';
					at: #data put: consentRecord;
					yourself));
				nextPut: Character lf ]
	] on: Error do: [ :ignored | ].
]
