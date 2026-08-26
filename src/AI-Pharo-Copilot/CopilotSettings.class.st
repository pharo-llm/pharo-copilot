"
Central, class-side configuration for Pharo Copilot with an Ollama backend.

This class stores the selected provider/model/endpoint and manages related concerns
like validating the Ollama service, ensuring the selected model exists (optionally
installing it), and caching/writing model metadata and templates for logging/debugging.
"
Class {
	#name : 'CopilotSettings',
	#superclass : 'Object',
	#classInstVars : [
		'enabled',
		'provider',
		'modelName',
		'host',
		'port',
		'modelMetadata',
		'ollamaClientFactory',
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
		'modelKeepAlive',
		'customParameters',
		'maxInstanceMethods',
		'maxClassMethods',
		'minimumPrefixLength',
		'completionSuggestionsCount',
		'completionLogprobsEnabled',
		'completionTopLogprobs',
		'backgroundColor',
		'installModelUserConsent',
		'imageCloseSurveyEnabled',
		'researchTelemetryConsentState',
		'screenRecordingConsentState'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'accessing' }
CopilotSettings class >> allOllamaOptions [

	"Always send the configured values so the behavior matches what the settings UI
	shows — silently omitting values that happen to equal some hardcoded default made
	the effective model behavior depend on Ollama-side defaults instead."

	| options |
	options := Dictionary new.

	self temperature ifNotNil: [ :value | options at: #temperature put: value ].
	self topP ifNotNil: [ :value | options at: #top_p put: value ].
	self topK ifNotNil: [ :value | options at: #top_k put: value ].
	self numPredict ifNotNil: [ :value | options at: #num_predict put: value ].
	self repeatPenalty ifNotNil: [ :value | options at: #repeat_penalty put: value ].
	self numCtx ifNotNil: [ :value | options at: #num_ctx put: value ].
	(seed notNil and: [ seed ~= 0 ]) ifTrue: [ options at: #seed put: seed ].

	(customParameters notNil and: [ customParameters isEmpty not ]) ifTrue: [
		customParameters keysAndValuesDo: [ :key :value | options at: key put: value ] ].

	^ options
]

{ #category : 'accessing' }
CopilotSettings class >> attemptAutoInstallForModelNamed: aModelName usingInitialResponse: response [

	(self shouldAutoInstallModelNamed: aModelName) ifFalse: [ ^ false ].
	^ self performInstallOfModelNamed: aModelName usingInitialResponse: response
]

{ #category : 'accessing' }
CopilotSettings class >> autoInstallModelScriptEnabled [

	^ autoInstallModelScriptEnabled ifNil: [ autoInstallModelScriptEnabled := true ]
]

{ #category : 'accessing' }
CopilotSettings class >> autoInstallModelScriptEnabled: aBoolean [

	autoInstallModelScriptEnabled := aBoolean.
	self autoSaveSettings
]

{ #category : 'persistence' }
CopilotSettings class >> autoSaveSettings [
	"Automatically save settings to file when they change. Runs in background to avoid blocking UI."

	[
		self saveSettingsToFile
	] on: Error do: [ :ex |
		Transcript
			show: 'Copilot settings auto-save failed: ', ex messageText;
			cr ]
]

{ #category : 'settings' }
CopilotSettings class >> availableModelNames [
	"Answer the list of available model names for the settings UI.
	Uses the cached registry: refreshing here would perform a synchronous HTTP call
	every time the settings browser builds its tree, and when Ollama is unreachable
	the saved selection would vanish from the list (looking like a lost setting)."

	^ CoPCModelRegistry current domainValuesForSettings
]

{ #category : 'settings' }
CopilotSettings class >> availableProviders [
	"Answer the supported provider symbols."

	^ { #ollama }
]

{ #category : 'settings' }
CopilotSettings class >> backgroundColor [
	"Answer the background color for the Copilot completion menu."

	backgroundColor ifNotNil: [ ^ backgroundColor ].
	^ self defaultBackgroundColor
]

{ #category : 'accessing' }
CopilotSettings class >> backgroundColor: aColor [
	"Set the background color for the Copilot completion menu."

	backgroundColor := aColor.
	self autoSaveSettings
]

{ #category : 'settings' }
CopilotSettings class >> canLaunchLocalOllamaService [ 
	"Answer whether it is safe for us to start Ollama ourselves.

	The launch goes through LibC>>#system:, a blocking FFI call: the whole VM is frozen
	until the spawned command returns, so no other Pharo process runs meanwhile — not even
	SUnit's per-test timeout watchdog. On Windows the spawned 'cmd /c start ... ollama
	serve' does not reliably return when Ollama is absent, which hangs the image outright.
	A non-interactive image (CI, scripts) has nobody to benefit from the service anyway, so
	never shell out from one."

	^ (Smalltalk respondsTo: #isInteractive)
		ifTrue: [ Smalltalk isInteractive ]
		ifFalse: [ true ]
]

{ #category : 'accessing' }
CopilotSettings class >> canonicalModelNameForComparison: aModelName [
	"Normalize model identifiers for comparison. Ollama may report repository/model
	names in canonical lowercase form even when the requested pull used mixed case."

	aModelName ifNil: [ ^ '' ].
	^ aModelName asString trimBoth asLowercase
]

{ #category : 'accessing' }
CopilotSettings class >> clearCachedModelMetadata [
	"Drop the in-memory cached model metadata so it will be recomputed."

	modelMetadata := nil
]

{ #category : 'settings' }
CopilotSettings class >> completionDebounceMilliseconds [

	^ completionDebounceMilliseconds ifNil: [ completionDebounceMilliseconds := 0 ]
]

{ #category : 'settings' }
CopilotSettings class >> completionDebounceMilliseconds: anObject [

	completionDebounceMilliseconds := anObject.
	self autoSaveSettings
]

{ #category : 'settings' }
CopilotSettings class >> completionIdleMilliseconds [

	^ completionIdleMilliseconds ifNil: [ completionIdleMilliseconds := 75 ]
]

{ #category : 'settings' }
CopilotSettings class >> completionIdleMilliseconds: anObject [

	completionIdleMilliseconds := anObject.
	self autoSaveSettings
]

{ #category : 'settings' }
CopilotSettings class >> completionLogprobsEnabled [
	"Answer whether completion requests should ask Ollama for output token log probabilities."

	^ completionLogprobsEnabled ifNil: [ completionLogprobsEnabled := true ]
]

{ #category : 'settings' }
CopilotSettings class >> completionLogprobsEnabled: aBoolean [

	completionLogprobsEnabled := aBoolean = true.
	self autoSaveSettings
]

{ #category : 'settings' }
CopilotSettings class >> completionSuggestionsCount [

	^ completionSuggestionsCount ifNil: [ completionSuggestionsCount := 1 ]
]

{ #category : 'settings' }
CopilotSettings class >> completionSuggestionsCount: anObject [

	completionSuggestionsCount := anObject.
	self autoSaveSettings
]

{ #category : 'settings' }
CopilotSettings class >> completionTopLogprobs [
	"Answer how many likely tokens Ollama should return at each generated token position."

^ completionTopLogprobs ifNil: [ completionTopLogprobs := 1 ]
]

{ #category : 'settings' }
CopilotSettings class >> completionTopLogprobs: anInteger [

	| value |
	value := anInteger ifNil: [ 0 ] ifNotNil: [ anInteger asInteger ].
	completionTopLogprobs := (value max: 0) min: 20.
	self autoSaveSettings
]

{ #category : 'private' }
CopilotSettings class >> confirmViaUIManager: messageString [
	"Ask for confirmation via UIManager; answer true/false, or nil if UIManager not available."

	| uiClass uiManager response |
	uiClass := Smalltalk globals at: #UIManager ifAbsent: [ nil ].
	uiClass ifNil: [ ^ nil ].
	(uiClass respondsTo: #default) ifFalse: [ ^ nil ].

	uiManager := uiClass default.
	(uiManager respondsTo: #confirm:) ifFalse: [ ^ nil ].

response := UIManager default confirm: messageString.
(response isKindOf: Boolean) ifFalse: [ ^ nil ].
^ response

]

{ #category : 'accessing' }
CopilotSettings class >> copilotEnabled [
	"Answer whether Copilot is enabled; default to true."

	^ enabled ifNil: [ enabled := true ]
]

{ #category : 'accessing' }
CopilotSettings class >> copilotEnabled: aBoolean [
	"Enable/disable Copilot globally."

	enabled := aBoolean.
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> copilotProvider [

	^ provider ifNil: [ provider := #ollama ]
]

{ #category : 'accessing' }
CopilotSettings class >> copilotProvider: aSymbol [

	provider := aSymbol.
	self autoSaveSettings
]

{ #category : 'ollama' }
CopilotSettings class >> customParameters [
	"Answer the dictionary of custom Ollama parameters (user-extensible). Default: empty dictionary"

	^ customParameters ifNil: [ customParameters := Dictionary new ]
]

{ #category : 'ollama' }
CopilotSettings class >> customParameters: aDictionary [
	"Set the dictionary of custom Ollama parameters."

	customParameters := aDictionary ifNil: [ Dictionary new ].
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> defaultBackgroundColor [
	"Answer the default background color for the Copilot completion menu."

	| uiThemeClass theme |
	uiThemeClass := Smalltalk globals at: #UITheme ifAbsent: [ nil ].
	uiThemeClass ifNotNil: [
		(uiThemeClass respondsTo: #current) ifTrue: [
			theme := uiThemeClass current.
			(theme respondsTo: #windowColor) ifTrue: [ ^ theme windowColor ] ] ].
	^ Color darkGray
]

{ #category : 'accessing' }
CopilotSettings class >> defaultCompletionModelName [

	^ CoPCOllamaClient defaultModelFullName
]

{ #category : 'accessing' }
CopilotSettings class >> defaultFimTemplate [
	"Return the best available FIM template (cached from logs, bundled templates, or fail)."

	| template cacheFile |
	cacheFile := self templateFileForModelNamed: self modelName.

	template := self fimTemplateFromFile: cacheFile.
	template ifNotNil: [
		self logUsingCachedFimTemplateFrom: cacheFile.
		^ template
	].

	template := self fimTemplateFromBundledTemplates.
	template ifNotNil: [ ^ template ].

	self logMissingFimTemplate.
	^ self error: 'No fill-in-the-middle template is available for the current Copilot model.'
]

{ #category : 'persistence' }
CopilotSettings class >> dictionaryValueAt: aKey from: aDictionary default: aDefaultValue [

	| value |
	value := self valueAt: aKey from: aDictionary default: aDefaultValue.
	^ (value isKindOf: Dictionary)
		ifTrue: [ value ]
		ifFalse: [ Dictionary new ]
]

{ #category : 'settings' }
CopilotSettings class >> ensureDefaultCompletionModelSelected [
	"Use the default completion model when no real model has been selected yet."

	| previousModel |
	previousModel := modelName.
	self useDefaultCompletionModelWhenSavedModelIsMissingOrNull.
	previousModel ~= modelName ifTrue: [ self autoSaveSettings ].
	^ self modelName
]

{ #category : 'accessing' }
CopilotSettings class >> ensureModelMetadataDirectoryFor: modelNameString [
	"Ensure the per-model metadata directory exists; answer the directory or nil on failure."

	| logsDirectory modelDirectory |
	logsDirectory := CoPharoCopilotLogger ensureLogsDirectory.
	modelDirectory := logsDirectory / (self sanitizedFileComponentFor: modelNameString default: 'unknown-model').

	[
		modelDirectory ensureCreateDirectory
	] on: Error do: [ :ex |
		CoPharoCopilotLogger
			logBackEndEvent: 'Failed to prepare metadata directory'
			details: (Dictionary new
				at: #model put: modelNameString;
				at: #errorClass put: ex class name;
				at: #error put: ex description;
				yourself).
		^ nil
	].

	^ modelDirectory
]

{ #category : 'accessing' }
CopilotSettings class >> ensureOllamaInstalledBeforeUse [

	| response |

	response := self ensureOllamaServiceAvailable.
	response ifNil: [ ^ false ].

	^ self ensurePredefinedModelsDownloadedUsingInitialResponse: response
]

{ #category : 'accessing' }
CopilotSettings class >> ensureOllamaServiceAvailable [
	"Verify Ollama responds. If it does not, try to launch it locally."

	| response |

	[
		response := self newOllamaClient listModels
	] on: Error do: [ :ex |
		self logOllamaServiceUnavailable: ex.
		self notifyUser:
			'Ollama is not responding. Pharo Copilot will try to launch Ollama locally, then handle model downloading.'.

		(self launchLocalOllamaServiceIfPossible) ifFalse: [
			self notifyUser:
				'Ollama could not be launched automatically. Please install/start Ollama and stay connected to the internet.'.
			^ nil ].

		(Delay forSeconds: 2) wait.

		[
			response := self newOllamaClient listModels
		] on: Error do: [ :retryEx |
			self logOllamaServiceUnavailable: retryEx.
			self notifyUser:
				'Ollama still is not responding. Please install/start Ollama and try again.'.
			^ nil ]
	].

	response ifNil: [
		self logOllamaMissingResponse.
		self notifyUser:
			'Ollama did not return a model list. Please check Ollama and try again.'.
		^ nil ].

	^ response
]

{ #category : 'accessing' }
CopilotSettings class >> ensurePredefinedModelsDownloadedUsingInitialResponse: initialResponse [

	| availableModels missingModels allDownloaded |

	availableModels := self modelNamesFromResponse: initialResponse.
	missingModels := self predefinedDownloadableModelNames
		reject: [ :each | self installedModelNames: availableModels includesModelNamed: each ].

	missingModels isEmpty ifTrue: [ ^ true ].

	"One single announcement listing exactly what will be downloaded — per-model chatter
	goes to the Transcript instead of popup dialogs."
	self notifyUser:
		('Pharo Copilot will download {1} model(s):' , String cr ,
		(self modelNamesTextFor: missingModels) , String cr ,
		'Please stay connected to the internet until the download completes.'
			format: { missingModels size asString }).

	allDownloaded := true.
	missingModels doWithIndex: [ :modelName :index |
		self notifyViaTranscript:
			('Downloading model {1} ({2}/{3})...'
				format: { modelName. index asString. missingModels size asString }).

		((self installModelNamed: modelName)
			and: [ self refreshModelsAfterInstallOf: modelName usingInitialResponse: initialResponse ])
				ifFalse: [ allDownloaded := false ] ].

	allDownloaded
		ifTrue: [
			self notifyUser: 'All predefined Copilot models are available locally.' ]
		ifFalse: [
			self notifyUser:
				'Some predefined models could not be downloaded. Please check your internet connection and Ollama logs.' ].

	^ allDownloaded
]

{ #category : 'settings' }
CopilotSettings class >> ensureSelectedModelAvailable [
	"Ensure the configured model exists in Ollama (optionally auto-install); answer true if available."

	| selectedModelName response availableModels |
	selectedModelName := self modelName.
	(self isNullModelName: selectedModelName) ifTrue: [ ^ true ].

	response := self ensureOllamaServiceAvailable.
	response ifNil: [ ^ self handleMissingOllamaForModelNamed: selectedModelName ].

	availableModels := self modelNamesFromResponse: response.
	self logValidatedModelAvailability: selectedModelName availableModels: availableModels.

	(self installedModelNames: availableModels includesModelNamed: selectedModelName) ifTrue: [ ^ true ].
	self autoInstallModelScriptEnabled ifFalse: [ ^ false ].

	(self attemptAutoInstallForModelNamed: selectedModelName usingInitialResponse: response) ifTrue: [ ^ true ].

	(self promptToInstallMissingModelNamed: selectedModelName availableModels: availableModels) ifTrue: [
		(self performInstallOfModelNamed: selectedModelName usingInitialResponse: response) ifTrue: [ ^ true ] ].

	self logMissingModel: selectedModelName availableModels: availableModels.
	self notifyUser:
		('We could not find this model in your Ollama installation. If you recently requested its installation, please wait while it completes.'
			 format: { selectedModelName }).
	^ false
]

{ #category : 'accessing' }
CopilotSettings class >> fetchModelMetadata [
	"Fetch and cache model metadata from Ollama; answer an empty dictionary on failure."

	| client response metadata selectedModelName |
	metadata := Dictionary new.

	(self ensureSelectedModelAvailable) ifFalse: [ ^ metadata ].

	selectedModelName := self modelName.
	(self isNullModelName: selectedModelName) ifTrue: [
		metadata := self nullModelMetadata.
		self saveModelMetadataFilesFor: metadata.
		self logGeneratedNullModelMetadata: metadata modelName: selectedModelName.
		^ metadata
	].

	[
		client := self newOllamaClient.
		response := client showModelNamed: selectedModelName.
		response ifNil: [ ^ metadata ].

		self populateMetadata: metadata fromResponse: response.
		self saveModelMetadataFilesFor: metadata.
		self logFetchedModelMetadata: metadata fallbackModelName: selectedModelName
	] on: Error do: [ :ex |
		self logFailedToFetchModelMetadataFor: selectedModelName error: ex
	].

	^ metadata
]

{ #category : 'accessing' }
CopilotSettings class >> fimTemplate [

	| metadata template promptMarkers suffixMarkers hasPrompt hasSuffix |
	metadata := self modelMetadata.
	metadata ifNil: [ ^ self defaultFimTemplate ].

	template := self valueForMetadataKey: #template in: metadata.
	template ifNil: [ ^ self defaultFimTemplate ].
	(template respondsTo: #asString) ifFalse: [ ^ self defaultFimTemplate ].

	template := template asString trimBoth.
	template isEmpty ifTrue: [ ^ self defaultFimTemplate ].

	promptMarkers := #('{{ .Prompt }}' '{{.Prompt}}' '{1}' '%1').
	suffixMarkers := #('{{ .Suffix }}' '{{.Suffix}}' '{2}' '%2').

	hasPrompt := promptMarkers anySatisfy: [ :each | template includesSubstring: each ].
	hasSuffix := suffixMarkers anySatisfy: [ :each | template includesSubstring: each ].

	(hasPrompt and: [ hasSuffix ]) ifFalse: [ ^ self defaultFimTemplate ].

	^ template
]

{ #category : 'accessing' }
CopilotSettings class >> fimTemplateFromBundledTemplates [
	"Try to load a bundled FIM template from the templates directory; answer nil if not found."

	| directory sanitizedName candidates |
	directory := self templatesDirectory.
	(directory exists) ifFalse: [ ^ nil ].

	sanitizedName := self
		sanitizedFileComponentFor: self modelName
		default: 'unknown-model'.

	candidates := OrderedCollection new.
	candidates add: directory / sanitizedName / 'template.txt'.
	candidates add: directory / 'template.txt'.

	candidates do: [ :each |
		| value |
		value := self fimTemplateFromFile: each.
		value ifNotNil: [
			self logUsingBundledFimTemplateFrom: each.
			^ value
		]
	].

	^ nil
]

{ #category : 'accessing' }
CopilotSettings class >> fimTemplateFromFile: aFileReference [
	"Read a template file and answer its non-empty contents, or nil if missing/unreadable."

	| file contents |
	aFileReference ifNil: [ ^ nil ].

	file := aFileReference asFileReference.
	((file exists) and: [ file isFile ]) ifFalse: [ ^ nil ].

	contents := [
		file readStreamDo: [ :stream | stream contents ]
	] on: Error do: [ :ex |
		self logFailedToReadFimTemplateFile: file error: ex.
		^ nil
	].

	(contents respondsTo: #asString) ifFalse: [ ^ nil ].
	contents := contents asString.
	contents isEmpty ifTrue: [ ^ nil ].

	^ contents
]

{ #category : 'ollama' }
CopilotSettings class >> getCustomParameter: aKey [
	"Get a single custom parameter, or nil if not set."

	^ self customParameters at: aKey ifAbsent: [ nil ]
]

{ #category : 'settings' }
CopilotSettings class >> handleMissingOllamaForModelNamed: selectedModelName [ 

	self switchToNullModelDueToMissingOllamaFor: selectedModelName.
	^ self isNullModelName: self modelName
]

{ #category : 'accessing' }
CopilotSettings class >> host [
	"Answer the configured Ollama host; default to localhost."

	^ host ifNil: [ host := '127.0.0.1' ]
]

{ #category : 'accessing' }
CopilotSettings class >> host: aString [
	"Set the Ollama host and clear cached metadata."

	host := aString.
	self clearCachedModelMetadata.
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> imageCloseSurveyEnabled [
	"Answer whether Copilot asks for a short feedback form when the Pharo image quits."

	^ self researchTelemetryAccepted
		and: [ imageCloseSurveyEnabled ifNil: [ imageCloseSurveyEnabled := true ] ]
]

{ #category : 'accessing' }
CopilotSettings class >> imageCloseSurveyEnabled: aBoolean [

	imageCloseSurveyEnabled := aBoolean.
	self autoSaveSettings
]

{ #category : 'research telemetry' }
CopilotSettings class >> anonymousResearchTelemetryEnabled [
	"Settings UI accessor. Unknown, missing, or declined consent is always OFF."

	^ self researchTelemetryAccepted
]

{ #category : 'research telemetry' }
CopilotSettings class >> anonymousResearchTelemetryEnabled: aBoolean [
	"Settings UI mutator. Enabling requires a fresh explicit confirmation."

	aBoolean = true
		ifTrue: [ ^ self requestEnableAnonymousResearchTelemetry ].
	^ self requestDisableAnonymousResearchTelemetry
]

{ #category : 'research telemetry' }
CopilotSettings class >> declineResearchTelemetryIfNotAsked [

	self researchTelemetryNotAsked ifTrue: [
		self recordResearchTelemetryConsentAccepted: false ]
]

{ #category : 'class initialization' }
CopilotSettings class >> initialize [

	provider ifNotNil: [ ^ self ].
	self initializeDefaults.
	self loadSettingsFromFile
]

{ #category : 'settings' }
CopilotSettings class >> initializeDefaults [

	enabled := true.
	provider := #ollama.
	modelName := self defaultCompletionModelName.
	host := '127.0.0.1'.
	port := 11434.
	autoInstallModelScriptEnabled := true.
	loggingEnabled := false.
	templatesDirectory := (FileLocator imageDirectory / 'pharo-copilot' / 'templates') asFileReference.
	completionDebounceMilliseconds := 0.
	completionIdleMilliseconds := 75.
	requestTimeoutSeconds := 60.
	modelInstallTimeoutSeconds := 600.
	temperature := 0.2.
	topP := 0.9.
	topK := 40.
	numPredict := 32.
	repeatPenalty := 1.1.
	numCtx := 4096.
	seed := 0.
	modelKeepAlive := '30m'.
	customParameters := Dictionary new.
	maxInstanceMethods := 6.
	maxClassMethods := 3.
	minimumPrefixLength := 3.
	completionSuggestionsCount := 1.
	completionLogprobsEnabled := true.
	completionTopLogprobs := 1.
	backgroundColor := self defaultBackgroundColor.
	installModelUserConsent := false.
	imageCloseSurveyEnabled := true.
	researchTelemetryConsentState := #notAsked.
	screenRecordingConsentState := #notAsked.
	ollamaClientFactory := [ CoPCOllamaClient new ].
	modelMetadata := nil
]

{ #category : 'settings' }
CopilotSettings class >> installCompletionEngineIfAvailable [
	"Select the Pharo Copilot completion engine when the host image supports it."

	| editorClass engineClass |
	editorClass := Smalltalk globals at: #RubSmalltalkEditor ifAbsent: [ nil ].
	engineClass := Smalltalk globals at: #CoPharoCopilotCompletionEngine ifAbsent: [ nil ].
	(editorClass isNil or: [ engineClass isNil ]) ifTrue: [ ^ false ].
	(editorClass respondsTo: #completionEngineClass:) ifFalse: [ ^ false ].

	editorClass completionEngineClass: engineClass.
	^ true
]

{ #category : 'accessing' }
CopilotSettings class >> installModelNamed: aModelName [
	
	| client pullResult |

	(self isPredefinedDownloadableModelName: aModelName) ifFalse: [
		self notifyUser:
			('The model "{1}" is not in the predefined downloadable model list.' format: { aModelName }).
		^ false ].

	[
		client := self newOllamaClient.

		self notifyViaTranscript:
			('Downloading {1}... Please stay connected to the internet.'
				format: { aModelName }).

		CoPharoCopilotLogger logBackEndEvent: 'Invoking Ollama model install script' details: (Dictionary new
			at: #model put: aModelName;
			yourself).

		pullResult := (client respondsTo: #pullModelNamed:timeoutSeconds:)
			ifTrue: [
				client
					pullModelNamed: aModelName
					timeoutSeconds: self modelInstallTimeoutSeconds ]
			ifFalse: [
				client pullModelNamed: aModelName ].

		(self pullResultIndicatesFailure: pullResult) ifTrue: [
			self error: 'Ollama reported pull failure for ', aModelName ].

		CoPharoCopilotLogger logBackEndEvent: 'Ollama model install script completed' details: (Dictionary new
			at: #model put: aModelName;
			yourself).

		self notifyViaTranscript: ('Download completed for {1}.' format: { aModelName }).
		^ true
	] on: Error do: [ :ex |
		self notifyUser:
			('Failed to download {1}.' , String cr ,
			'Please check your internet connection and Ollama logs.'
				format: { aModelName }).
		^ false ]
]

{ #category : 'accessing' }
CopilotSettings class >> installModelNamedForSetup: aModelName [

	^ self installModelNamedForSetup: aModelName progress: nil
]

{ #category : 'accessing' }
CopilotSettings class >> installModelNamedForSetup: aModelName progress: aProgressBlockOrNil [
	"Pull a predefined model, reporting streaming download progress to the optional
	block (a dictionary per Ollama status line: status, total, completed)."

	| client pullResult |

	(self isPredefinedDownloadableModelName: aModelName) ifFalse: [
		CoPharoCopilotLogger logBackEndEvent: 'Setup refused non-predefined model install' details: (Dictionary new
			at: #model put: aModelName;
			yourself).
		^ false ].

	[
		client := self newOllamaClient.

		CoPharoCopilotLogger logBackEndEvent: 'Setup invoking Ollama model install script' details: (Dictionary new
			at: #model put: aModelName;
			yourself).

		pullResult := (aProgressBlockOrNil notNil and: [ client respondsTo: #pullModelNamed:timeoutSeconds:progress: ])
			ifTrue: [
				client
					pullModelNamed: aModelName
					timeoutSeconds: self modelInstallTimeoutSeconds
					progress: aProgressBlockOrNil ]
			ifFalse: [
				(client respondsTo: #pullModelNamed:timeoutSeconds:)
					ifTrue: [
						client
							pullModelNamed: aModelName
							timeoutSeconds: self modelInstallTimeoutSeconds ]
					ifFalse: [
						client pullModelNamed: aModelName ] ].

		(self pullResultIndicatesFailure: pullResult) ifTrue: [
			self error: 'Ollama reported pull failure for ', aModelName ].

		CoPharoCopilotLogger logBackEndEvent: 'Setup Ollama model install script completed' details: (Dictionary new
			at: #model put: aModelName;
			yourself).

		^ true
	] on: Error do: [ :ex |
		CoPharoCopilotLogger logBackEndEvent: 'Setup failed to download model' details: (Dictionary new
			at: #model put: aModelName;
			at: #errorClass put: ex class name;
			at: #error put: ex description;
			yourself).
		^ false ]
]

{ #category : 'persistence' }
CopilotSettings class >> installModelPromptMessageForModelNamed: aModelName [
	"Build the consent prompt shown before model installation."

	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Pharo Copilot uses your current editing context to request code completions from your local Ollama model.';
			nextPut: Character lf;
			nextPutAll: 'No source code is sent to external cloud services by this plugin.';
			nextPut: Character lf;
			nextPutAll: 'The model "', aModelName, '" is not installed yet.';
			nextPut: Character lf;
			nextPutAll: 'Do you consent to installing it now?' ]
]

{ #category : 'persistence' }
CopilotSettings class >> installPredefinedSetupModelsNow [
	"Check Ollama, then download every predefined setup model that is missing."

	| response missingModels |
	response := self ensureOllamaServiceAvailable.
	response ifNil: [ ^ false ].

	missingModels := self missingSetupModelNamesFrom: response.
	missingModels isEmpty ifTrue: [
		self notifyUser: 'All setup models are already installed.'.
		^ true
	].

	CoPCModelDownloadProgressPresenter openOn: missingModels.
	^ true
]

{ #category : 'persistence' }
CopilotSettings class >> installPredefinedSetupModelsNowSetting [

	^ false
]

{ #category : 'persistence' }
CopilotSettings class >> installPredefinedSetupModelsNowSetting: aBoolean [

	aBoolean ifTrue: [ self installPredefinedSetupModelsNow ]
]

{ #category : 'accessing' }
CopilotSettings class >> installSelectedModelNow [
	"Install the currently selected model via Ollama pull, showing download progress in
	a dedicated window instead of blocking the UI thread."

	| selectedModelName response availableModels |
	selectedModelName := self modelName.
	(selectedModelName isNil or: [ selectedModelName isEmpty ]) ifTrue: [
		self notifyUser: 'Please select an Ollama model before installing.'.
		^ false
	].

	response := self ensureOllamaServiceAvailable.
	response ifNil: [ ^ self handleMissingOllamaForModelNamed: selectedModelName ].

	availableModels := self modelNamesFromResponse: response.
	(self installedModelNames: availableModels includesModelNamed: selectedModelName) ifTrue: [
		self notifyUser: ('The model "{1}" is already installed.' format: { selectedModelName }).
		^ true
	].

	(self isPredefinedDownloadableModelName: selectedModelName) ifFalse: [
		self notifyUser:
			('The model "{1}" is not in the predefined downloadable model list.' format: { selectedModelName }).
		^ false
	].

	CoPCModelDownloadProgressPresenter openOn: { selectedModelName }.
	^ true
]

{ #category : 'accessing' }
CopilotSettings class >> installSelectedModelNowSetting [
	"Settings UI helper: always unchecked."

	^ false
]

{ #category : 'accessing' }
CopilotSettings class >> installSelectedModelNowSetting: aBoolean [
	"Trigger a model pull from the settings UI when checked."

	aBoolean ifTrue: [ self installSelectedModelNow ]
]

{ #category : 'accessing' }
CopilotSettings class >> installedModelNames: modelNames includesModelNamed: aModelName [

	^ modelNames anySatisfy: [ :each |
		self modelName: aModelName matchesInstalledModelName: each ]
]

{ #category : 'settings' }
CopilotSettings class >> internetConnectionAvailable [

	^ [
		ZnEasy get: 'https://ollama.com'.
		true
	] on: Error do: [ :ex |
		CoPharoCopilotLogger logBackEndEvent: 'Internet connection check failed' details: (Dictionary new
			at: #errorClass put: ex class name;
			at: #error put: ex description;
			yourself).
		false
	]
]

{ #category : 'accessing' }
CopilotSettings class >> isCopilotEngineSelected [
	"Answer whether a Copilot completion engine is currently selected in the editor."

	^ [
		| currentEngine |
		currentEngine := RubSmalltalkEditor completionEngineClass.
		currentEngine notNil and: [
			currentEngine name = 'CoCompletionEnginePharoCopilot'
				or: [ currentEngine name includesSubstring: 'Copilot' ]
		]
	] on: Error do: [ false ]
]

{ #category : 'accessing' }
CopilotSettings class >> isNullModelName: aString [
	"Answer whether the given model name is the configured null model name."

	^ aString = self nullModelFullName
]

{ #category : 'accessing' }
CopilotSettings class >> isPredefinedDownloadableModelName: aModelName [

	aModelName ifNil: [ ^ false ].
	^ self
		installedModelNames: self predefinedDownloadableModelNames
		includesModelNamed: aModelName
]

{ #category : 'accessing' }
CopilotSettings class >> launchLocalOllamaServiceIfPossible [

	self notifyUser:
		('Launching Ollama locally.' , String cr ,
		'After Ollama starts, Pharo Copilot will handle model downloading.' , String cr ,
		'Please stay connected to the internet.').

	^ self launchLocalOllamaServiceSilentlyIfPossible
]

{ #category : 'accessing' }
CopilotSettings class >> launchLocalOllamaServiceSilentlyIfPossible [

	| osPlatform libc command |

	osPlatform := Smalltalk globals at: #OSPlatform ifAbsent: [ nil ].
	libc := Smalltalk globals at: #LibC ifAbsent: [ nil ].
	(osPlatform isNil or: [ libc isNil ]) ifTrue: [ ^ false ].

	command := osPlatform current isWindows
		ifTrue: [ 'cmd /c start "" /B ollama serve' ]
		ifFalse: [ 'ollama serve &' ].

	[
		libc uniqueInstance system: command.
		(Delay forSeconds: 1) wait.
		^ true
	] on: Error do: [ :ex |
		CoPharoCopilotLogger logBackEndEvent: 'Failed to launch local Ollama service' details: (Dictionary new
			at: #command put: command;
			at: #errorClass put: ex class name;
			at: #error put: ex description;
			yourself).
		^ false ]
]

{ #category : 'accessing' }
CopilotSettings class >> listModelsForSetupAfterLaunchingOllamaIfNeeded [

	| response |

	[
		response := self newOllamaClient listModels
	] on: Error do: [ :ex |
		self logOllamaServiceUnavailable: ex.

		(self launchLocalOllamaServiceSilentlyIfPossible) ifFalse: [ ^ nil ].
		(Delay forSeconds: 2) wait.

		[
			response := self newOllamaClient listModels
		] on: Error do: [ :retryEx |
			self logOllamaServiceUnavailable: retryEx.
			^ nil ]
	].

	response ifNil: [
		self logOllamaMissingResponse.
		^ nil ].

	^ response
]

{ #category : 'persistence' }
CopilotSettings class >> loadSettingsFromFile [
	"Load settings from the persistent STON file if it exists."

	| fileRef stonString snapshot |

	fileRef := self settingsFileReference.
	(fileRef exists and: [ fileRef isFile ]) ifFalse: [ ^ self ].

	[

		fileRef readStreamDo: [ :stream |
			stonString := stream contents
		].

		snapshot := STON fromString: stonString.
		self restoreSettingsFromSerializableSnapshot: snapshot.
		] on: Error do: [ :ex |
		Transcript
			show: 'Copilot settings load failed. Keeping defaults. Error: ', ex messageText;
			cr ].


]

{ #category : 'private' }
CopilotSettings class >> logDetectedInstalledModel: aModelName before: initialResponse after: refreshedModels [
	"Log that a model became available after installation."
]

{ #category : 'private' }
CopilotSettings class >> logFailedToFetchModelMetadataFor: aModelName error: ex [
]

{ #category : 'private' }
CopilotSettings class >> logFailedToReadFimTemplateFile: file error: ex [
	"Log errors while reading a template file."

]

{ #category : 'private' }
CopilotSettings class >> logFetchedModelMetadata: metadata fallbackModelName: aModelName [
	"Log a successful metadata fetch."
]

{ #category : 'private' }
CopilotSettings class >> logGeneratedNullModelMetadata: metadata modelName: aModelName [
	"Log that we generated placeholder/null metadata."

]

{ #category : 'private' }
CopilotSettings class >> logInstallDidNotExposeModel: aModelName before: initialResponse after: refreshedModels [
	"Log when an install completed but the model is still unavailable."
]

{ #category : 'accessing' }
CopilotSettings class >> logMissingFimTemplate [
	"Log that no FIM template could be found for the current model."

]

{ #category : 'private' }
CopilotSettings class >> logMissingModel: aModelName availableModels: availableModels [
	"Log that a configured model is not present in the Ollama installation."

]

{ #category : 'private' }
CopilotSettings class >> logOllamaMissingResponse [
	"Log a nil/empty response from Ollama listModels."

]

{ #category : 'private' }
CopilotSettings class >> logOllamaServiceUnavailable: ex [
	"Log when the Ollama service cannot be reached."

]

{ #category : 'private' }
CopilotSettings class >> logUsingBundledFimTemplateFrom: fileRef [
	"Log that we loaded a bundled template file."

	CoPharoCopilotLogger
		logBackEndEvent: 'Using bundled FIM template'
		details: (Dictionary new
			at: #model put: (self modelName ifNil: [ 'unknown-model' ]);
			at: #source put: fileRef pathString;
			yourself)
]

{ #category : 'private' }
CopilotSettings class >> logUsingCachedFimTemplateFrom: cacheFile [
	"Log that we loaded a cached template from logs."

	CoPharoCopilotLogger
		logBackEndEvent: 'Using cached FIM template from logs'
		details: (Dictionary new
			at: #model put: (self modelName ifNil: [ 'unknown-model' ]);
			at: #source put: cacheFile pathString;
			yourself)
]

{ #category : 'private' }
CopilotSettings class >> logValidatedModelAvailability: aModelName availableModels: availableModels [
	"Log that model availability was checked against Ollama."
]

{ #category : 'accessing' }
CopilotSettings class >> loggingEnabled [
	"Answer whether research telemetry logging is enabled. No explicit consent means OFF."

	^ self researchTelemetryAccepted
		and: [ loggingEnabled ifNil: [ loggingEnabled := true ] ]
]

{ #category : 'accessing' }
CopilotSettings class >> loggingEnabled: aBoolean [

	loggingEnabled := aBoolean.
	self autoSaveSettings
]

{ #category : 'context' }
CopilotSettings class >> maxClassMethods [

	^ maxClassMethods ifNil: [ maxClassMethods := 3 ]
]

{ #category : 'context' }
CopilotSettings class >> maxClassMethods: anObject [

	maxClassMethods := anObject.
	self autoSaveSettings
]

{ #category : 'context' }
CopilotSettings class >> maxInstanceMethods [

	^ maxInstanceMethods ifNil: [ maxInstanceMethods := 6 ]
]

{ #category : 'context' }
CopilotSettings class >> maxInstanceMethods: anObject [

	maxInstanceMethods := anObject.
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> metadataFileContentsFor: value [
	"Format a metadata value as text suitable for writing to a .txt file."

	| formatted |
	formatted := CoPharoCopilotLogger formatValue: value.
	formatted ifNil: [ ^ '' ].
	^ formatted asString
]

{ #category : 'private' }
CopilotSettings class >> metadataJsonStringFor: value default: defaultString [
	"Try to stringify a value as JSON; fall back to printString or default when empty."

	[
		| json |
		json := STONJSON toString: value.
		json isEmpty ifTrue: [ ^ defaultString ].
		^ json
	] on: Error do: [ :ignored | ].

	^ value printString
]

{ #category : 'accessing' }
CopilotSettings class >> metadataStringForKey: aKey default: defaultString [
	"Read a metadata entry as a useful string (including JSON for complex objects) with a fallback."

	| metadata value |
	metadata := self modelMetadata.
	value := self valueForMetadataKey: aKey in: metadata.

	value isNil ifTrue: [ ^ defaultString ].
	(value isString) ifTrue: [ ^ (value isEmpty ifTrue: [ defaultString ] ifFalse: [ value ]) ].

	(value respondsTo: #asString) ifTrue: [
		| converted |
		converted := value asString.
		^ (converted isEmpty ifTrue: [ defaultString ] ifFalse: [ converted ])
	].

	^ self metadataJsonStringFor: value default: defaultString
]

{ #category : 'context' }
CopilotSettings class >> minimumPrefixLength [

	^ minimumPrefixLength ifNil: [ minimumPrefixLength := 3 ]
]

{ #category : 'context' }
CopilotSettings class >> minimumPrefixLength: anObject [

	minimumPrefixLength := anObject.
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> missingOllamaSetupMessage [

	^ 'You cannot use Pharo-Copilot tools without Ollama. Please download and install Ollama, then run setup again.'

]

{ #category : 'persistence' }
CopilotSettings class >> missingSetupModelNamesFrom: listModelsResponse [
	"Answer setup models that are not currently installed in Ollama."

	| installedModels |
	installedModels := self modelNamesFromResponse: listModelsResponse.

	^ self predefinedSetupModelNames
		reject: [ :each | self installedModelNames: installedModels includesModelNamed: each ]
]

{ #category : 'accessing' }
CopilotSettings class >> modelInstallTimeoutSeconds [
	"Answer the timeout (seconds) for Ollama model pulls."

	^ modelInstallTimeoutSeconds ifNil: [ modelInstallTimeoutSeconds := 600 ]
]

{ #category : 'accessing' }
CopilotSettings class >> modelInstallTimeoutSeconds: anObject [

	modelInstallTimeoutSeconds := anObject.
	self autoSaveSettings
]

{ #category : 'ollama' }
CopilotSettings class >> modelKeepAlive [
	"Answer the keep_alive value sent with generation requests. Keeping the model loaded
	between completions avoids paying the multi-second model load on every idle gap."

	^ modelKeepAlive ifNil: [ modelKeepAlive := '30m' ]
]

{ #category : 'ollama' }
CopilotSettings class >> modelKeepAlive: aStringOrNumber [

	modelKeepAlive := aStringOrNumber.
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> modelMetadata [
	"Answer cached model metadata, fetching it lazily if needed."

	modelMetadata ifNil: [ modelMetadata := self fetchModelMetadata ].
	^ modelMetadata
]

{ #category : 'accessing' }
CopilotSettings class >> modelName [
	"Answer the configured model name; default to Ollama's default model."

	^ modelName ifNil: [ modelName := self defaultCompletionModelName ]
]

{ #category : 'accessing' }
CopilotSettings class >> modelName: aString [
	"Set the model name and clear cached metadata."

	modelName := aString.
	self clearCachedModelMetadata.
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> modelName: requestedModelName matchesInstalledModelName: installedModelName [

	| requested installed |
	requested := self canonicalModelNameForComparison: requestedModelName.
	installed := self canonicalModelNameForComparison: installedModelName.

	requested = installed ifTrue: [ ^ true ].
	(requested includesSubstring: ':') ifFalse: [
		^ installed = (requested , ':latest') ].
	^ false
]

{ #category : 'private' }
CopilotSettings class >> modelNameFromModelEntry: each [
	"Extract the name from a model entry (dictionary-like or plain string)."

	| name |
	name := each.
	(each respondsTo: #at:ifAbsent:) ifTrue: [
		name := each at: #name ifAbsent: [ each at: 'name' ifAbsent: [ nil ] ]
	].
	^ name
]

{ #category : 'accessing' }
CopilotSettings class >> modelNameStringFromMetadata: metadata [
	"Compute a safe string model name from metadata, falling back to current model name."

	| modelNameValue modelNameString |
	modelNameValue := metadata at: #model ifAbsent: [ self modelName ].
	modelNameString := modelNameValue ifNil: [ self modelName ].
	modelNameString isNil ifTrue: [ modelNameString := 'unknown-model' ].
	^ modelNameString asString
]

{ #category : 'settings' }
CopilotSettings class >> modelNamesFromResponse: response [
	"Extract model names from an Ollama listModels response."

	| models names |
	response ifNil: [ ^ #() ].
	(response respondsTo: #at:ifAbsent:) ifFalse: [ ^ #() ].

	models := response at: #models ifAbsent: [ response at: 'models' ifAbsent: [ #() ] ].
	(models respondsTo: #do:) ifFalse: [ ^ #() ].

	names := OrderedCollection new.
	models do: [ :each |
		| extracted |
		extracted := self modelNameFromModelEntry: each.
		extracted ifNotNil: [ names add: extracted ]
	].

	^ names asArray
]

{ #category : 'accessing' }
CopilotSettings class >> modelNamesTextFor: modelNames [
	"Answer a bullet list text for the given model names."

	^ String streamContents: [ :stream |
		modelNames
			do: [ :each |
				stream
					nextPutAll: '- ';
					nextPutAll: each asString ]
			separatedBy: [ stream cr ] ]
]

{ #category : 'accessing' }
CopilotSettings class >> modelParameters [
	"Answer the model parameters metadata string."

	^ self metadataStringForKey: #parameters default: 'Not provided by model.'
]

{ #category : 'accessing' }
CopilotSettings class >> modelParameters: ignored [
	"Ignore attempts to set read-only metadata from the settings UI."
]

{ #category : 'accessing' }
CopilotSettings class >> modelSystemPrompt [
	"Answer the model system prompt metadata string."

	^ self metadataStringForKey: #system default: 'Not provided by model.'
]

{ #category : 'accessing' }
CopilotSettings class >> modelSystemPrompt: ignored [
	"Ignore attempts to set read-only metadata from the settings UI."
]

{ #category : 'settings' }
CopilotSettings class >> modelSystemPromptIfAvailable [
	"Answer the system prompt if one is provided by the model, otherwise answer an empty string."

	| prompt |
	prompt := self modelSystemPrompt.
	(prompt isNil or: [ prompt isEmpty or: [ prompt = 'Not provided by model.' ] ]) ifTrue: [ ^ '' ].
	^ prompt
]

{ #category : 'accessing' }
CopilotSettings class >> modelTemplate [
	"Answer the model template metadata string."

	^ self metadataStringForKey: #template default: 'Not provided by model.'
]

{ #category : 'accessing' }
CopilotSettings class >> modelTemplate: ignored [
	"Ignore attempts to set read-only metadata from the settings UI."
]

{ #category : 'accessing' }
CopilotSettings class >> newOllamaClient [
	"Create a new client instance using the configured factory."

	^ self ollamaClientFactory value
]

{ #category : 'settings' }
CopilotSettings class >> notifyUser: aString [
	"Display a message to the user (UIManager if available, otherwise Transcript)."

	(self notifyViaUIManager: aString) ifTrue: [ ^ self ].
	self notifyViaTranscript: aString
]

{ #category : 'settings' }
CopilotSettings class >> notifyViaTranscript: aString [
	"Write a message to Transcript if available; answer whether it was written."

	| transcript |
	transcript := Smalltalk globals at: #Transcript ifAbsent: [ nil ].
	transcript ifNil: [ ^ false ].
	(transcript respondsTo: #show:) ifFalse: [ ^ false ].

	transcript show: aString; cr.
	^ true
]

{ #category : 'settings' }
CopilotSettings class >> notifyViaUIManager: aString [
	"Show a message via UIManager if possible; answer whether it was shown."

	| uiClass uiManager |
	uiClass := Smalltalk globals at: #UIManager ifAbsent: [ nil ].
	uiClass ifNil: [ ^ false ].
	(uiClass respondsTo: #default) ifFalse: [ ^ false ].

	uiManager := uiClass default.
	(uiManager respondsTo: #inform:) ifFalse: [ ^ false ].

	uiManager inform: aString.
	^ true
]

{ #category : 'accessing' }
CopilotSettings class >> nullModelFullName [
	"Answer the full name of the placeholder/null model."

	^ CoPCOllamaClient nullModelFullName
]

{ #category : 'accessing' }
CopilotSettings class >> nullModelMetadata [
	"Answer placeholder metadata for the null model (used when Copilot is not configured)."

	| details modelfile |
	details := Dictionary new
		at: #family put: 'pharo-copilot';
		at: #description put: 'Placeholder metadata for the Pharo Copilot null model. Configure an Ollama model to enable completions.';
		at: #status put: 'inactive';
		yourself.

	modelfile := String streamContents: [ :stream |
		stream nextPutAll: '# Modelfile placeholder for the Pharo Copilot null model'.
		stream nextPutAll: String crlf.
		stream nextPutAll: '# Configure an Ollama model in the settings to enable completions.'
	].

	^ Dictionary new
		at: #model put: self nullModelFullName;
		at: #details put: details;
		at: #modelfile put: modelfile;
		at: #system put: 'Pharo Copilot is not configured. This null model intentionally produces no output until a real Ollama model is selected.';
		at: #template put: 'No completion template is available because Pharo Copilot is not configured with an Ollama model.';
		yourself
]

{ #category : 'ollama' }
CopilotSettings class >> numCtx [
	"Answer the num_ctx parameter for Ollama (context window size). Default: 4096"

	^ numCtx ifNil: [ numCtx := 4096 ]
]

{ #category : 'ollama' }
CopilotSettings class >> numCtx: anIntegerOrNil [

	numCtx := anIntegerOrNil.
	self autoSaveSettings
]

{ #category : 'ollama' }
CopilotSettings class >> numPredict [
	"Answer the num_predict parameter for Ollama (max tokens to generate). Default: 32 keeps inline completions fast."

	^ numPredict ifNil: [ numPredict := 32 ]
]

{ #category : 'ollama' }
CopilotSettings class >> numPredict: anInteger [

	numPredict := anInteger.
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> ollamaClientFactory [
	"Answer the factory closure used to create Ollama clients; default constructs a new client."

	ollamaClientFactory ifNil: [ ollamaClientFactory := [ CoPCOllamaClient new ] ].
	^ ollamaClientFactory
]

{ #category : 'accessing' }
CopilotSettings class >> ollamaClientFactory: aBlockClosure [

	ollamaClientFactory := aBlockClosure.
	self clearCachedModelMetadata
]

{ #category : 'accessing' }
CopilotSettings class >> ollamaDownloadPageUrl [

	^ 'https://ollama.com/download'
]

{ #category : 'settings' }
CopilotSettings class >> performInstallOfModelNamed: aModelName usingInitialResponse: response [
	"Install the model and refresh available models; answer whether it became available."

	^ (self installModelNamed: aModelName)
		and: [ self refreshModelsAfterInstallOf: aModelName usingInitialResponse: response ]
]

{ #category : 'accessing' }
CopilotSettings class >> populateMetadata: metadata fromResponse: response [
	"Parse and copy key fields from an Ollama showModel response into the given dictionary."

	| keys details parsedResponse |
	response ifNil: [ ^ metadata ].

	parsedResponse := response.
	parsedResponse isString ifTrue: [
		[ parsedResponse := STONJSON fromString: parsedResponse ]
			on: Error do: [ ^ metadata ]
	].

	(parsedResponse respondsTo: #at:ifAbsent:) ifFalse: [ ^ metadata ].

	keys := #(#template #system #parameters #modelfile).
	keys do: [ :key |
		| value altKey |
		altKey := key asString.
		value := parsedResponse at: key ifAbsent: [ parsedResponse at: altKey ifAbsent: [ nil ] ].
		value ifNotNil: [ metadata at: key put: value ]
	].

	details := parsedResponse at: #details ifAbsent: [ parsedResponse at: 'details' ifAbsent: [ nil ] ].
	details ifNotNil: [ metadata at: #details put: details ].

	metadata
		at: #model
		put: (parsedResponse
			at: #model
			ifAbsent: [ parsedResponse at: 'model' ifAbsent: [ self modelName ] ]).

	^ metadata
]

{ #category : 'accessing' }
CopilotSettings class >> port [
	"Answer the configured Ollama port; default to 11434."

	^ port ifNil: [ port := 11434 ]
]

{ #category : 'accessing' }
CopilotSettings class >> port: aNumberOrString [

	port := aNumberOrString.
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> predefinedDownloadableModelNames [

	^ #(
		'pharo-llm/Qwen2.5-Coder-SFT:3b'
		'pharo-llm/Qwen2.5-Coder-SFT:q4_K_M'
	)
]

{ #category : 'accessing' }
CopilotSettings class >> predefinedDownloadableModelNamesText [

	^ self modelNamesTextFor: self predefinedDownloadableModelNames
]

{ #category : 'accessing' }
CopilotSettings class >> predefinedSetupModelNames [
	"Answer the fixed plugin setup model list that must exist in Ollama."

	^ self predefinedDownloadableModelNames asArray
]

{ #category : 'settings' }
CopilotSettings class >> promptToInstallMissingModelNamed: aModelName availableModels: availableModels [
	"Ask the user whether to install a missing model; answer true if accepted."

	| message confirmation |
	message := self installModelPromptMessageForModelNamed: aModelName.

	confirmation := self confirmViaUIManager: message.
	confirmation ifNil: [
		self notifyViaTranscript: message.
		^ false
	].

	^ confirmation
]

{ #category : 'settings' }
CopilotSettings class >> pullResultIndicatesFailure: pullResult [
	"Answer whether an Ollama pull response explicitly reports failure."

	| errorText parsedResponse |
	pullResult == false ifTrue: [ ^ true ].
	pullResult isNil ifTrue: [ ^ true ].

	pullResult isString ifTrue: [
		parsedResponse := [ STONJSON fromString: pullResult ] on: Error do: [ nil ].
		parsedResponse ifNil: [ ^ false ].
		^ self pullResultIndicatesFailure: parsedResponse ].

	(pullResult isKindOf: Dictionary) ifFalse: [ ^ false ].

	errorText := pullResult at: #error ifAbsent: [ pullResult at: 'error' ifAbsent: [ nil ] ].
	errorText ifNil: [ ^ false ].
	^ errorText asString trimBoth isEmpty not
]

{ #category : 'settings' }
CopilotSettings class >> recordInstallModelUserConsentForModelNamed: aModelName accepted: aBoolean [
	"Persist the most recent user consent decision and append it to the evaluation log."

	| consentRecord |
	consentRecord := Dictionary new
		at: #model put: aModelName;
		at: #accepted put: aBoolean;
		at: #timestamp put: DateAndTime now asString;
		yourself.

	installModelUserConsent := consentRecord.
	self autoSaveSettings.

	CoPharoCopilotLogger
		appendEvaluationEvent: 'model-install-consent'
		data: consentRecord
]

{ #category : 'accessing' }
CopilotSettings class >> recordPrivacyPolicyUserConsentAccepted: aBoolean [

	^ self recordResearchTelemetryConsentAccepted: aBoolean
]

{ #category : 'research telemetry' }
CopilotSettings class >> recordResearchTelemetryConsentAccepted: aBoolean [

	| consentRecord consentState |
	consentState := aBoolean = true ifTrue: [ #accepted ] ifFalse: [ #declined ].
	consentRecord := Dictionary new
		at: #consentSubject put: #anonymousResearchTelemetry;
		at: #consentPurpose put: 'Collect anonymous IDE interaction events for Pharo usage research.';
		at: #accepted put: aBoolean;
		at: #consentState put: consentState;
		at: #dataCollectionConsentState put: consentState;
		at: #screenRecordingConsentState put: self screenRecordingConsentState;
		at: #consentNotice put: self researchTelemetryFirstLaunchText;
		at: #consentDetails put: self researchTelemetryLearnMoreText;
		at: #timestamp put: DateAndTime now asString;
		yourself.

	aBoolean = true
		ifTrue: [
			researchTelemetryConsentState := #accepted.
			loggingEnabled := true.
			self autoSaveSettings.
			CoPharoCopilotLogger
				appendConsentEvent: 'research-telemetry-consent'
				data: consentRecord ]
		ifFalse: [
			researchTelemetryConsentState := #declined.
			loggingEnabled := false.
			self autoSaveSettings.
			CoPharoCopilotLogger
				appendConsentEvent: 'research-telemetry-consent'
				data: consentRecord ].

	^ consentRecord
]

{ #category : 'research telemetry' }
CopilotSettings class >> researchTelemetryAccepted [

	^ self researchTelemetryConsentState = #accepted
]

{ #category : 'research telemetry' }
CopilotSettings class >> researchTelemetryConsentState [
	"Answer the persisted consent state. Anything unknown is treated as declined."

	| normalized |
	normalized := researchTelemetryConsentState ifNil: [ #notAsked ].
	normalized := [ normalized asSymbol ] on: Error do: [ ^ #declined ].
	(#(#notAsked #declined #accepted) includes: normalized) ifFalse: [ ^ #declined ].
	^ normalized
]

{ #category : 'research telemetry' }
CopilotSettings class >> researchTelemetryDeclined [

	^ self researchTelemetryConsentState = #declined
]

{ #category : 'research telemetry' }
CopilotSettings class >> researchTelemetryDisabledStatusText [

	^ 'Anonymous research telemetry is disabled.', String cr,
		'Pharo Copilot is not sending research telemetry about your IDE interactions.'
]

{ #category : 'research telemetry' }
CopilotSettings class >> researchTelemetryEnabledStatusText [

	^ 'Anonymous research telemetry is enabled.', String cr,
		'Pharo Copilot is contributing anonymous interaction events to the Pharo usage research project.', String cr,
		'The data is sent to an Inria-hosted research server and may become part of a public research dataset.'
]

{ #category : 'research telemetry' }
CopilotSettings class >> researchTelemetryFirstLaunchText [

	^ 'Pharo researchers and engineers are studying how developers use Pharo and its development tools.', String cr,
		'With your permission, Pharo Copilot can send anonymous interaction events about IDE tool usage to an Inria-hosted research server.', String cr,
		String cr,
		'- Participation is voluntary.', String cr,
		'- Telemetry is OFF by default.', String cr,
		'- No research telemetry is sent unless you explicitly agree.', String cr,
		'- Events describe tool interactions, not your source-code contents.', String cr,
		'- Anonymous submitted data may become part of a public research dataset.', String cr,
		'- You can disable telemetry later in Settings.'
]

{ #category : 'research telemetry' }
CopilotSettings class >> researchTelemetryLearnMoreText [

	^ 'About the Pharo Usage Research Project', String cr,
		String cr,
		'Why collect this data?', String cr,
		'Researchers have limited quantitative information about how Pharo development tools are used in real projects. Anonymous telemetry can help improve existing tools, evaluate new features, and support reproducible software-engineering research.', String cr,
		String cr,
		'What may be collected?', String cr,
		'Anonymous interaction events such as opening development tools, opening debugger windows, using debugger actions and buttons, browsing code, using IDE commands, copy/paste interaction events, interacting with Pharo libraries and tools, and using newly introduced Pharo features.', String cr,
		String cr,
		'Events may include a UTC timestamp, a randomly generated identifier, an interaction type, and references linking related events when necessary.', String cr,
		String cr,
		'What is not intended to be collected?', String cr,
		'Your name, email address, account credentials, passwords, authentication tokens, sensitive personal information, or source-code contents.', String cr,
		String cr,
		'Where does the data go?', String cr,
		'If you agree, telemetry is transmitted to infrastructure hosted by Inria. The collected data may be used to create an anonymous public research dataset about Pharo development practices.', String cr,
		String cr,
		'Can you withdraw?', String cr,
		'Yes. You can disable telemetry at any time from Pharo Copilot settings. Disabling telemetry stops future collection and transmission. Because submitted events are anonymous, previously submitted events may not be individually removable.', String cr,
		String cr,
		'Who is responsible?', String cr,
		'Members of the Pharo Consortium and researchers from Inria''s EVREF team.', String cr,
		String cr,
		'Questions: dpo@inria.fr'
]

{ #category : 'research telemetry' }
CopilotSettings class >> researchTelemetryNotAsked [

	^ self researchTelemetryConsentState = #notAsked
]

{ #category : 'research telemetry' }
CopilotSettings class >> requestDisableAnonymousResearchTelemetry [

	self researchTelemetryAccepted ifFalse: [
		self recordResearchTelemetryConsentAccepted: false.
		^ false ].

	(self confirmViaUIManager: self researchTelemetryDisablePrompt) = true ifFalse: [ ^ true ].
	self recordResearchTelemetryConsentAccepted: false.
	self notifyUser: 'Anonymous research telemetry disabled', String cr,
		'Pharo Copilot will no longer collect or transmit research telemetry.'.
	^ false
]

{ #category : 'research telemetry' }
CopilotSettings class >> requestEnableAnonymousResearchTelemetry [

	(self confirmViaUIManager: self researchTelemetryEnablePrompt) = true ifFalse: [
		self declineResearchTelemetryIfNotAsked.
		^ false ].
	self recordResearchTelemetryConsentAccepted: true.
	self notifyUser: 'Thank you for participating', String cr,
		'Anonymous research telemetry is now enabled.', String cr,
		'You can disable it at any time from Pharo Copilot settings.'.
	^ true
]

{ #category : 'research telemetry' }
CopilotSettings class >> researchTelemetryDisablePrompt [

	^ 'Disable anonymous research telemetry?', String cr,
		String cr,
		'Pharo Copilot will stop collecting and transmitting future research telemetry.', String cr,
		'Data already anonymously submitted may remain in the research dataset because it cannot be linked back to you.'
]

{ #category : 'research telemetry' }
CopilotSettings class >> researchTelemetryEnablePrompt [

	^ 'Enable anonymous research telemetry?', String cr,
		String cr,
		'By enabling this option, you agree that Pharo Copilot may collect anonymous interaction events describing how you use Pharo development tools.', String cr,
		'The data will be transmitted to an Inria-hosted research server and may later become part of a public research dataset.', String cr,
		'Participation is voluntary and you can disable telemetry again at any time.', String cr,
		'Data already anonymously submitted may not be individually removable because it cannot be linked back to you.'
]

{ #category : 'research telemetry' }
CopilotSettings class >> showResearchTelemetryStudyInformation [

	| message uiClass uiManager |
	message := self researchTelemetryLearnMoreText.
	uiClass := Smalltalk globals at: #UIManager ifAbsent: [ nil ].
	uiClass ifNotNil: [
		(uiClass respondsTo: #default) ifTrue: [
			uiManager := uiClass default.
			(uiManager respondsTo: #longMessage:title:)
				ifTrue: [
					^ uiManager
						longMessage: message
						title: 'Anonymous Usage Research' ].
			(uiManager respondsTo: #inform:)
				ifTrue: [ ^ uiManager inform: message ] ] ].

	self notifyViaTranscript: message
]

{ #category : 'research telemetry' }
CopilotSettings class >> showResearchTelemetryStudyInformationSetting [

	^ false
]

{ #category : 'research telemetry' }
CopilotSettings class >> showResearchTelemetryStudyInformationSetting: aBoolean [

	aBoolean ifTrue: [ self showResearchTelemetryStudyInformation ]
]

{ #category : 'screen recording' }
CopilotSettings class >> screenRecordingAccepted [

	^ self screenRecordingConsentState = #accepted
]

{ #category : 'screen recording' }
CopilotSettings class >> screenRecordingConsentState [
	"Answer the persisted screen recording consent state. Anything unknown is treated as declined."

	| normalized |
	normalized := screenRecordingConsentState ifNil: [ #notAsked ].
	normalized := [ normalized asSymbol ] on: Error do: [ ^ #declined ].
	(#(#notAsked #declined #accepted) includes: normalized) ifFalse: [ ^ #declined ].
	^ normalized
]

{ #category : 'screen recording' }
CopilotSettings class >> screenRecordingDeclined [

	^ self screenRecordingConsentState = #declined
]

{ #category : 'screen recording' }
CopilotSettings class >> screenRecordingDisabledStatusText [

	^ 'Screen recording is disabled.', String cr,
	'Pharo Copilot is not recording your screen.'
]

{ #category : 'screen recording' }
CopilotSettings class >> screenRecordingEnabledStatusText [

	^ 'Screen recording is enabled.', String cr,
	'Screen recordings may help researchers understand how developers work with AI code completion.',
	'A recording may capture source code or other information visible in your Pharo environment.',
	String cr,
	'Raw videos are stored on Inria-hosted research infrastructure and are not made public.'
]

{ #category : 'screen recording' }
CopilotSettings class >> screenRecordingFirstLaunchText [

	^ 'Screen recordings can help researchers understand how developers work with AI code completion in real coding sessions.', String cr,
	String cr,
	'- Screen recording is optional.', String cr,
	'- A recording may capture source code or other information visible in your Pharo environment.', String cr,
	'- If you agree, videos are stored on Inria-hosted research infrastructure.', String cr,
	'- Access to raw videos is limited to authorized members of the Pharo Consortium and Inria EVREF team.', String cr,
	'- Raw videos will not be made public.', String cr,
	'- Screen recording is not enabled unless you explicitly agree.', String cr,
	'- You can disable screen recording later in Settings.'
]

{ #category : 'screen recording' }
CopilotSettings class >> screenRecordingLearnMoreText [

	^ 'About Screen Recording', String cr,
	String cr,
	'Why record the screen?', String cr,
	'Screen recordings help researchers observe how developers interact with AI code completion during real coding sessions. This qualitative data complements the anonymous interaction telemetry.', String cr,
	String cr,
	'What may be visible in a recording?', String cr,
	'A screen recording captures whatever is visible on your Pharo screen during the session. This may include source code, variable names, comments, and other on-screen information.', String cr,
	String cr,
	'What is not intended to be collected?', String cr,
	'Your name, email address, account credentials, passwords, or authentication tokens.', String cr,
	String cr,
	'Where are recordings stored and who can see them?', String cr,
	'If you agree, screen recordings are transmitted to and stored on Inria-hosted research infrastructure. Access to the raw video files is limited to authorized members of the Pharo Consortium and Inria EVREF team who need them for research analysis, data handling, or infrastructure operations.', String cr,
	String cr,
	'Will recordings be made public?', String cr,
	'No. The raw screen recording videos will not be made public and will not be included in a public dataset. Research publications or shared datasets may use aggregated findings or anonymized derived data, but not the video files themselves.', String cr,
	String cr,
	'Can you withdraw?', String cr,
	'Yes. You can disable screen recording at any time from Pharo Copilot settings. Disabling screen recording stops future recordings. Previously recorded sessions may already have been processed.', String cr,
	String cr,
	'Who is responsible?', String cr,
	'Members of the Pharo Consortium and researchers from Inria''s EVREF team.', String cr,
	String cr,
	'Questions: dpo@inria.fr'
]

{ #category : 'screen recording' }
CopilotSettings class >> screenRecordingNotAsked [

	^ self screenRecordingConsentState = #notAsked
]

{ #category : 'screen recording' }
CopilotSettings class >> recordScreenRecordingConsentAccepted: aBoolean [

	| consentRecord consentState |
	consentState := aBoolean = true ifTrue: [ #accepted ] ifFalse: [ #declined ].
	consentRecord := Dictionary new
		at: #consentSubject put: #screenRecording;
		at: #consentPurpose put: 'Record the Pharo screen during coding sessions for research analysis.';
		at: #accepted put: aBoolean;
		at: #consentState put: consentState;
		at: #dataCollectionConsentState put: self researchTelemetryConsentState;
		at: #screenRecordingConsentState put: consentState;
		at: #consentNotice put: self screenRecordingFirstLaunchText;
		at: #consentDetails put: self screenRecordingLearnMoreText;
		at: #timestamp put: DateAndTime now asString;
		yourself.

	aBoolean = true
		ifTrue: [
			screenRecordingConsentState := #accepted.
			self autoSaveSettings.
			CoPharoCopilotLogger
				appendConsentEvent: 'screen-recording-consent'
				data: consentRecord ]
		ifFalse: [
			screenRecordingConsentState := #declined.
			self autoSaveSettings.
			CoPharoCopilotLogger
				appendConsentEvent: 'screen-recording-consent'
				data: consentRecord ].

	^ consentRecord
]

{ #category : 'settings' }
CopilotSettings class >> refreshModelsAfterInstallOf: aModelName usingInitialResponse: initialResponse [
	"Re-list models after an install and verify the target model is present; answer true if found."

	| refreshedModels attempts |
	refreshedModels := #().
	attempts := 10.

	1 to: attempts do: [ :attempt |
		[
			| client refreshedResponse |
			client := self newOllamaClient.
			refreshedResponse := client listModels.
			refreshedModels := self modelNamesFromResponse: refreshedResponse.

			(self installedModelNames: refreshedModels includesModelNamed: aModelName)
				ifTrue: [
					self logDetectedInstalledModel: aModelName before: initialResponse after: refreshedModels.
					[ CoPCModelRegistry refresh ] on: Error do: [ :ignored | ].
					^ true ].

			(self showModelConfirmsInstalled: aModelName usingClient: client)
				ifTrue: [
					self logDetectedInstalledModel: aModelName before: initialResponse after: refreshedModels.
					[ CoPCModelRegistry refresh ] on: Error do: [ :ignored | ].
					^ true ].

			attempt < attempts ifTrue: [ (Delay forMilliseconds: 500) wait ]
		] on: Error do: [ :ex |
			attempt = attempts
				ifTrue: [
					CoPharoCopilotLogger
						logError: 'Failed to refresh Ollama models after install'
						origin: #CopilotSettings
						exception: ex
						payload: (Dictionary new
							at: #model put: aModelName;
							yourself) ]
				ifFalse: [ (Delay forMilliseconds: 500) wait ] ] ].

	self logInstallDidNotExposeModel: aModelName before: initialResponse after: refreshedModels.

	^ false
]

{ #category : 'accessing' }
CopilotSettings class >> removeMetadataTextFilesFrom: aDirectory [
	"Remove previously written .txt metadata files from the given directory (best-effort)."

	(aDirectory exists) ifFalse: [ ^ self ].

	[
		aDirectory children do: [ :child |
			(child isFile and: [ ((child extension ifNil: [ '' ]) asLowercase) = 'txt' ])
				ifTrue: [ [ child ensureDelete ] on: Error do: [ :ignored | ] ]
		]
	] on: Error do: [ :ignored | ].
]

{ #category : 'ollama' }
CopilotSettings class >> repeatPenalty [

	^ repeatPenalty ifNil: [ repeatPenalty := 1.1 ]
]

{ #category : 'ollama' }
CopilotSettings class >> repeatPenalty: aNumber [

	repeatPenalty := aNumber.
	self autoSaveSettings
]

{ #category : 'settings' }
CopilotSettings class >> requestTimeoutSeconds [

	^ requestTimeoutSeconds ifNil: [ requestTimeoutSeconds := 60 ]
]

{ #category : 'settings' }
CopilotSettings class >> requestTimeoutSeconds: anObject [

	requestTimeoutSeconds := anObject.
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> resetToDefaultSettings [
	"Reset all settings to defaults (by clearing class-side state)."
<script>
	self initializeDefaults.
	CoPCContextSettings initializeDefaults
]

{ #category : 'persistence' }
CopilotSettings class >> restoreSettingsFromSerializableSnapshot: aDictionary [

	| templatesPath |

	self initializeDefaults.

	enabled := self valueAt: #enabled from: aDictionary default: enabled.
	provider := self valueAt: #provider from: aDictionary default: provider.
	modelName := self valueAt: #modelName from: aDictionary default: modelName.
	host := self valueAt: #host from: aDictionary default: host.
	port := self valueAt: #port from: aDictionary default: port.
	autoInstallModelScriptEnabled := self valueAt: #autoInstallModelScriptEnabled from: aDictionary default: autoInstallModelScriptEnabled.
	loggingEnabled := self valueAt: #loggingEnabled from: aDictionary default: loggingEnabled.
	completionDebounceMilliseconds := self valueAt: #completionDebounceMilliseconds from: aDictionary default: completionDebounceMilliseconds.
	completionIdleMilliseconds := self valueAt: #completionIdleMilliseconds from: aDictionary default: completionIdleMilliseconds.
	requestTimeoutSeconds := self valueAt: #requestTimeoutSeconds from: aDictionary default: requestTimeoutSeconds.
	modelInstallTimeoutSeconds := self valueAt: #modelInstallTimeoutSeconds from: aDictionary default: modelInstallTimeoutSeconds.
	temperature := self valueAt: #temperature from: aDictionary default: temperature.
	topP := self valueAt: #topP from: aDictionary default: topP.
	topK := self valueAt: #topK from: aDictionary default: topK.
	numPredict := self valueAt: #numPredict from: aDictionary default: numPredict.
	repeatPenalty := self valueAt: #repeatPenalty from: aDictionary default: repeatPenalty.
	numCtx := self valueAt: #numCtx from: aDictionary default: numCtx.
	seed := self valueAt: #seed from: aDictionary default: seed.
	modelKeepAlive := self valueAt: #modelKeepAlive from: aDictionary default: modelKeepAlive.
	customParameters := self dictionaryValueAt: #customParameters from: aDictionary default: customParameters.
	maxInstanceMethods := self valueAt: #maxInstanceMethods from: aDictionary default: maxInstanceMethods.
	maxClassMethods := self valueAt: #maxClassMethods from: aDictionary default: maxClassMethods.
	minimumPrefixLength := self valueAt: #minimumPrefixLength from: aDictionary default: minimumPrefixLength.
	completionSuggestionsCount := self valueAt: #completionSuggestionsCount from: aDictionary default: completionSuggestionsCount.
	completionLogprobsEnabled := self valueAt: #completionLogprobsEnabled from: aDictionary default: completionLogprobsEnabled.
	completionTopLogprobs := self valueAt: #completionTopLogprobs from: aDictionary default: completionTopLogprobs.
	backgroundColor := self valueAt: #backgroundColor from: aDictionary default: backgroundColor.
	installModelUserConsent := self valueAt: #installModelUserConsent from: aDictionary default: installModelUserConsent.
	imageCloseSurveyEnabled := self valueAt: #imageCloseSurveyEnabled from: aDictionary default: imageCloseSurveyEnabled.
	researchTelemetryConsentState := self valueAt: #researchTelemetryConsentState from: aDictionary default: researchTelemetryConsentState.
	screenRecordingConsentState := self valueAt: #screenRecordingConsentState from: aDictionary default: screenRecordingConsentState.

	templatesPath := aDictionary at: #templatesDirectory ifAbsent: [ nil ].
	templatesPath = nil ifFalse: [
		templatesDirectory := templatesPath asFileReference
	].
	(aDictionary at: #contextMode ifAbsent: [ nil ])
		ifNotNil: [ :savedMode | CoPCContextSettings mode: savedMode ].
	(aDictionary at: #navigationHistoryEnabled ifAbsent: [ nil ])
		ifNotNil: [ :savedFlag | CoPCContextNavigationHistory enabled: savedFlag ].
	self upgradeLegacyCompletionDefaults.
	self ensureDefaultCompletionModelSelected
]

{ #category : 'accessing' }
CopilotSettings class >> restoreSettingsFromSnapshot: aDictionary [
	"Restore settings from a snapshot produced by #settingsSnapshot."

	enabled := aDictionary at: #enabled ifAbsent: [ aDictionary at: #Enabled ifAbsent: [ nil ] ].
	provider := aDictionary at: #provider ifAbsent: [ aDictionary at: #Provider ifAbsent: [ nil ] ].
	modelName := aDictionary at: #modelName ifAbsent: [ aDictionary at: #ModelName ifAbsent: [ nil ] ].
	host := aDictionary at: #host ifAbsent: [ aDictionary at: #Host ifAbsent: [ nil ] ].
	port := aDictionary at: #port ifAbsent: [ aDictionary at: #Port ifAbsent: [ nil ] ].
	modelMetadata := aDictionary at: #modelMetadata ifAbsent: [ aDictionary at: #ModelMetadata ifAbsent: [ nil ] ].
	ollamaClientFactory := aDictionary at: #ollamaClientFactory ifAbsent: [ aDictionary at: #OllamaClientFactory ifAbsent: [ nil ] ].
	autoInstallModelScriptEnabled := aDictionary
		                                 at: #autoInstallModelScriptEnabled
		                                 ifAbsent: [ aDictionary at: #AutoInstallModelScriptEnabled ifAbsent: [ nil ] ].
	loggingEnabled := aDictionary at: #loggingEnabled ifAbsent: [ aDictionary at: #LoggingEnabled ifAbsent: [ nil ] ].
	templatesDirectory := aDictionary at: #templatesDirectory ifAbsent: [ aDictionary at: #TemplatesDirectory ifAbsent: [ nil ] ].
	completionDebounceMilliseconds := aDictionary
		                                  at: #completionDebounceMilliseconds
		                                  ifAbsent: [ aDictionary at: #CompletionDebounceMilliseconds ifAbsent: [ nil ] ].
	completionIdleMilliseconds := aDictionary
		                              at: #completionIdleMilliseconds
		                              ifAbsent: [ aDictionary at: #CompletionIdleMilliseconds ifAbsent: [ nil ] ].
	requestTimeoutSeconds := aDictionary
		                         at: #requestTimeoutSeconds
		                         ifAbsent: [ aDictionary at: #RequestTimeoutSeconds ifAbsent: [ nil ] ].
	modelInstallTimeoutSeconds := aDictionary
		                              at: #modelInstallTimeoutSeconds
		                              ifAbsent: [ aDictionary at: #ModelInstallTimeoutSeconds ifAbsent: [ nil ] ].
	temperature := aDictionary at: #temperature ifAbsent: [ nil ].
	topP := aDictionary at: #topP ifAbsent: [ nil ].
	topK := aDictionary at: #topK ifAbsent: [ nil ].
	numPredict := aDictionary at: #numPredict ifAbsent: [ nil ].
	repeatPenalty := aDictionary at: #repeatPenalty ifAbsent: [ nil ].
	numCtx := aDictionary at: #numCtx ifAbsent: [ nil ].
	seed := aDictionary at: #seed ifAbsent: [ nil ].
	modelKeepAlive := aDictionary at: #modelKeepAlive ifAbsent: [ nil ].
	customParameters := aDictionary at: #customParameters ifAbsent: [ Dictionary new ].
	maxInstanceMethods := aDictionary at: #maxInstanceMethods ifAbsent: [ aDictionary at: #MaxInstanceMethods ifAbsent: [ nil ] ].
	maxClassMethods := aDictionary at: #maxClassMethods ifAbsent: [ aDictionary at: #MaxClassMethods ifAbsent: [ nil ] ].
	minimumPrefixLength := aDictionary at: #minimumPrefixLength ifAbsent: [ aDictionary at: #MinimumPrefixLength ifAbsent: [ nil ] ].
completionSuggestionsCount := aDictionary at: #completionSuggestionsCount ifAbsent: [ aDictionary at: #CompletionSuggestionsCount ifAbsent: [ nil ] ].
completionLogprobsEnabled := aDictionary at: #completionLogprobsEnabled ifAbsent: [ aDictionary at: #CompletionLogprobsEnabled ifAbsent: [ nil ] ].
completionTopLogprobs := aDictionary at: #completionTopLogprobs ifAbsent: [ aDictionary at: #CompletionTopLogprobs ifAbsent: [ nil ] ].
backgroundColor := aDictionary at: #backgroundColor ifAbsent: [ aDictionary at: #BackgroundColor ifAbsent: [ nil ] ].
installModelUserConsent := aDictionary at: #installModelUserConsent ifAbsent: [ aDictionary at: #InstallModelUserConsent ifAbsent: [ nil ] ].
imageCloseSurveyEnabled := aDictionary at: #imageCloseSurveyEnabled ifAbsent: [ aDictionary at: #ImageCloseSurveyEnabled ifAbsent: [ nil ] ].
researchTelemetryConsentState := aDictionary at: #researchTelemetryConsentState ifAbsent: [ aDictionary at: #ResearchTelemetryConsentState ifAbsent: [ nil ] ].
screenRecordingConsentState := aDictionary at: #screenRecordingConsentState ifAbsent: [ aDictionary at: #ScreenRecordingConsentState ifAbsent: [ nil ] ].
self useDefaultCompletionModelWhenSavedModelIsMissingOrNull
]

{ #category : 'accessing' }
CopilotSettings class >> sanitizedFileComponentFor: anObject default: defaultString [
	"Convert a value into a safe filename component, falling back to the default."

	| candidate |
	anObject isNil ifTrue: [ ^ defaultString asFileName ].

	candidate := [ anObject asString ] on: Error do: [ anObject printString ].
	(candidate isNil or: [ candidate isEmpty ]) ifTrue: [ ^ defaultString asFileName ].

	^ candidate asFileName
]

{ #category : 'accessing' }
CopilotSettings class >> saveModelMetadataFilesFor: metadata [
	"Write model metadata to per-model .txt files under the logs directory (best-effort)."

	| modelNameString modelDirectory |
	(self loggingEnabled and: [ metadata notNil ]) ifFalse: [ ^ self ].
	metadata isEmpty ifTrue: [ ^ self ].

	modelNameString := self modelNameStringFromMetadata: metadata.
	modelDirectory := self ensureModelMetadataDirectoryFor: modelNameString.
	modelDirectory ifNil: [ ^ self ].

	self removeMetadataTextFilesFrom: modelDirectory.
	self writeMetadata: metadata toDirectory: modelDirectory modelName: modelNameString
]

{ #category : 'persistence' }
CopilotSettings class >> saveSettingsToFile [
	"Save current settings to the persistent STON file."

	| fileRef snapshot stonString |
	fileRef := self settingsFileReference.
	snapshot := self serializableSettingsSnapshot.
	stonString := STON toString: snapshot.

	fileRef parent ifNotNil: [ :parent | parent ensureCreateDirectory ].
	fileRef ensureCreateFile.
	fileRef writeStreamDo: [ :stream |
		stream truncate.
		stream nextPutAll: stonString
	].
]

{ #category : 'ollama' }
CopilotSettings class >> seed [
	"Answer the seed parameter for Ollama (for reproducible generation). Default: nil (random)"

	^ seed ifNil: [ 0 ]
]

{ #category : 'ollama' }
CopilotSettings class >> seed: anIntegerOrNil [

	seed := anIntegerOrNil.
	self autoSaveSettings
]

{ #category : 'persistence' }
CopilotSettings class >> serializableSettingsSnapshot [
	"Create a snapshot that can be serialized to STON (excludes closures and complex objects)."

	| snapshot templatesPath |
	snapshot := Dictionary new
		            at: #enabled put: enabled;
		            at: #provider put: provider;
		            at: #modelName put: modelName;
		            at: #host put: host;
		            at: #port put: port;
		            at: #autoInstallModelScriptEnabled put: autoInstallModelScriptEnabled;
		            at: #loggingEnabled put: loggingEnabled;
		            at: #completionDebounceMilliseconds put: completionDebounceMilliseconds;
		            at: #completionIdleMilliseconds put: completionIdleMilliseconds;
		            at: #requestTimeoutSeconds put: requestTimeoutSeconds;
		            at: #modelInstallTimeoutSeconds put: modelInstallTimeoutSeconds;
		            at: #temperature put: temperature;
		            at: #topP put: topP;
		            at: #topK put: topK;
		            at: #numPredict put: numPredict;
		            at: #repeatPenalty put: repeatPenalty;
		            at: #numCtx put: numCtx;
		            at: #seed put: seed;
		            at: #modelKeepAlive put: modelKeepAlive;
		            at: #customParameters put: (customParameters ifNil: [ Dictionary new ]);
		            at: #maxInstanceMethods put: maxInstanceMethods;
		            at: #maxClassMethods put: maxClassMethods;
		            at: #minimumPrefixLength put: minimumPrefixLength;
		            at: #contextMode put: CoPCContextSettings mode;
		at: #navigationHistoryEnabled put: CoPCContextNavigationHistory enabled;
		            at: #completionSuggestionsCount put: completionSuggestionsCount;
		            at: #completionLogprobsEnabled put: completionLogprobsEnabled;
		            at: #completionTopLogprobs put: completionTopLogprobs;
		            at: #backgroundColor put: backgroundColor;
		at: #installModelUserConsent put: installModelUserConsent;
		at: #imageCloseSurveyEnabled put: imageCloseSurveyEnabled;
		at: #researchTelemetryConsentState put: self researchTelemetryConsentState;
		at: #screenRecordingConsentState put: self screenRecordingConsentState;
		            yourself.
	templatesDirectory ifNotNil: [
			templatesPath := [ templatesDirectory pathString ]
				                 on: Error
				                 do: [ nil ].
			templatesPath ifNotNil: [ snapshot at: #templatesDirectory put: templatesPath ] ].

	^ snapshot
]

{ #category : 'ollama' }
CopilotSettings class >> setCustomParameter: aKey value: aValue [
	"Set a single custom parameter."

	self customParameters at: aKey put: aValue.
	self autoSaveSettings
]

{ #category : 'persistence' }
CopilotSettings class >> settingsFileReference [
	"Answer the file reference for the persistent settings file."

	| logsDirectory |
	logsDirectory := CoPharoCopilotLogger ensureLogsDirectory.
	^ logsDirectory / 'settings.ston'

]

{ #category : 'ui' }
CopilotSettings class >> settingsOn: aBuilder [
	"Register Copilot settings in the system settings UI."

	<systemsettings>
	(aBuilder setting: #CopilotSettings)
		target: self;
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
					target: self;
					getSelector: #copilotProvider;
					setSelector: #copilotProvider:;
					domainValues: self availableProviders.

				(aBuilder pickOne: #modelName)
					label: 'Model';
					target: self;
					getSelector: #modelName;
					setSelector: #modelName:;
					default: self modelName;
					domainValues: self availableModelNames.

				(aBuilder setting: #anonymousResearchTelemetryEnabled)
					order: 0.3;
					label: 'Anonymous usage research';
					target: self;
					getSelector: #anonymousResearchTelemetryEnabled;
					setSelector: #anonymousResearchTelemetryEnabled:;
					default: false;
					description: 'OFF by default. When enabled, Pharo Copilot sends anonymous IDE interaction events to an Inria-hosted research server for the Pharo usage research project. You can disable it at any time.'.

				(aBuilder setting: #showResearchTelemetryStudyInformationSetting)
					order: 0.31;
					label: 'Learn more about usage research';
					target: self;
					getSelector: #showResearchTelemetryStudyInformationSetting;
					setSelector: #showResearchTelemetryStudyInformationSetting:;
					default: false;
					description: 'Show the anonymous usage research purpose, data limits, destination, public dataset note, and withdrawal information.'.

				(aBuilder setting: #imageCloseSurveyEnabled)
					order: 0.35;
					label: 'Ask for feedback on image close';
					target: self;
					getSelector: #imageCloseSurveyEnabled;
					setSelector: #imageCloseSurveyEnabled:;
					default: self imageCloseSurveyEnabled;
					description: 'Only active when anonymous usage research is enabled. When enabled, Copilot asks a short feedback form before the Pharo image quits.'.

				(aBuilder setting: #autoInstallModelScriptEnabled)
					order: 0.4;
					label: 'Auto-install Pharo coder model';
					target: self;
					getSelector: #autoInstallModelScriptEnabled;
					setSelector: #autoInstallModelScriptEnabled:;
					default: self autoInstallModelScriptEnabled;
					description:
						'When enabled, Pharo Copilot automatically downloads the selected model when it is missing from your Ollama installation.'.

				(aBuilder setting: #installSelectedModelNowSetting)
					order: 0.45;
					label: 'Install selected model now';
					target: self;
					getSelector: #installSelectedModelNowSetting;
					setSelector: #installSelectedModelNowSetting:;
					description: 'Manually pull the currently selected Ollama model.'.

				(aBuilder setting: #completionDebounceMilliseconds)
					order: 0.5;
					label: 'Completion debounce (ms)';
					target: self;
					getSelector: #completionDebounceMilliseconds;
					setSelector: #completionDebounceMilliseconds:;
					default: self completionDebounceMilliseconds;
					description: 'Milliseconds to wait after a boundary before requesting completions (0-60000).'.

				(aBuilder setting: #completionIdleMilliseconds)
					order: 0.6;
					label: 'Completion idle (ms)';
					target: self;
					getSelector: #completionIdleMilliseconds;
					setSelector: #completionIdleMilliseconds:;
					default: self completionIdleMilliseconds;
					description: 'Milliseconds to wait after typing stops before requesting completions (0-60000).'.

				(aBuilder pickOne: #contextMode)
					order: 0.65;
					label: 'Context mode';
					target: CoPCContextSettings;
					getSelector: #mode;
					setSelector: #mode:;
					default: CoPCContextSettings mode;
					domainValues: CoPCContextSettings availableModes;
					description: 'Controls whether completions use full source or selectors-only class context.'.


				(aBuilder setting: #navigationHistoryEnabled)
					order: 0.655;
					label: 'Include browser navigation history';
					target: CoPCContextSettings;
					getSelector: #navigationHistoryEnabled;
					setSelector: #navigationHistoryEnabled:;
					default: CoPCContextSettings navigationHistoryEnabled;
					description: 'When enabled, the current Calypso browser selection and recent navigation states are appended as the final context section before the FIM prompt sent to the model.'.
					
					
				(aBuilder setting: #maxInstanceMethods)
					order: 0.66;
					label: 'Max instance methods in context';
					target: self;
					getSelector: #maxInstanceMethods;
					setSelector: #maxInstanceMethods:;
					default: self maxInstanceMethods;
					description:
						'Maximum number of instance-side methods to include in the class context sent with completions (1-200). Default: 6'.

				(aBuilder setting: #maxClassMethods)
					order: 0.67;
					label: 'Max class methods in context';
					target: self;
					getSelector: #maxClassMethods;
					setSelector: #maxClassMethods:;
					default: self maxClassMethods;
					description:
						'Maximum number of class-side methods to include in the class context sent with completions (1-100). Default: 3'.

				(aBuilder setting: #minimumPrefixLength)
					order: 0.68;
					label: 'Minimum prefix length';
					target: self;
					getSelector: #minimumPrefixLength;
					setSelector: #minimumPrefixLength:;
					default: self minimumPrefixLength;
					description: 'Minimum number of characters typed before requesting a completion (1-20). Default: 3'.

				(aBuilder setting: #requestTimeoutSeconds)
					order: 0.7;
					label: 'Request timeout (sec)';
					target: self;
					getSelector: #requestTimeoutSeconds;
					setSelector: #requestTimeoutSeconds:;
					default: self requestTimeoutSeconds;
					description: 'Seconds to wait for Ollama responses before timing out (1-120).'.

	(aBuilder setting: #completionSuggestionsCount)
					order: 0.69;
					label: 'Completion suggestions';
					target: self;
					getSelector: #completionSuggestionsCount;
					setSelector: #completionSuggestionsCount:;
					default: self completionSuggestionsCount;
					description: 'How many completion alternatives to request per trigger (1-10).'.
					
				(aBuilder setting: #modelInstallTimeoutSeconds)
					order: 0.75;
					label: 'Model install timeout (sec)';
					target: self;
					getSelector: #modelInstallTimeoutSeconds;
					setSelector: #modelInstallTimeoutSeconds:;
					default: self modelInstallTimeoutSeconds;
					description: 'Seconds to wait for Ollama model downloads before timing out (30-3600).'.

				(aBuilder setting: #host)
					order: 1;
					label: 'Server host';
					target: self;
					getSelector: #host;
					setSelector: #host:;
					default: self host.

				(aBuilder setting: #port)
					order: 2;
					label: 'Server port';
					target: self;
					getSelector: #port;
					setSelector: #port:;
					default: self port.
					
				(aBuilder setting: #backgroundColor)
					order: 2.5;
					label: 'Background Color';
					target: self;
					getSelector: #backgroundColor;
					setSelector: #backgroundColor:;
					default: self defaultBackgroundColor;
					description: 'Background color for the Copilot completion popup menu.'.
				(aBuilder group: #ollamaParameters)
					order: 3;
					label: 'Ollama Parameters';
					description: 'Configure Ollama model parameters (temperature, top_p, etc.)';
					with: [
							(aBuilder setting: #temperature)
								order: 1;
								label: 'Temperature';
								target: self;
								getSelector: #temperature;
								setSelector: #temperature:;
								default: self temperature;
								description: 'Controls randomness in generation (0.0 = deterministic, 2.0 = very random). Default: 0.2 — low values give more reliable code completions.'.

							(aBuilder setting: #topP)
								order: 2;
								label: 'Top P (nucleus sampling)';
								target: self;
								getSelector: #topP;
								setSelector: #topP:;
								default: self topP;
								description: 'Nucleus sampling threshold (0.0 to 1.0). Default: 0.9'.

							(aBuilder setting: #topK)
								order: 3;
								label: 'Top K';
								target: self;
								getSelector: #topK;
								setSelector: #topK:;
								default: self topK;
								description: 'Limits token selection to top K candidates (1 to 100). Default: 40'.

							(aBuilder setting: #numPredict)
								order: 4;
								label: 'Max tokens to generate';
								target: self;
								getSelector: #numPredict;
								setSelector: #numPredict:;
								default: self numPredict;
								description: 'Maximum number of tokens to generate (1 to 2048). Default: 32. Lower values respond faster.'.

							(aBuilder setting: #repeatPenalty)
								order: 5;
								label: 'Repeat penalty';
								target: self;
								getSelector: #repeatPenalty;
								setSelector: #repeatPenalty:;
								default: self repeatPenalty;
								description: 'Penalizes repetition (0.0 to 2.0, higher = less repetition). Default: 1.1'.

							(aBuilder setting: #numCtx)
								order: 6;
								label: 'Context window size';
								target: self;
								getSelector: #numCtx;
								setSelector: #numCtx:;
								default: self numCtx;
								description: 'Context window size (512 to 32768, or leave empty for model default)'.

							(aBuilder setting: #seed)
								order: 7;
								label: 'Seed (for reproducibility)';
								target: self;
								getSelector: #seed;
								setSelector: #seed:;
								default: self seed;
								description: 'Random seed for reproducible generation (leave empty for random)' ] ]
]

{ #category : 'accessing' }
CopilotSettings class >> settingsSnapshot [
	"Capture all settings into a dictionary so they can be restored later."

	^ Dictionary new
		  at: #enabled put: enabled;
		  at: #provider put: provider;
		  at: #modelName put: modelName;
		  at: #host put: host;
		  at: #port put: port;
		  at: #modelMetadata put: modelMetadata;
		  at: #ollamaClientFactory put: ollamaClientFactory;
		  at: #autoInstallModelScriptEnabled put: autoInstallModelScriptEnabled;
		  at: #loggingEnabled put: loggingEnabled;
		  at: #templatesDirectory put: templatesDirectory;
		  at: #completionDebounceMilliseconds put: completionDebounceMilliseconds;
		  at: #completionIdleMilliseconds put: completionIdleMilliseconds;
		  at: #requestTimeoutSeconds put: requestTimeoutSeconds;
		  at: #modelInstallTimeoutSeconds put: modelInstallTimeoutSeconds;
		  at: #temperature put: temperature;
		  at: #topP put: topP;
		  at: #topK put: topK;
		  at: #numPredict put: numPredict;
		  at: #repeatPenalty put: repeatPenalty;
		  at: #numCtx put: numCtx;
		  at: #seed put: seed;
		  at: #modelKeepAlive put: modelKeepAlive;
		  at: #customParameters put: customParameters;
		  at: #maxInstanceMethods put: maxInstanceMethods;
		  at: #maxClassMethods put: maxClassMethods;
		  at: #minimumPrefixLength put: minimumPrefixLength;
		  at: #completionSuggestionsCount put: completionSuggestionsCount;
		  at: #completionLogprobsEnabled put: completionLogprobsEnabled;
		  at: #completionTopLogprobs put: completionTopLogprobs;
		  at: #backgroundColor put: backgroundColor;
		at: #installModelUserConsent put: installModelUserConsent;
		at: #imageCloseSurveyEnabled put: imageCloseSurveyEnabled;
		at: #researchTelemetryConsentState put: self researchTelemetryConsentState;
		at: #screenRecordingConsentState put: self screenRecordingConsentState;
		  yourself
]

{ #category : 'accessing' }
CopilotSettings class >> shouldAutoInstallModelNamed: aModelName [
	"Answer whether auto-install should run for the given model name."

	(self autoInstallModelScriptEnabled) ifFalse: [ ^ false ].
	aModelName ifNil: [ ^ false ].
	(aModelName respondsTo: #isEmpty) ifTrue: [ aModelName isEmpty ifTrue: [ ^ false ] ].
	(self isNullModelName: aModelName) ifTrue: [ ^ false ].
	^ true
]

{ #category : 'accessing' }
CopilotSettings class >> shouldShowDetailedSettings [
	"Answer whether detailed settings should be shown (currently: when Copilot is enabled)."

	^ self copilotEnabled
]

{ #category : 'accessing' }
CopilotSettings class >> showInstallCompletionDialog [
	"Show a friendly post-install message to the user."

	| message uiClass uiManager transcript |
	message := 'Pharo Copilot installed ' , String cr , 'Welcome to Pharo-Copilot' , String cr
		, 'Ollama runs your models locally, so none of your data is sent anywhere.' , String cr
		, 'Everything is already configured—just open your Browser and start typing.' , String cr
		, 'For more details, visit our documentation' , String cr.

	uiClass := Smalltalk globals at: #UIManager ifAbsent: [ nil ].
	uiClass ifNotNil: [
		(uiClass respondsTo: #default) ifTrue: [
			uiManager := uiClass default.
			(uiManager respondsTo: #longMessage:title:)
				ifTrue: [ ^ uiManager longMessage: message title: 'Pharo Copilot setup' ].
			(uiManager respondsTo: #inform:)
				ifTrue: [ ^ uiManager inform: message ]
		]
	].

	transcript := Smalltalk globals at: #Transcript ifAbsent: [ nil ].
	transcript ifNotNil: [
		(transcript respondsTo: #show:)
			ifTrue: [ transcript show: message; cr ]
	]
]

{ #category : 'settings' }
CopilotSettings class >> showModelConfirmsInstalled: aModelName usingClient: client [
	"Answer whether Ollama can resolve the model directly. This avoids reporting a
	completed pull as failed when the list endpoint lags behind the model store."

	| response |
	(client respondsTo: #showModelNamed:) ifFalse: [ ^ false ].

	response := [
		client showModelNamed: aModelName
	] on: Error do: [ ^ false ].

	response ifNil: [ ^ false ].
	^ (self pullResultIndicatesFailure: response) not
]

{ #category : 'settings' }
CopilotSettings class >> switchToNullModelDueToMissingOllamaFor: selectedModelName [

	self modelName: self nullModelFullName.
	self notifyUser: 'Ollama is not available. Pharo Copilot will use the null model until you configure an Ollama model.'
]

{ #category : 'ollama' }
CopilotSettings class >> temperature [
	"Answer the temperature parameter for Ollama (controls randomness). Default: 0.2 — low randomness suits code completion"

	^ temperature ifNil: [ temperature := 0.2 ]
]

{ #category : 'ollama' }
CopilotSettings class >> temperature: aNumber [

	temperature := aNumber.
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> templateFileForModelNamed: aModelName [
	"Answer the per-model cached template file reference under the logs directory."

	| modelNameValue sanitizedName baseDirectory |
	modelNameValue := aModelName ifNil: [ self modelName ].

	sanitizedName := self
		sanitizedFileComponentFor: modelNameValue
		default: 'unknown-model'.

	baseDirectory := CoPharoCopilotLogger logsDirectoryReference.
	^ (baseDirectory / sanitizedName / 'template.txt') asFileReference
]

{ #category : 'accessing' }
CopilotSettings class >> templatesDirectory [
	"Answer the directory that contains bundled templates."

	^ templatesDirectory ifNil: [
		templatesDirectory := (FileLocator imageDirectory / 'pharo-copilot' / 'templates') asFileReference
	]
]

{ #category : 'accessing' }
CopilotSettings class >> templatesDirectory: aFileReference [
	"Set the directory containing bundled templates."

	templatesDirectory := aFileReference asFileReference.
	self autoSaveSettings
]

{ #category : 'ollama' }
CopilotSettings class >> topK [

	^ topK ifNil: [ topK := 40 ]
]

{ #category : 'ollama' }
CopilotSettings class >> topK: anInteger [
	topK := anInteger.
	self autoSaveSettings
]

{ #category : 'ollama' }
CopilotSettings class >> topP [

	^ topP ifNil: [ topP := 0.9 ]
]

{ #category : 'ollama' }
CopilotSettings class >> topP: aNumber [
	topP := aNumber.
	self autoSaveSettings
]

{ #category : 'persistence' }
CopilotSettings class >> upgradeLegacyCompletionDefaults [
	"Move persisted settings from old slow default values to the current fast defaults.
	Non-matching user tuning is left untouched."

	completionDebounceMilliseconds = 100 ifTrue: [
		completionDebounceMilliseconds := 0 ].
	completionIdleMilliseconds = 300 ifTrue: [
		completionIdleMilliseconds := 75 ].
	numPredict = 64 ifTrue: [
		numPredict := 32 ].
	maxInstanceMethods = 10 ifTrue: [
		maxInstanceMethods := 6 ].
	maxClassMethods = 5 ifTrue: [
		maxClassMethods := 3 ].
	completionTopLogprobs = 5 ifTrue: [
		completionTopLogprobs := 1 ]
]

{ #category : 'settings' }
CopilotSettings class >> useDefaultCompletionModelWhenSavedModelIsMissingOrNull [

	(modelName isNil or: [
		modelName asString trimBoth isEmpty or: [
			self isNullModelName: modelName ] ])
		ifTrue: [
			modelName := self defaultCompletionModelName.
			modelMetadata := nil ]
]

{ #category : 'persistence' }
CopilotSettings class >> valueAt: aKey from: aDictionary default: aDefaultValue [

	| value |
	value := aDictionary at: aKey ifAbsent: [ aDefaultValue ].
	^ value = nil
		ifTrue: [ aDefaultValue ]
		ifFalse: [ value ]
]

{ #category : 'accessing' }
CopilotSettings class >> valueForMetadataKey: aKey in: metadata [
	"Read a key from metadata allowing both symbol and string keys."

	^ metadata
		at: aKey
		ifAbsent: [ metadata at: aKey asString ifAbsent: [ nil ] ]
]

{ #category : 'accessing' }
CopilotSettings class >> withDefaultSettingsDo: aBlock [
	"Temporarily reset settings to defaults while evaluating the block, then restore the prior settings."

	| snapshot |
	snapshot := self settingsSnapshot.
	[
		self resetToDefaultSettings.
		aBlock value
	] ensure: [ self restoreSettingsFromSnapshot: snapshot ]
]

{ #category : 'accessing' }
CopilotSettings class >> writeMetadata: metadata toDirectory: modelDirectory modelName: modelNameString [
	"Write each metadata association to its own .txt file (best-effort)."

	metadata associationsDo: [ :assoc |
		| fileName fileRef contents keyLabel |
		fileName := (self sanitizedFileComponentFor: assoc key default: 'metadata') , '.txt'.
		fileRef := modelDirectory / fileName.
		contents := self metadataFileContentsFor: assoc value.
		keyLabel := (assoc key ifNil: [ 'metadata' ]) asString.

		[
			fileRef ensureCreateFile.
			fileRef writeStreamDo: [ :stream |
				stream truncate.
				stream nextPutAll: contents
			]
		] on: Error do: [ :ex |
			CoPharoCopilotLogger
				logBackEndEvent: 'Failed to write model metadata file'
				details: (Dictionary new
					at: #model put: modelNameString;
					at: #key put: keyLabel;
					at: #file put: fileRef fullName;
					at: #errorClass put: ex class name;
					at: #error put: ex description;
					yourself)
		]
	]
]
