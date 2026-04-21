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
		'customParameters',
		'maxInstanceMethods',
		'maxClassMethods',
		'minimumPrefixLength',
		'completionSuggestionsCount',
		'backgroundColor',
		'installModelUserConsent'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'ollama' }
CopilotSettings class >> allOllamaOptions [
	"Answer a dictionary of all Ollama options (standard + custom) ready to send to the API."

	| options |
	options := Dictionary new.

	"Add standard parameters if they have non-nil values"
	temperature ifNotNil: [ options at: #temperature put: temperature ].
	topP ifNotNil: [ options at: #top_p put: topP ].
	topK ifNotNil: [ options at: #top_k put: topK ].
	numPredict ifNotNil: [ options at: #num_predict put: numPredict ].
	repeatPenalty ifNotNil: [ options at: #repeat_penalty put: repeatPenalty ].
	numCtx ifNotNil: [ options at: #num_ctx put: numCtx ].
	seed ifNotNil: [ options at: #seed put: seed ].

	"Add custom parameters"
	customParameters ifNotNil: [
		customParameters keysAndValuesDo: [ :key :value |
			options at: key put: value
		]
	].

	^ options

]

{ #category : 'accessing' }
CopilotSettings class >> attemptAutoInstallForModelNamed: aModelName usingInitialResponse: response [
	"Try to auto-install the given model when enabled; answer whether the install succeeded."

	(self shouldAutoInstallModelNamed: aModelName) ifFalse: [ ^ false ].
	^ self performInstallOfModelNamed: aModelName usingInitialResponse: response
]

{ #category : 'accessing' }
CopilotSettings class >> autoInstallModelScriptEnabled [
	"Answer whether auto-install is enabled; default to true."

	^ autoInstallModelScriptEnabled ifNil: [ autoInstallModelScriptEnabled := true ]
]

{ #category : 'accessing' }
CopilotSettings class >> autoInstallModelScriptEnabled: aBoolean [
	"Enable/disable auto-install of missing models."

	autoInstallModelScriptEnabled := aBoolean.
	self autoSaveSettings
]

{ #category : 'persistence' }
CopilotSettings class >> autoSaveSettings [
	"Automatically save settings to file when they change. Runs in background to avoid blocking UI."

	[
		self saveSettingsToFile
	] forkAt: Processor userBackgroundPriority named: 'CopilotSettings auto-save'
]

{ #category : 'settings' }
CopilotSettings class >> availableModelNames [
	"Answer the list of available model names for the settings UI."

	^ OModelRegistry refresh domainValuesForSettings
]

{ #category : 'settings' }
CopilotSettings class >> availableProviders [
	"Answer the supported provider symbols."

	^ { #ollama }
]

{ #category : 'settings' }
CopilotSettings class >> backgroundColor [
	"Answer the background color for the Copilot completion menu."

	| uiThemeClass theme |
	uiThemeClass := Smalltalk globals at: #UITheme ifAbsent: [ nil ].
	uiThemeClass ifNotNil: [
		(uiThemeClass respondsTo: #current) ifTrue: [
			theme := uiThemeClass current.
			(theme respondsTo: #windowColor) ifTrue: [ ^ theme windowColor ] ] ].
	^ Color darkGray
]

{ #category : 'accessing' }
CopilotSettings class >> backgroundColor: aColor [
	"Set the background color for the Copilot completion menu."

	backgroundColor := aColor.
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> clearCachedModelMetadata [
	"Drop the in-memory cached model metadata so it will be recomputed."

	modelMetadata := nil
]

{ #category : 'settings' }
CopilotSettings class >> completionDebounceMilliseconds [

	^ completionDebounceMilliseconds ifNil: [ completionDebounceMilliseconds := 50 ]
]

{ #category : 'settings' }
CopilotSettings class >> completionDebounceMilliseconds: anObject [
	"Set the debounce delay (milliseconds) before firing completion requests."

	completionDebounceMilliseconds := self
		                                  normalizedDuration: anObject
		                                  default: 50
		                                  minimum: 1
		                                  maximum: 60000.
	self autoSaveSettings
]

{ #category : 'settings' }
CopilotSettings class >> completionIdleMilliseconds [

	^ completionIdleMilliseconds ifNil: [ completionIdleMilliseconds := 300 ]
]

{ #category : 'settings' }
CopilotSettings class >> completionIdleMilliseconds: anObject [
	"Set the idle delay (milliseconds) before firing completion requests."

	completionIdleMilliseconds := self
		                              normalizedDuration: anObject
		                              default: 300
		                              minimum: 1
		                              maximum: 60000.
	self autoSaveSettings
]

{ #category : 'settings' }
CopilotSettings class >> completionSuggestionsCount [
	"Answer how many completion alternatives should be requested per completion trigger."

	^ completionSuggestionsCount ifNil: [ completionSuggestionsCount := 3 ]
]

{ #category : 'settings' }
CopilotSettings class >> completionSuggestionsCount: anObject [
	"Set how many completion alternatives should be requested per completion trigger."

	completionSuggestionsCount := self
		                              normalizedDuration: anObject
		                              default: 3
		                              minimum: 1
		                              maximum: 10.
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
	"Answer the configured provider; default to #ollama."

	^ provider ifNil: [ provider := #ollama ].
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> copilotProvider: aSymbol [
	"Set the provider symbol."

	provider := aSymbol
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

{ #category : 'accessing' }
CopilotSettings class >> ensureModelMetadataDirectoryFor: modelNameString [
	"Ensure the per-model metadata directory exists; answer the directory or nil on failure."

	| logsDirectory modelDirectory |
	logsDirectory := CoCopilotLogger ensureLogsDirectory.
	modelDirectory := logsDirectory / (self sanitizedFileComponentFor: modelNameString default: 'unknown-model').

	[
		modelDirectory ensureCreateDirectory
	] on: Error do: [ :ex |
		CoCopilotLogger
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

{ #category : 'settings' }
CopilotSettings class >> ensureOllamaServiceAvailable [
	"Verify the Ollama service responds; answer the listModels response or nil if unavailable."

	| response |
	[
		response := self newOllamaClient listModels
	] on: Error do: [ :ex |
		self logOllamaServiceUnavailable: ex.
		self notifyUser: 'Ollama is not configured. Please configure it.'.
		^ nil
	].

	response ifNil: [
		self logOllamaMissingResponse.
		self notifyUser: 'Ollama is not configured. Please configure it.'.
		^ nil
	].

	^ response
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

	(availableModels includes: selectedModelName) ifTrue: [ ^ true ].
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

	"Handle cases where the Ollama service is missing; attempt install or fall back to the null model."

	(self promptToInstallMissingModelNamed: selectedModelName availableModels: #())
		ifTrue: [
			(self installModelNamed: selectedModelName) ifTrue: [ ^ true ] ].

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
CopilotSettings class >> installModelNamed: aModelName [
	"Invoke Ollama to pull/install the given model; answer whether it succeeded."

	| client |
	[
		client := self newOllamaClient.

		self notifyUser: ('Downloading {1}... This may take a few minutes.' format: { aModelName }).
		CoCopilotLogger logBackEndEvent: 'Invoking Ollama model install script' details: (Dictionary new
				 at: #model put: aModelName;
				 yourself).

			(client respondsTo: #pullModelNamed:timeoutSeconds:)
			ifTrue: [ client pullModelNamed: aModelName timeoutSeconds: self modelInstallTimeoutSeconds ]
			ifFalse: [ client pullModelNamed: aModelName ].

		CoCopilotLogger logBackEndEvent: 'Ollama model install script completed' details: (Dictionary new
				 at: #model put: aModelName;
				 yourself).
		self notifyUser: ('Download completed for {1}.' format: { aModelName }).
		^ true ]
		on: Error
		do: [ :ex |
				CoCopilotLogger
					logError: 'Failed to invoke Ollama model install script'
					origin: #CopilotSettings
					exception: ex
					payload: (Dictionary new
							 at: #model put: aModelName;
							 yourself).
				self notifyUser: ('Failed to download {1}. Please check Ollama logs.' format: { aModelName }).
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

{ #category : 'accessing' }
CopilotSettings class >> installSelectedModelNow [
	"Install the currently selected model via Ollama pull."

	| selectedModelName response |
	selectedModelName := self modelName.
	(selectedModelName isNil or: [ selectedModelName isEmpty ]) ifTrue: [
		self notifyUser: 'Please select an Ollama model before installing.'.
		^ false
	].

	response := self ensureOllamaServiceAvailable.
	response ifNil: [ ^ self handleMissingOllamaForModelNamed: selectedModelName ].

	(self installModelNamed: selectedModelName) ifFalse: [ ^ false ].

	(self refreshModelsAfterInstallOf: selectedModelName usingInitialResponse: response)
		ifTrue: [ ^ true ].

	self notifyUser:
		'Model download is still in progress. Please wait and refresh the model list.'.
	^ false
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

{ #category : 'persistence' }
CopilotSettings class >> loadSettingsFromFile [
	"Load settings from the persistent STON file if it exists."

	| fileRef stonString snapshot |

		fileRef := self settingsFileReference.
		(fileRef exists and: [ fileRef isFile ]) ifFalse: [ ^ self ].

		fileRef readStreamDo: [ :stream |
			stonString := stream contents
		].

		snapshot := STON fromString: stonString.
		self restoreSettingsFromSerializableSnapshot: snapshot.


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
	"Log when an install completed but the model is still not visible."
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

	CoCopilotLogger
		logBackEndEvent: 'Using bundled FIM template'
		details: (Dictionary new
			at: #model put: (self modelName ifNil: [ 'unknown-model' ]);
			at: #source put: fileRef pathString;
			yourself)
]

{ #category : 'private' }
CopilotSettings class >> logUsingCachedFimTemplateFrom: cacheFile [
	"Log that we loaded a cached template from logs."

	CoCopilotLogger
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
	"Answer whether logging is enabled; default to true."

	^ loggingEnabled ifNil: [ loggingEnabled := true ].
]

{ #category : 'accessing' }
CopilotSettings class >> loggingEnabled: aBoolean [
	"Enable/disable logging."

	loggingEnabled := aBoolean.
	self autoSaveSettings
]

{ #category : 'context' }
CopilotSettings class >> maxClassMethods [

	^ maxClassMethods ifNil: [ maxClassMethods := 5 ]
]

{ #category : 'context' }
CopilotSettings class >> maxClassMethods: anObject [

	maxClassMethods := self
		                   normalizedDuration: anObject
		                   default: 5
		                   minimum: 1
		                   maximum: 100.
	self autoSaveSettings
]

{ #category : 'context' }
CopilotSettings class >> maxInstanceMethods [

	^ maxInstanceMethods ifNil: [ maxInstanceMethods := 10 ]
]

{ #category : 'context' }
CopilotSettings class >> maxInstanceMethods: anObject [
	"Set the maximum number of instance-side methods for context (1 to 200, default: 30)."

	maxInstanceMethods := self
		                      normalizedDuration: anObject
		                      default: 10
		                      minimum: 1
		                      maximum: 200.
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> metadataFileContentsFor: value [
	"Format a metadata value as text suitable for writing to a .txt file."

	| formatted |
	formatted := CoCopilotLogger formatValue: value.
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
	"Answer the minimum prefix length required before requesting a completion. Default: 2"

	^ minimumPrefixLength ifNil: [ minimumPrefixLength := 2 ]
]

{ #category : 'context' }
CopilotSettings class >> minimumPrefixLength: anObject [
	"Set the minimum prefix length (1 to 20, default: 2)."

	minimumPrefixLength := self normalizedDuration: anObject default: 2 minimum: 1 maximum: 20.
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> modelInstallTimeoutSeconds [
	"Answer the timeout (seconds) for Ollama model pulls."

	^ modelInstallTimeoutSeconds ifNil: [ modelInstallTimeoutSeconds := 600 ]
]

{ #category : 'accessing' }
CopilotSettings class >> modelInstallTimeoutSeconds: anObject [
	"Set the timeout (seconds) for Ollama model pulls."

	modelInstallTimeoutSeconds := self
		                              normalizedDuration: anObject
		                              default: 600
		                              minimum: 30
		                              maximum: 3600.
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

	^ modelName ifNil: [ modelName := OllamaClient defaultModelFullName ]
]

{ #category : 'accessing' }
CopilotSettings class >> modelName: aString [
	"Set the model name and clear cached metadata."

	modelName := aString.
	self clearCachedModelMetadata.
	self autoSaveSettings
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
CopilotSettings class >> normalizedDuration: anObject default: defaultValue minimum: minValue maximum: maxValue [
	"Normalize a duration, enforcing a non-zero range."

	| candidate |
	anObject ifNil: [ ^ defaultValue ].
	candidate := [ anObject asInteger ] on: Error do: [ defaultValue ].
	candidate <= 0 ifTrue: [ ^ defaultValue max: minValue ].
	candidate := candidate max: minValue.
	^ candidate min: maxValue
]

{ #category : 'ollama' }
CopilotSettings class >> normalizedFloat: anObject default: defaultValue minimum: minValue maximum: maxValue [
	"Normalize a float value, enforcing a range."

	| candidate |
	anObject ifNil: [ ^ defaultValue ].
	candidate := [ anObject asFloat ] on: Error do: [ defaultValue ].
	candidate := candidate max: minValue.
	^ candidate min: maxValue
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

	^ OllamaClient nullModelFullName
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
	"Answer the num_ctx parameter for Ollama (context window size). Default: nil (use model default)"

	^ numCtx ifNil: [ 2048 ]
]

{ #category : 'ollama' }
CopilotSettings class >> numCtx: anIntegerOrNil [
	"Set the num_ctx parameter (512 to 32768, or nil for model default)."

	anIntegerOrNil ifNil: [ numCtx := nil. self autoSaveSettings. ^ nil ].
	numCtx := self normalizedDuration: anIntegerOrNil default: 2048 minimum: 512 maximum: 32768.
	self autoSaveSettings
]

{ #category : 'ollama' }
CopilotSettings class >> numPredict [
	"Answer the num_predict parameter for Ollama (max tokens to generate). Default: 128"

	^ numPredict ifNil: [ numPredict := 128 ]
]

{ #category : 'ollama' }
CopilotSettings class >> numPredict: anInteger [
	"Set the num_predict parameter (1 to 2048, default: 128)."

	numPredict := self normalizedDuration: anInteger default: 128 minimum: 1 maximum: 2048.
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> ollamaClientFactory [
	"Answer the factory closure used to create Ollama clients; default constructs a new client."

	ollamaClientFactory ifNil: [ ollamaClientFactory := [ OllamaClient new ] ].
	^ ollamaClientFactory
]

{ #category : 'accessing' }
CopilotSettings class >> ollamaClientFactory: aBlockClosure [
	"Set the client factory and clear cached metadata."

	ollamaClientFactory := aBlockClosure.
	self clearCachedModelMetadata
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
	"Set the Ollama port (accepts string or number) and clear cached metadata."

	port := aNumberOrString isString
		ifTrue: [
			[ aNumberOrString asNumber ]
				on: Error
				do: [ self port ]
		]
		ifFalse: [ aNumberOrString ].

	self clearCachedModelMetadata.
	self autoSaveSettings
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
CopilotSettings class >> recordInstallModelUserConsentForModelNamed: aModelName accepted: aBoolean [
	"Persist the most recent user consent decision and append it to the evaluation log."

	| consentRecord evalFile |
	consentRecord := Dictionary new
		at: #model put: aModelName;
		at: #accepted put: aBoolean;
		at: #timestamp put: DateAndTime now asString;
		yourself.

	installModelUserConsent := consentRecord.
	self autoSaveSettings.

	[
		CoCopilotLogger ensureEvaluationLogFileInitialized.
		evalFile := CoCopilotLogger evaluationLogFileReference.
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

{ #category : 'accessing' }
CopilotSettings class >> recordPrivacyPolicyUserConsentAccepted: aBoolean [

	| consentRecord evalFile |
	consentRecord := Dictionary new
		at: #accepted put: aBoolean;
		at: #timestamp put: DateAndTime now asString;
		yourself.

	[
		CoCopilotLogger ensureEvaluationLogFileInitialized.
		evalFile := CoCopilotLogger evaluationLogFileReference.
		evalFile writeStreamDo: [ :stream |
			stream setToEnd.
			stream
				nextPutAll: (STONJSON toString: (Dictionary new
					at: #event put: 'privacy-policy-consent';
					at: #data put: consentRecord;
					yourself));
				nextPut: Character lf ]
	] on: Error do: [ :ignored | ].
]

{ #category : 'settings' }
CopilotSettings class >> refreshModelsAfterInstallOf: aModelName usingInitialResponse: initialResponse [
	"Re-list models after an install and verify the target model is present; answer true if found."

	[
		| refreshedResponse refreshedModels |
		refreshedResponse := self newOllamaClient listModels.
		refreshedModels := self modelNamesFromResponse: refreshedResponse.

		(refreshedModels includes: aModelName)
			ifTrue: [
				self logDetectedInstalledModel: aModelName before: initialResponse after: refreshedModels.
				[ OModelRegistry refresh ] on: Error do: [ :ignored | ].
				^ true
			].

		self logInstallDidNotExposeModel: aModelName before: initialResponse after: refreshedModels
	] on: Error do: [ :ex |
		CoCopilotLogger
			logError: 'Failed to refresh Ollama models after install'
			origin: #CopilotSettings
			exception: ex
			payload: (Dictionary new
				at: #model put: aModelName;
				yourself)
	].

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
	"Answer the repeat_penalty parameter for Ollama (penalizes repetition). Default: 1.1"

	^ repeatPenalty ifNil: [ repeatPenalty := 1.1 ]
]

{ #category : 'ollama' }
CopilotSettings class >> repeatPenalty: aNumber [
	"Set the repeat_penalty parameter (0.0 to 2.0, default: 1.1)."

	repeatPenalty := self normalizedFloat: aNumber default: 1.1 minimum: 0.0 maximum: 2.0.
	self autoSaveSettings
]

{ #category : 'settings' }
CopilotSettings class >> requestTimeoutSeconds [
	"Answer the HTTP request timeout (seconds) for Ollama calls."

	^ requestTimeoutSeconds ifNil: [ requestTimeoutSeconds := 500 ]
]

{ #category : 'settings' }
CopilotSettings class >> requestTimeoutSeconds: anObject [
	"Set the HTTP request timeout (seconds) for Ollama calls."

	requestTimeoutSeconds := anObject.
	self autoSaveSettings
]

{ #category : 'accessing' }
CopilotSettings class >> resetToDefaultSettings [
	"Reset all settings to defaults (by clearing class-side state)."

	<script>
	enabled := nil.
	provider := nil.
	modelName := nil.
	host := nil.
	port := nil.
	modelMetadata := nil.
	ollamaClientFactory := nil.
	autoInstallModelScriptEnabled := nil.
	loggingEnabled := nil.
	templatesDirectory := nil.
	completionDebounceMilliseconds := nil.
	completionIdleMilliseconds := nil.
	requestTimeoutSeconds := nil.
	modelInstallTimeoutSeconds := nil.
	temperature := nil.
	topP := nil.
	topK := nil.
	numPredict := nil.
	repeatPenalty := nil.
	numCtx := nil.
	seed := nil.
	customParameters := nil.
	maxInstanceMethods := nil.
	maxClassMethods := nil.
	minimumPrefixLength := nil.
	completionSuggestionsCount := nil.
	backgroundColor := nil.
	installModelUserConsent := nil
]

{ #category : 'persistence' }
CopilotSettings class >> restoreSettingsFromSerializableSnapshot: aDictionary [
	"Restore settings from a serializable snapshot (handles path strings, etc.)."

	| templatesPath |
	enabled := aDictionary at: #enabled ifAbsent: [ nil ].
	provider := aDictionary at: #provider ifAbsent: [ nil ].
	modelName := aDictionary at: #modelName ifAbsent: [ nil ].
	host := aDictionary at: #host ifAbsent: [ nil ].
	port := aDictionary at: #port ifAbsent: [ nil ].
	autoInstallModelScriptEnabled := aDictionary at: #autoInstallModelScriptEnabled ifAbsent: [ nil ].
	loggingEnabled := aDictionary at: #loggingEnabled ifAbsent: [ nil ].
	completionDebounceMilliseconds := aDictionary at: #completionDebounceMilliseconds ifAbsent: [ nil ].
	completionIdleMilliseconds := aDictionary at: #completionIdleMilliseconds ifAbsent: [ nil ].
	requestTimeoutSeconds := aDictionary at: #requestTimeoutSeconds ifAbsent: [ nil ].
	modelInstallTimeoutSeconds := aDictionary at: #modelInstallTimeoutSeconds ifAbsent: [ nil ].
	temperature := aDictionary at: #temperature ifAbsent: [ nil ].
	topP := aDictionary at: #topP ifAbsent: [ nil ].
	topK := aDictionary at: #topK ifAbsent: [ nil ].
	numPredict := aDictionary at: #numPredict ifAbsent: [ nil ].
	repeatPenalty := aDictionary at: #repeatPenalty ifAbsent: [ nil ].
	numCtx := aDictionary at: #numCtx ifAbsent: [ nil ].
	seed := aDictionary at: #seed ifAbsent: [ nil ].
	customParameters := aDictionary at: #customParameters ifAbsent: [ Dictionary new ].
	maxInstanceMethods := aDictionary at: #maxInstanceMethods ifAbsent: [ nil ].
	maxClassMethods := aDictionary at: #maxClassMethods ifAbsent: [ nil ].
	minimumPrefixLength := aDictionary at: #minimumPrefixLength ifAbsent: [ nil ].
		completionSuggestionsCount := aDictionary at: #completionSuggestionsCount ifAbsent: [ nil ].
		backgroundColor := aDictionary at: #backgroundColor ifAbsent: [ nil ].
		installModelUserConsent := aDictionary at: #installModelUserConsent ifAbsent: [ nil ].
	(aDictionary at: #contextMode ifAbsent: [ nil ]) ifNotNil: [ :savedMode | CopilotContextSettings mode: savedMode ]. "Convert templatesDirectory path string back to FileReference"
	templatesPath := aDictionary at: #templatesDirectory ifAbsent: [ nil ].
	templatesPath ifNotNil: [
			templatesDirectory := [ templatesPath asFileReference ]
				                      on: Error
				                      do: [ nil ] ].
	modelMetadata := nil.
	ollamaClientFactory := nil
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
	customParameters := aDictionary at: #customParameters ifAbsent: [ Dictionary new ].
	maxInstanceMethods := aDictionary at: #maxInstanceMethods ifAbsent: [ aDictionary at: #MaxInstanceMethods ifAbsent: [ nil ] ].
	maxClassMethods := aDictionary at: #maxClassMethods ifAbsent: [ aDictionary at: #MaxClassMethods ifAbsent: [ nil ] ].
	minimumPrefixLength := aDictionary at: #minimumPrefixLength ifAbsent: [ aDictionary at: #MinimumPrefixLength ifAbsent: [ nil ] ].
completionSuggestionsCount := aDictionary at: #completionSuggestionsCount ifAbsent: [ aDictionary at: #CompletionSuggestionsCount ifAbsent: [ nil ] ].
backgroundColor := aDictionary at: #backgroundColor ifAbsent: [ aDictionary at: #BackgroundColor ifAbsent: [ nil ] ].
installModelUserConsent := aDictionary at: #installModelUserConsent ifAbsent: [ aDictionary at: #InstallModelUserConsent ifAbsent: [ nil ] ].
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
	"Set the seed parameter for reproducible generation (any integer, or nil for random)."

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
		            at: #customParameters put: (customParameters ifNil: [ Dictionary new ]);
		            at: #maxInstanceMethods put: maxInstanceMethods;
		            at: #maxClassMethods put: maxClassMethods;
		            at: #minimumPrefixLength put: minimumPrefixLength;
		            at: #contextMode put: CopilotContextSettings mode;
		            at: #completionSuggestionsCount put: completionSuggestionsCount;
		            at: #backgroundColor put: backgroundColor;
		at: #installModelUserConsent put: installModelUserConsent;
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
	logsDirectory := CoCopilotLogger ensureLogsDirectory.
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

				(aBuilder setting: #loggingEnabled)
					order: 0.3;
					label: 'Enable logging';
					target: self;
					getSelector: #loggingEnabled;
					setSelector: #loggingEnabled:;
					default: self loggingEnabled;
					description: 'When disabled, Copilot will not record activity or evaluation logs.'.

				(aBuilder setting: #autoInstallModelScriptEnabled)
					order: 0.4;
					label: 'Auto-install Pharo coder model';
					target: self;
					getSelector: #autoInstallModelScriptEnabled;
					setSelector: #autoInstallModelScriptEnabled:;
					default: self autoInstallModelScriptEnabled;
					description:
						'When enabled, Pharo Copilot automatically runs the installation script if the "pharo-coder-1.5b-fim-f16.gguf:latest" model is missing.'.

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
					description: 'Milliseconds to wait after a boundary before requesting completions (1-60000).'.

				(aBuilder setting: #completionIdleMilliseconds)
					order: 0.6;
					label: 'Completion idle (ms)';
					target: self;
					getSelector: #completionIdleMilliseconds;
					setSelector: #completionIdleMilliseconds:;
					default: self completionIdleMilliseconds;
					description: 'Milliseconds to wait after typing stops before requesting completions (1-60000).'.

				(aBuilder pickOne: #contextMode)
					order: 0.65;
					label: 'Context mode';
					target: CopilotContextSettings;
					getSelector: #mode;
					setSelector: #mode:;
					default: CopilotContextSettings mode;
					domainValues: CopilotContextSettings availableModes;
					description: 'Controls whether completions use full source or selectors-only class context.'.


				(aBuilder setting: #maxInstanceMethods)
					order: 0.66;
					label: 'Max instance methods in context';
					target: self;
					getSelector: #maxInstanceMethods;
					setSelector: #maxInstanceMethods:;
					default: self maxInstanceMethods;
					description:
						'Maximum number of instance-side methods to include in the class context sent with completions (1-200). Default: 30'.

				(aBuilder setting: #maxClassMethods)
					order: 0.67;
					label: 'Max class methods in context';
					target: self;
					getSelector: #maxClassMethods;
					setSelector: #maxClassMethods:;
					default: self maxClassMethods;
					description:
						'Maximum number of class-side methods to include in the class context sent with completions (1-100). Default: 15'.

				(aBuilder setting: #minimumPrefixLength)
					order: 0.68;
					label: 'Minimum prefix length';
					target: self;
					getSelector: #minimumPrefixLength;
					setSelector: #minimumPrefixLength:;
					default: self minimumPrefixLength;
					description: 'Minimum number of characters typed before requesting a completion (1-20). Default: 2'.

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
					description: 'How many completion alternatives to request per trigger (1-10). Default: 3'.
					
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
								description: 'Controls randomness in generation (0.0 = deterministic, 2.0 = very random). Default: 0.8'.

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
								description: 'Maximum number of tokens to generate (1 to 2048). Default: 128'.

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
		  at: #customParameters put: customParameters;
		  at: #maxInstanceMethods put: maxInstanceMethods;
		  at: #maxClassMethods put: maxClassMethods;
		  at: #minimumPrefixLength put: minimumPrefixLength;
		  at: #completionSuggestionsCount put: completionSuggestionsCount;
		  at: #backgroundColor put: backgroundColor;
		at: #installModelUserConsent put: installModelUserConsent;
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
CopilotSettings class >> switchToNullModelDueToMissingOllamaFor: selectedModelName [

	self modelName: self nullModelFullName.
	self notifyUser: 'Ollama is not available. Pharo Copilot will use the null model until you configure an Ollama model.'
]

{ #category : 'ollama' }
CopilotSettings class >> temperature [ 
	"Answer the temperature parameter for Ollama (controls randomness). Default: 0.8"

	^ temperature ifNil: [ temperature := 0.8 ]
]

{ #category : 'ollama' }
CopilotSettings class >> temperature: aNumber [
	"Set the temperature parameter (0.0 to 2.0, default: 0.8)."

	temperature := self normalizedFloat: aNumber default: 0.8 minimum: 0.0 maximum: 2.0.
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

	baseDirectory := CoCopilotLogger logsDirectoryReference.
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
	"Answer the top_k parameter for Ollama (limits token selection). Default: 40"

	^ topK ifNil: [ topK := 40 ]
]

{ #category : 'ollama' }
CopilotSettings class >> topK: anInteger [
	"Set the top_k parameter (1 to 100, default: 40)."

	topK := self normalizedDuration: anInteger default: 40 minimum: 1 maximum: 100.
	self autoSaveSettings
]

{ #category : 'ollama' }
CopilotSettings class >> topP [
	"Answer the top_p parameter for Ollama (nucleus sampling). Default: 0.9"

	^ topP ifNil: [ topP := 0.9 ]
]

{ #category : 'ollama' }
CopilotSettings class >> topP: aNumber [
	"Set the top_p parameter (0.0 to 1.0, default: 0.9)."

	topP := self normalizedFloat: aNumber default: 0.9 minimum: 0.0 maximum: 1.0.
	self autoSaveSettings
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
		] 
	]
]
