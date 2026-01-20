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
		'modelInstallTimeoutSeconds'
	],
	#category : 'AI-Pharo-Copilot-Ollama',
	#package : 'AI-Pharo-Copilot-Ollama'
}

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

	autoInstallModelScriptEnabled := aBoolean
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

{ #category : 'accessing' }
CopilotSettings class >> clearCachedModelMetadata [
	"Drop the in-memory cached model metadata so it will be recomputed."

	modelMetadata := nil
]

{ #category : 'settings' }
CopilotSettings class >> completionDebounceMilliseconds [
	"Answer the debounce delay (milliseconds) before firing completion requests."

	^ completionDebounceMilliseconds ifNil: [ completionDebounceMilliseconds := 250 ]
]

{ #category : 'settings' }
CopilotSettings class >> completionDebounceMilliseconds: anObject [
	"Set the debounce delay (milliseconds) before firing completion requests."

	completionDebounceMilliseconds := self normalizedDuration: anObject default: 250 minimum: 1 maximum: 60000
]

{ #category : 'settings' }
CopilotSettings class >> completionIdleMilliseconds [
	"Answer the idle delay (milliseconds) before firing completion requests."

	^ completionIdleMilliseconds ifNil: [ completionIdleMilliseconds := 2000 ]
]

{ #category : 'settings' }
CopilotSettings class >> completionIdleMilliseconds: anObject [
	"Set the idle delay (milliseconds) before firing completion requests."

	completionIdleMilliseconds := self normalizedDuration: anObject default: 2000 minimum: 1 maximum: 60000
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

	enabled := aBoolean
]

{ #category : 'accessing' }
CopilotSettings class >> copilotProvider [
	"Answer the configured provider; default to #ollama."

	^ provider ifNil: [ provider := #ollama ]
]

{ #category : 'accessing' }
CopilotSettings class >> copilotProvider: aSymbol [
	"Set the provider symbol."

	provider := aSymbol
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
	"Answer the validated FIM template from metadata or fall back to the default template."

	| metadata template |
	metadata := self modelMetadata.
	metadata ifNil: [ ^ self defaultFimTemplate ].

	template := metadata at: #template ifAbsent: [ metadata at: 'template' ifAbsent: [ nil ] ].
	template ifNil: [ ^ self defaultFimTemplate ].
	(template respondsTo: #asString) ifFalse: [ ^ self defaultFimTemplate ].

	template := template asString.
	(template isEmpty
		or: [ ((template includesSubstring: '%1') not) or: [ (template includesSubstring: '%2') not ] ])
		ifTrue: [ ^ self defaultFimTemplate ].

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
	self clearCachedModelMetadata
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

{ #category : 'private' }
CopilotSettings class >> logDetectedInstalledModel: aModelName before: initialResponse after: refreshedModels [
	"Log that a model became available after installation."

	CoCopilotLogger
		logBackEndEvent: 'Detected newly available Ollama model after install'
		details: (Dictionary new
			at: #model put: aModelName;
			at: #availableModelsBefore put: (self modelNamesFromResponse: initialResponse);
			at: #availableModelsAfter put: refreshedModels;
			yourself)
]

{ #category : 'private' }
CopilotSettings class >> logFailedToFetchModelMetadataFor: aModelName error: ex [
	"Log metadata fetch failures in a compact form."

	CoCopilotLogger
		logBackEndEvent: 'Failed to fetch Ollama model metadata'
		details: (Dictionary new
			at: #model put: aModelName;
			at: #errorClass put: ex class name;
			at: #error put: ex description;
			yourself)
]

{ #category : 'private' }
CopilotSettings class >> logFailedToReadFimTemplateFile: file error: ex [
	"Log errors while reading a template file."

	CoCopilotLogger
		logError: 'Failed to read FIM template file'
		origin: #CopilotSettings
		exception: ex
		payload: (Dictionary new
			at: #file put: file pathString;
			yourself)
]

{ #category : 'private' }
CopilotSettings class >> logFetchedModelMetadata: metadata fallbackModelName: aModelName [
	"Log a successful metadata fetch."

	CoCopilotLogger
		logBackEndEvent: 'Fetched Ollama model metadata'
		details: (Dictionary new
			at: #model put: (metadata at: #model ifAbsent: [ aModelName ]);
			at: #keys put: metadata keys asArray;
			yourself)
]

{ #category : 'private' }
CopilotSettings class >> logGeneratedNullModelMetadata: metadata modelName: aModelName [
	"Log that we generated placeholder/null metadata."

	CoCopilotLogger
		logBackEndEvent: 'Generated null model metadata'
		details: (Dictionary new
			at: #model put: aModelName;
			at: #keys put: metadata keys asArray;
			yourself)
]

{ #category : 'private' }
CopilotSettings class >> logInstallDidNotExposeModel: aModelName before: initialResponse after: refreshedModels [
	"Log when an install completed but the model is still not visible."

	CoCopilotLogger
		logBackEndEvent: 'Model install did not expose expected Ollama model'
		details: (Dictionary new
			at: #model put: aModelName;
			at: #availableModelsBefore put: (self modelNamesFromResponse: initialResponse);
			at: #availableModelsAfter put: refreshedModels;
			yourself)
]

{ #category : 'accessing' }
CopilotSettings class >> logMissingFimTemplate [
	"Log that no FIM template could be found for the current model."

	CoCopilotLogger
		logBackEndEvent: 'Missing FIM template for model'
		details: (Dictionary new
			at: #model put: (self modelName ifNil: [ 'unknown-model' ]);
			at: #templatesDirectory put: self templatesDirectory pathString;
			yourself)
]

{ #category : 'private' }
CopilotSettings class >> logMissingModel: aModelName availableModels: availableModels [
	"Log that a configured model is not present in the Ollama installation."

	CoCopilotLogger
		logBackEndEvent: 'Missing Ollama model'
		details: (Dictionary new
			at: #model put: aModelName;
			at: #availableModels put: availableModels;
			yourself)
]

{ #category : 'private' }
CopilotSettings class >> logOllamaMissingResponse [
	"Log a nil/empty response from Ollama listModels."

	CoCopilotLogger
		logBackEndEvent: 'Missing response from Ollama service'
		details: (Dictionary new
			at: #host put: self host;
			at: #port put: self port;
			yourself)
]

{ #category : 'private' }
CopilotSettings class >> logOllamaServiceUnavailable: ex [
	"Log when the Ollama service cannot be reached."

	CoCopilotLogger
		logError: 'Ollama service unavailable'
		origin: #CopilotSettings
		exception: ex
		payload: (Dictionary new
			at: #host put: self host;
			at: #port put: self port;
			yourself)
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

	CoCopilotLogger
		logBackEndEvent: 'Validated Ollama model availability'
		details: (Dictionary new
			at: #model put: aModelName;
			at: #availableModelCount put: availableModels size;
			yourself)
]

{ #category : 'accessing' }
CopilotSettings class >> loggingEnabled [
	"Answer whether logging is enabled; default to true."

	^ loggingEnabled ifNil: [ loggingEnabled := true ]
]

{ #category : 'accessing' }
CopilotSettings class >> loggingEnabled: aBoolean [
	"Enable/disable logging."

	loggingEnabled := aBoolean
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

{ #category : 'accessing' }
CopilotSettings class >> modelInstallTimeoutSeconds [
	"Answer the timeout (seconds) for Ollama model pulls."

	^ modelInstallTimeoutSeconds ifNil: [ modelInstallTimeoutSeconds := 600 ]
]

{ #category : 'accessing' }
CopilotSettings class >> modelInstallTimeoutSeconds: anObject [
	"Set the timeout (seconds) for Ollama model pulls."

	modelInstallTimeoutSeconds := self normalizedDuration: anObject default: 600 minimum: 30 maximum: 3600
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
	self clearCachedModelMetadata
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

	self clearCachedModelMetadata
]

{ #category : 'settings' }
CopilotSettings class >> promptToInstallMissingModelNamed: aModelName availableModels: availableModels [
	"Ask the user whether to install a missing model; answer true if accepted."

	| message confirmation |
	message := 'This model is not available, Do you want to install it ? ' format: { aModelName }.

	CoCopilotLogger
		logBackEndEvent: 'Prompting user to install missing Ollama model'
		details: (Dictionary new
			at: #model put: aModelName;
			at: #availableModels put: availableModels;
			yourself).

	confirmation := self confirmViaUIManager: message.
	confirmation ifNil: [
		self notifyViaTranscript: message.
		^ false
	].

	CoCopilotLogger
		logBackEndEvent: 'User responded to Ollama model install prompt'
		details: (Dictionary new
			at: #model put: aModelName;
			at: #userAccepted put: confirmation;
			yourself).

	^ confirmation
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

{ #category : 'settings' }
CopilotSettings class >> requestTimeoutSeconds [
	"Answer the HTTP request timeout (seconds) for Ollama calls."

	^ requestTimeoutSeconds ifNil: [ requestTimeoutSeconds := 5 ]
]

{ #category : 'settings' }
CopilotSettings class >> requestTimeoutSeconds: anObject [
	"Set the HTTP request timeout (seconds) for Ollama calls."

	requestTimeoutSeconds := self normalizedDuration: anObject default: 5 minimum: 1 maximum: 120
]

{ #category : 'accessing' }
CopilotSettings class >> resetToDefaultSettings [
	"Reset all settings to defaults (by clearing class-side state)."

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
		modelInstallTimeoutSeconds := aDictionary at: #modelInstallTimeoutSeconds ifAbsent: [ aDictionary at: #ModelInstallTimeoutSeconds ifAbsent: [ nil ] ].
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


				(aBuilder setting: #requestTimeoutSeconds)
					order: 0.7;
					label: 'Request timeout (sec)';
					target: self;
					getSelector: #requestTimeoutSeconds;
					setSelector: #requestTimeoutSeconds:;
					default: self requestTimeoutSeconds;
					description: 'Seconds to wait for Ollama responses before timing out (1-120).'.

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
					default: self port ]
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
	"Fall back to the null model when Ollama is unavailable and the user declines installation."

	CoCopilotLogger
		logBackEndEvent: 'Falling back to null model due to missing Ollama'
		details: (Dictionary new
			at: #model put: selectedModelName;
			at: #nullModel put: self nullModelFullName;
			yourself).

	self modelName: self nullModelFullName.
	self notifyUser: 'Ollama is not available. Pharo Copilot will use the null model until you configure an Ollama model.'
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

	templatesDirectory := aFileReference asFileReference
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
			CoCopilotLogger
				logBackEndEvent: 'Failed to write Ollama metadata file'
				details: (Dictionary new
					at: #model put: modelNameString;
					at: #key put: keyLabel;
					at: #file put: fileRef basename;
					at: #errorClass put: ex class name;
					at: #error put: ex description;
					yourself)
		]
	]
]
