"
Holds global settings for Copilot and its Ollama backend.
"
Class {
	#name : 'CopilotSettings',
	#superclass : 'Object',
	#classInstVars : [
		'Enabled',
		'Provider',
		'ModelName',
		'Host',
		'Port',
		'ModelMetadata',
		'OllamaClientFactory',
		'AutoInstallModelScriptEnabled',
		'TemplatesDirectory'
	],
	#category : 'AI-Pharo-Copilot-Ollama',
	#package : 'AI-Pharo-Copilot-Ollama'
}

{ #category : 'accessing' }
CopilotSettings class >> attemptAutoInstallForModelNamed: modelName usingInitialResponse: response [

	(self shouldAutoInstallModelNamed: modelName) ifFalse: [ ^ false ].
    ^ self performInstallOfModelNamed: modelName usingInitialResponse: response
]

{ #category : 'accessing' }
CopilotSettings class >> autoInstallModelScriptEnabled [

    ^ AutoInstallModelScriptEnabled ifNil: [ AutoInstallModelScriptEnabled := true ]
]

{ #category : 'accessing' }
CopilotSettings class >> autoInstallModelScriptEnabled: aBoolean [

    AutoInstallModelScriptEnabled := aBoolean.
]

{ #category : 'settings' }
CopilotSettings class >> availableModelNames [

	^ OModelRegistry refresh domainValuesForSettings
]

{ #category : 'settings' }
CopilotSettings class >> availableProviders [

    "Adapt to your backends"
    ^ { #ollama}.
]

{ #category : 'accessing' }
CopilotSettings class >> clearCachedModelMetadata [
    ModelMetadata := nil.
]

{ #category : 'accessing' }
CopilotSettings class >> copilotEnabled [
    ^ Enabled ifNil: [ Enabled := true ].
]

{ #category : 'accessing' }
CopilotSettings class >> copilotEnabled: aBool [

    Enabled := aBool.
]

{ #category : 'accessing' }
CopilotSettings class >> copilotProvider [

    ^ Provider ifNil: [ Provider := #ollama ].
]

{ #category : 'accessing' }
CopilotSettings class >> copilotProvider: aSymbol [

    Provider := aSymbol.
]

{ #category : 'accessing' }
CopilotSettings class >> defaultFimTemplate [


    | template |
template := self fimTemplateFromBundledTemplates.
    template ifNotNil: [ ^ template ].
    ^ self error: 'No fill-in-the-middle template is available for the current Copilot model.'
]

{ #category : 'settings' }
CopilotSettings class >> ensureOllamaServiceAvailable [

	| response |
	<TODO: 'make it better'>
	[ response := self newOllamaClient listModels ]
		on: Error
		do: [ :ex |
				self notifyUser: 'Ollama is not configured. Please configure it.'.
				^ nil ].
	response ifNil: [
			self notifyUser: 'Ollama is not configured. Please configure it.'.
			^ nil ].
	^ response
]

{ #category : 'settings' }
CopilotSettings class >> ensureSelectedModelAvailable [

	| modelName response availableModels |
	modelName := self modelName.
	(self isNullModelName: modelName) ifTrue: [ ^ true ].
	response := self ensureOllamaServiceAvailable.
	response ifNil: [ ^ false ].
	availableModels := self modelNamesFromResponse: response.
	(availableModels includes: modelName) ifTrue: [ ^ true ].
	self autoInstallModelScriptEnabled ifFalse: [ ^ false ].
	(self attemptAutoInstallForModelNamed: modelName usingInitialResponse: response) ifTrue: [ ^ true ].
	(self promptToInstallMissingModelNamed: modelName availableModels: availableModels) ifTrue: [
		(self performInstallOfModelNamed: modelName usingInitialResponse: response) ifTrue: [ ^ true ] ].
	self notifyUser:
		('We could not find this model in your Ollama installation. If you recently requested its installation, please wait while it completes.'
			 format: { modelName }).
	^ false
]

{ #category : 'accessing' }
CopilotSettings class >> fetchModelMetadata [

	| client response metadata modelName |
	metadata := Dictionary new.
	self ensureSelectedModelAvailable ifFalse: [ ^ metadata ].
	modelName := self modelName.
	(self isNullModelName: modelName) ifTrue: [
			metadata := self nullModelMetadata.
			^ metadata ].
	[
		client := self newOllamaClient.
		response := client showModelNamed: modelName.
		response ifNil: [ ^ metadata ].
		self populateMetadata: metadata fromResponse: response.
		self saveModelMetadataFilesFor: metadata.
		 ]
		on: Error
		do: [ :ex |
				 ].
	^ metadata
]

{ #category : 'accessing' }
CopilotSettings class >> fimTemplate [

	    | metadata template |
    metadata := self modelMetadata.
    metadata ifNil: [ ^ self defaultFimTemplate ].
    template := metadata at: #template ifAbsent: [ metadata at: 'template' ifAbsent: [ nil ] ].
    template ifNil: [ ^ self defaultFimTemplate ].
    (template respondsTo: #asString) ifFalse: [ ^ self defaultFimTemplate ].
    template := template asString.
    (template isEmpty or: [
        (template includesSubstring: '%1') not or: [ (template includesSubstring: '%2') not ] ])
        ifTrue: [ ^ self defaultFimTemplate ].
    ^ template
]

{ #category : 'accessing' }
CopilotSettings class >> fimTemplateFromBundledTemplates [

	| directory sanitizedName candidates |
	directory := self templatesDirectory.
	directory exists ifFalse: [ ^ nil ].
	sanitizedName := self sanitizedFileComponentFor: self modelName default: 'unknown-model'.
	candidates := OrderedCollection new.
	candidates add: directory / sanitizedName / 'template.txt'.
	candidates add: directory / 'template.txt'.
	candidates do: [ :each |
			| value |
			value := self fimTemplateFromFile: each.
			 value ifNotNil: [ ^ value ] ].
	
]

{ #category : 'accessing' }
CopilotSettings class >> fimTemplateFromFile: aFileReference [

	| file contents |
	aFileReference ifNil: [ ^ nil ].
	file := aFileReference asFileReference.
	(file exists and: [ file isFile ]) ifFalse: [ ^ nil ].
	contents := [ file readStreamDo: [ :stream | stream contents ] ]
		            on: Error
		            do: [ :ex |
				            ^ nil ].
	(contents respondsTo: #asString) ifFalse: [ ^ nil ].
	contents := contents asString.
	contents isEmpty ifTrue: [ ^ nil ].
	^ contents
]

{ #category : 'accessing' }
CopilotSettings class >> host [

    ^ Host ifNil: [ Host := '127.0.0.1' ].
]

{ #category : 'accessing' }
CopilotSettings class >> host: aString [

    Host := aString.
self clearCachedModelMetadata.
]

{ #category : 'accessing' }
CopilotSettings class >> installModelNamed: modelName [

	| client |
	[
		client := self newOllamaClient.
		self notifyUser: ('Downloading... This may take a few minutes.' format: { modelName }).
		client pullModelNamed: modelName.
		^ true ]
		on: Error
		do: [ :ex |
				^ false ]
]

{ #category : 'accessing' }
CopilotSettings class >> isCopilotEngineSelected [

	^ [
		  | currentEngine |
		  currentEngine := RubSmalltalkEditor completionEngineClass.
		  currentEngine notNil and: [
			  currentEngine name = 'CoCompletionEnginePharoCopilot' or: [ currentEngine name includesSubstring: 'Copilot' ] ] ]
		  on: Error
		  do: [ false ]
]

{ #category : 'accessing' }
CopilotSettings class >> isNullModelName: aString [

        ^ aString = self nullModelFullName
]

{ #category : 'accessing' }
CopilotSettings class >> metadataStringForKey: aKey default: defaultString [
    | metadata value |
    metadata := self modelMetadata.
    value := metadata
        at: aKey
        ifAbsent: [ metadata at: aKey asString ifAbsent: [ nil ] ].
    value isNil ifTrue: [ ^ defaultString ].
    value isString ifTrue: [ value isEmpty ifTrue: [ ^ defaultString ]. ^ value ].
    (value respondsTo: #asString)
        ifTrue: [ | converted |
            converted := value asString.
            converted isEmpty ifTrue: [ ^ defaultString ].
            ^ converted ].
    [
        | json |
        json := STONJSON toString: value.
        json isEmpty ifTrue: [ ^ defaultString ].
        ^ json
    ] on: Error do: [ :ignored | ].
    ^ value printString
]

{ #category : 'accessing' }
CopilotSettings class >> modelMetadata [
    ModelMetadata ifNil: [ ModelMetadata := self fetchModelMetadata ].
    ^ ModelMetadata
]

{ #category : 'accessing' }
CopilotSettings class >> modelName [

	^ ModelName ifNil: [ ModelName := OllamaClient defaultModelFullName ]
]

{ #category : 'accessing' }
CopilotSettings class >> modelName: aString [

	ModelName := aString.
	self clearCachedModelMetadata.
]

{ #category : 'settings' }
CopilotSettings class >> modelNamesFromResponse: response [

    | models names |
    response ifNil: [ ^ #() ].
    (response respondsTo: #at:ifAbsent:) ifFalse: [ ^ #() ].
    models := response at: #models ifAbsent: [ response at: 'models' ifAbsent: [ #() ] ].
    (models respondsTo: #do:) ifFalse: [ ^ #() ].
    names := OrderedCollection new.
    models do: [ :each |
        | name |
        name := each.
        (each respondsTo: #at:ifAbsent:)
            ifTrue: [ name := each at: #name ifAbsent: [ each at: 'name' ifAbsent: [ nil ] ] ].
        name ifNotNil: [ names add: name ].
    ].
    ^ names asArray
]

{ #category : 'accessing' }
CopilotSettings class >> modelParameters [
    ^ self metadataStringForKey: #parameters default: 'Not provided by model.'
]

{ #category : 'accessing' }
CopilotSettings class >> modelParameters: ignored [
    "Ignore attempts to set read-only metadata from the settings UI"
]

{ #category : 'accessing' }
CopilotSettings class >> modelSystemPrompt [
    ^ self metadataStringForKey: #system default: 'Not provided by model.'
]

{ #category : 'accessing' }
CopilotSettings class >> modelSystemPrompt: ignored [
    "Ignore attempts to set read-only metadata from the settings UI"
]

{ #category : 'accessing' }
CopilotSettings class >> modelTemplate [
    ^ self metadataStringForKey: #template default: 'Not provided by model.'
]

{ #category : 'accessing' }
CopilotSettings class >> modelTemplate: ignored [
    "Ignore attempts to set read-only metadata from the settings UI"
]

{ #category : 'accessing' }
CopilotSettings class >> newOllamaClient [
    ^ self ollamaClientFactory value
]

{ #category : 'settings' }
CopilotSettings class >> notifyUser: aString [

    | uiClass uiManager transcript |
    uiClass := Smalltalk globals at: #UIManager ifAbsent: [ nil ].
    uiClass ifNotNil: [
        (uiClass respondsTo: #default)
            ifTrue: [
                uiManager := uiClass default.
                (uiManager respondsTo: #inform:)
                    ifTrue: [ uiManager inform: aString. ^ self ].
            ].
    ].
    transcript := Smalltalk globals at: #Transcript ifAbsent: [ nil ].
    transcript ifNotNil: [
        (transcript respondsTo: #show:)
            ifTrue: [ transcript show: aString; cr ].
    ].
]

{ #category : 'accessing' }
CopilotSettings class >> nullModelFullName [

        ^ OllamaClient nullModelFullName
]

{ #category : 'accessing' }
CopilotSettings class >> nullModelMetadata [

| details modelfile |
details := Dictionary new
at: #family put: 'pharo-copilot';
at: #description put: 'Placeholder metadata for the Pharo Copilot null model. Configure an Ollama model to enable completions.';
at: #status put: 'inactive';
yourself.
modelfile := String streamContents: [ :stream |
stream nextPutAll: '# Modelfile placeholder for the Pharo Copilot null model'.
stream nextPutAll: String crlf.
stream nextPutAll: '# Configure an Ollama model in the settings to enable completions.' ].
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
    OllamaClientFactory ifNil: [ OllamaClientFactory := [ OllamaClient new ] ].
    ^ OllamaClientFactory
]

{ #category : 'accessing' }
CopilotSettings class >> ollamaClientFactory: aBlockClosure [
    OllamaClientFactory := aBlockClosure.
    self clearCachedModelMetadata.
]

{ #category : 'settings' }
CopilotSettings class >> performInstallOfModelNamed: modelName usingInitialResponse: response [

    ^ (self installModelNamed: modelName)
        and: [ self refreshModelsAfterInstallOf: modelName usingInitialResponse: response ]
]

{ #category : 'accessing' }
CopilotSettings class >> populateMetadata: metadata fromResponse: response [

  | keys details parsedResponse |
    response ifNil: [ ^ metadata ].
    parsedResponse := response.
    parsedResponse isString ifTrue: [
        [ parsedResponse := STONJSON fromString: parsedResponse ] 
            on: Error do: [ ^ metadata ].
    ].
    (parsedResponse respondsTo: #at:ifAbsent:) ifFalse: [ ^ metadata ].
    keys := #(#template #system #parameters #modelfile).
    keys do: [ :key |
        | value altKey |
        altKey := key asString.
        value := parsedResponse at: key ifAbsent: [ parsedResponse at: altKey ifAbsent: [ nil ] ].
        value ifNotNil: [ metadata at: key put: value ].
    ].
    details := parsedResponse at: #details ifAbsent: [ parsedResponse at: 'details' ifAbsent: [ nil ] ].
    details ifNotNil: [ metadata at: #details put: details ].
    metadata at: #model put: (parsedResponse at: #model ifAbsent: [ parsedResponse at: 'model' ifAbsent: [ self modelName ] ]).
    ^ metadata

]

{ #category : 'accessing' }
CopilotSettings class >> port [

    ^ Port ifNil: [ Port := 11434 ].
]

{ #category : 'accessing' }
CopilotSettings class >> port: aNumber [

	Port := aNumber isString
		        ifTrue: [
				        [ aNumber asNumber ]
					        on: Error
					        do: [ self port ] ]
		        ifFalse: [ aNumber ].
		self clearCachedModelMetadata.
]

{ #category : 'settings' }
CopilotSettings class >> promptToInstallMissingModelNamed: modelName availableModels: availableModels [

	| uiClass uiManager confirmation message transcript |
	message := 'This model is not available, Do you want to install it ? ' format: { modelName }.
	uiClass := Smalltalk globals at: #UIManager ifAbsent: [ nil ].
	uiClass ifNotNil: [
			(uiClass respondsTo: #default) ifTrue: [
					uiManager := uiClass default.
					(uiManager respondsTo: #confirm:) ifTrue: [ confirmation := uiManager confirm: message ] ] ].
	confirmation ifNil: [
			transcript := Smalltalk globals at: #Transcript ifAbsent: [ nil ].
			transcript ifNotNil: [
					(transcript respondsTo: #show:) ifTrue: [
							transcript
								show: message;
								cr ] ].
			^ false ].
	^ confirmation
]

{ #category : 'settings' }
CopilotSettings class >> refreshModelsAfterInstallOf: modelName usingInitialResponse: initialResponse [

    [
        | refreshedResponse refreshedModels |
        refreshedResponse := self newOllamaClient listModels.
        refreshedModels := self modelNamesFromResponse: refreshedResponse.
        (refreshedModels includes: modelName) ifTrue: [
            [ OModelRegistry refresh ] on: Error do: [ :ignored | ].
            ^ true
        ].
     
    ] on: Error do: [ :ex |
    ].
    ^ false
]

{ #category : 'accessing' }
CopilotSettings class >> resetToDefaultSettings [

	Enabled := nil.
	Provider := nil.
	ModelName := nil.
	Host := nil.
	Port := nil.
	ModelMetadata := nil.
	OllamaClientFactory := nil.
	AutoInstallModelScriptEnabled := nil.
	TemplatesDirectory := nil
]

{ #category : 'accessing' }
CopilotSettings class >> restoreSettingsFromSnapshot: aDictionary [

	Enabled := aDictionary at: #Enabled ifAbsent: [ nil ].
	Provider := aDictionary at: #Provider ifAbsent: [ nil ].
	ModelName := aDictionary at: #ModelName ifAbsent: [ nil ].
	Host := aDictionary at: #Host ifAbsent: [ nil ].
	Port := aDictionary at: #Port ifAbsent: [ nil ].
	ModelMetadata := aDictionary at: #ModelMetadata ifAbsent: [ nil ].
	OllamaClientFactory := aDictionary at: #OllamaClientFactory ifAbsent: [ nil ].
	AutoInstallModelScriptEnabled := aDictionary at: #AutoInstallModelScriptEnabled ifAbsent: [ nil ].
	TemplatesDirectory := aDictionary at: #TemplatesDirectory ifAbsent: [ nil ]
]

{ #category : 'accessing' }
CopilotSettings class >> sanitizedFileComponentFor: anObject default: defaultString [

    | candidate |
    anObject isNil ifTrue: [ ^ defaultString asFileName ].
    candidate := [ anObject asString ] on: Error do: [ anObject printString ].
    (candidate isNil or: [ candidate isEmpty ]) ifTrue: [ ^ defaultString asFileName ].
    ^ candidate asFileName
]

{ #category : 'settings' }
CopilotSettings class >> settingsOn: aBuilder [
	"Only show copilot settings if copilot engine is selected"

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

				(aBuilder setting: #autoInstallModelScriptEnabled)
					order: 0.4;
					label: 'Auto-install Pharo coder model';
					target: self;
					getSelector: #autoInstallModelScriptEnabled;
					setSelector: #autoInstallModelScriptEnabled:;
					default: self autoInstallModelScriptEnabled;
					description:
						'When enabled, Pharo Copilot automatically runs the installation script if the "pharo-coder-1.5b-fim-f16.gguf:latest" model is missing.'.



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
					default: self port.]
]

{ #category : 'accessing' }
CopilotSettings class >> settingsSnapshot [

	^ Dictionary new
		  at: #Enabled put: Enabled;
		  at: #Provider put: Provider;
		  at: #ModelName put: ModelName;
		  at: #Host put: Host;
		  at: #Port put: Port;
		  at: #ModelMetadata put: ModelMetadata;
		  at: #OllamaClientFactory put: OllamaClientFactory;
		  at: #AutoInstallModelScriptEnabled put: AutoInstallModelScriptEnabled;
		at: #TemplatesDirectory put: TemplatesDirectory;
		  yourself
]

{ #category : 'accessing' }
CopilotSettings class >> shouldAutoInstallModelNamed: modelName [

    (self autoInstallModelScriptEnabled) ifFalse: [ ^ false ].
    modelName ifNil: [ ^ false ].
    (modelName respondsTo: #isEmpty) ifTrue: [ modelName isEmpty ifTrue: [ ^ false ] ].
    (self isNullModelName: modelName) ifTrue: [ ^ false ].
    ^ true
]

{ #category : 'accessing' }
CopilotSettings class >> shouldShowDetailedSettings [
    "Show detailed settings if copilot is enabled"
    
    ^ self copilotEnabled

]

{ #category : 'accessing' }
CopilotSettings class >> showInstallCompletionDialog [

| message uiClass uiManager transcript |
message := 'Pharo Copilot installed ' , String cr , 'Welcome to Pharo-Copilot' , String cr
           , 'Ollama runs your models locally, so none of your data is sent anywhere.' , String cr
           , 'Everything is already configured—just open your Browser and start typing.' , String cr
           , 'For more details, visit our documentation' , String cr.
	uiClass := Smalltalk globals at: #UIManager ifAbsent: [ nil ].
	uiClass ifNotNil: [
			(uiClass respondsTo: #default) ifTrue: [
					uiManager := uiClass default.
					(uiManager respondsTo: #longMessage:title:) ifTrue: [ ^ uiManager longMessage: message title: 'Pharo Copilot setup' ].
					(uiManager respondsTo: #inform:) ifTrue: [ ^ uiManager inform: message ] ] ].
	transcript := Smalltalk globals at: #Transcript ifAbsent: [ nil ].
	transcript ifNotNil: [
			(transcript respondsTo: #show:) ifTrue: [
					transcript
						show: message;
						cr ] ]
]

{ #category : 'accessing' }
CopilotSettings class >> templateFileForModelNamed: aModelName [
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
    ^ TemplatesDirectory ifNil: [
        TemplatesDirectory := (FileLocator imageDirectory / 'pharo-copilot' / 'templates') asFileReference ]
]

{ #category : 'accessing' }
CopilotSettings class >> templatesDirectory: aFileReference [

    TemplatesDirectory := aFileReference asFileReference
]

{ #category : 'accessing' }
CopilotSettings class >> withDefaultSettingsDo: aBlock [

    | snapshot |
    snapshot := self settingsSnapshot.
    [
        self resetToDefaultSettings.
        aBlock value
    ] ensure: [ self restoreSettingsFromSnapshot: snapshot ]
]
