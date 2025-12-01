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
		'LoggingEnabled',
		'TemplatesDirectory'
	],
	#category : 'AI-Pharo-Copilot-Ollama',
	#package : 'AI-Pharo-Copilot-Ollama'
}

{ #category : 'accessing' }
CopilotSettings class >> attemptAutoInstallForModelNamed: modelName usingInitialResponse: response [

    (self shouldAutoInstallModelNamed: modelName) ifFalse: [ ^ false ].
    CoCopilotLogger
        logBackEndEvent: 'Attempting auto-install for missing Ollama model'
        details: (Dictionary new
            at: #model put: modelName;
            at: #availableModelsBefore put: (self modelNamesFromResponse: response);
            yourself).
    (self installModelNamed: modelName) ifFalse: [ ^ false ].
    [
        | refreshedResponse refreshedModels |
        refreshedResponse := self newOllamaClient listModels.
        refreshedModels := self modelNamesFromResponse: refreshedResponse.
        (refreshedModels includes: modelName) ifTrue: [
            CoCopilotLogger
                logBackEndEvent: 'Auto-install detected newly available Ollama model'
                details: (Dictionary new
                    at: #model put: modelName;
                    at: #availableModelsAfter put: refreshedModels;
                    yourself).
            [ OModelRegistry refresh ] on: Error do: [ :ignored | ].
            ^ true
        ].
        CoCopilotLogger
            logBackEndEvent: 'Auto-install did not expose expected Ollama model'
            details: (Dictionary new
                at: #model put: modelName;
                at: #availableModelsAfter put: refreshedModels;
                yourself).
    ] on: Error do: [ :ex |
        CoCopilotLogger
            logError: 'Failed to refresh Ollama models after auto-install'
            origin: #CopilotSettings
            exception: ex
            payload: (Dictionary new
                at: #model put: modelName;
                yourself).
    ].
    ^ false
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

    | template cacheFile |
    cacheFile := self templateFileForModelNamed: self modelName.
    template := self fimTemplateFromFile: cacheFile.
    template ifNotNil: [
        CoCopilotLogger
            logBackEndEvent: 'Using cached FIM template from logs'
            details: (Dictionary new
                at: #model put: (self modelName ifNil: [ 'unknown-model' ]);
                at: #source put: cacheFile pathString;
                yourself).
        ^ template ].
    template := self fimTemplateFromBundledTemplates.
    template ifNotNil: [ ^ template ].
    self logMissingFimTemplate.
    ^ self error: 'No fill-in-the-middle template is available for the current Copilot model.'
]

{ #category : 'settings' }
CopilotSettings class >> ensureOllamaServiceAvailable [

    | response |
    [
        response := self newOllamaClient listModels.
    ]
        on: Error
        do: [ :ex |
            CoCopilotLogger
                logError: 'Ollama service unavailable'
                origin: #CopilotSettings
                exception: ex
                payload: (Dictionary new
                    at: #host put: self host;
                    at: #port put: self port;
                    yourself).
            self notifyUser: 'Ollama is not configured. Please configure it.'.
            ^ nil
        ].
    response ifNil: [
        CoCopilotLogger
            logBackEndEvent: 'Missing response from Ollama service'
            details: (Dictionary new
                at: #host put: self host;
                at: #port put: self port;
                yourself).
        self notifyUser: 'Ollama is not configured. Please configure it.'.
        ^ nil
    ].
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
    CoCopilotLogger
        logBackEndEvent: 'Validated Ollama model availability'
        details: (Dictionary new
            at: #model put: modelName;
            at: #availableModelCount put: availableModels size;
            yourself).
    (availableModels includes: modelName) ifTrue: [ ^ true ].
    (self attemptAutoInstallForModelNamed: modelName usingInitialResponse: response)
        ifTrue: [ ^ true ].
    CoCopilotLogger
        logBackEndEvent: 'Missing Ollama model'
        details: (Dictionary new
            at: #model put: modelName;
            at: #availableModels put: availableModels;
            yourself).
    self
        notifyUser:
            ('We could not find the model "{1}" in your Ollama installation. Do you want to install it?'
                format: { modelName }).
    ^ false
]

{ #category : 'accessing' }
CopilotSettings class >> fetchModelMetadata [

| client response metadata modelName |
metadata := Dictionary new.
(self ensureSelectedModelAvailable) ifFalse: [ ^ metadata ].
modelName := self modelName.
(self isNullModelName: modelName) ifTrue: [
metadata := self nullModelMetadata.
self saveModelMetadataFilesFor: metadata.
CoCopilotLogger
logBackEndEvent: 'Generated null model metadata'
details: (Dictionary new
at: #model put: modelName;
at: #keys put: metadata keys asArray;
yourself).
^ metadata ].
[
client := self newOllamaClient.
response := client showModelNamed: modelName.
response ifNil: [ ^ metadata ].
self populateMetadata: metadata fromResponse: response.
self saveModelMetadataFilesFor: metadata.
CoCopilotLogger
logBackEndEvent: 'Fetched Ollama model metadata'
details: (Dictionary new
at: #model put: (metadata at: #model ifAbsent: [ modelName ]);
at: #keys put: metadata keys asArray;
yourself) ]
on: Error
do: [ :ex |
CoCopilotLogger logBackEndEvent: 'Failed to fetch Ollama model metadata' details: (Dictionary new
at: #model put: modelName;
at: #errorClass put: ex class name;
at: #error put: ex description;
yourself) ].
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
CopilotSettings class >> fimTemplate: ignored [
]

{ #category : 'accessing' }
CopilotSettings class >> fimTemplateFromBundledTemplates [

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
            CoCopilotLogger
                logBackEndEvent: 'Using bundled FIM template'
                details: (Dictionary new
                    at: #model put: (self modelName ifNil: [ 'unknown-model' ]);
                    at: #source put: each pathString;
                    yourself).
            ^ value ] ].
    ^ nil
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
            CoCopilotLogger
                logError: 'Failed to read FIM template file'
                origin: #CopilotSettings
                exception: ex
                payload: (Dictionary new
                    at: #file put: file pathString;
                    yourself).
            ^ nil ].
    (contents respondsTo: #asString) ifFalse: [ ^ nil ].
    contents := contents asString.
    contents isEmpty ifTrue: [ ^ nil ].
    ^ contents
]

{ #category : 'accessing' }
CopilotSettings class >> fimTemplateOption: aString [

	"The inline FIM template is sourced from the templates repository."
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
        CoCopilotLogger
            logBackEndEvent: 'Invoking Ollama model install script'
            details: (Dictionary new
                at: #model put: modelName;
                yourself).
        client pullModelNamed: modelName.
        CoCopilotLogger
            logBackEndEvent: 'Ollama model install script completed'
            details: (Dictionary new
                at: #model put: modelName;
                yourself).
        ^ true
    ] on: Error do: [ :ex |
        CoCopilotLogger
            logError: 'Failed to invoke Ollama model install script'
            origin: #CopilotSettings
            exception: ex
            payload: (Dictionary new
                at: #model put: modelName;
                yourself).
        ^ false
    ]
]

{ #category : 'accessing' }
CopilotSettings class >> isCopilotEngineSelected [
    "Check if the current completion engine is the copilot engine"
    ^ [ 
        | currentEngine |
        currentEngine := RubSmalltalkEditor completionEngineClass.
        currentEngine notNil and: [ 
            currentEngine name = 'CoCompletionEnginePharoCopilot' or: [
                currentEngine name includesSubstring: 'Copilot' ] ]
    ] on: Error do: [ false ]
]

{ #category : 'accessing' }
CopilotSettings class >> isNullModelName: aString [

        ^ aString = self nullModelFullName
]

{ #category : 'accessing' }
CopilotSettings class >> logMissingFimTemplate [

    CoCopilotLogger
        logBackEndEvent: 'Missing FIM template for model'
        details: (Dictionary new
            at: #model put: (self modelName ifNil: [ 'unknown-model' ]);
            at: #templatesDirectory put: self templatesDirectory pathString;
            yourself)
]

{ #category : 'accessing' }
CopilotSettings class >> loggingEnabled [

    ^ LoggingEnabled ifNil: [ LoggingEnabled := true ]
]

{ #category : 'accessing' }
CopilotSettings class >> loggingEnabled: aBoolean [

    LoggingEnabled := aBoolean.
]

{ #category : 'accessing' }
CopilotSettings class >> metadataFileContentsFor: value [

    | formatted |
    formatted := CoCopilotLogger formatValue: value.
    formatted ifNil: [ ^ '' ].
    ^ formatted asString
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

{ #category : 'accessing' }
CopilotSettings class >> removeMetadataTextFilesFrom: aDirectory [

    (aDirectory exists) ifFalse: [ ^ self ].
    [
        aDirectory children do: [ :child |
            (child isFile and: [ ((child extension ifNil: [ '' ]) asLowercase) = 'txt' ]) ifTrue: [
                [ child ensureDelete ] on: Error do: [ :ignored | ] ] ]
        ] on: Error do: [ :ignored | ]
]

{ #category : 'accessing' }
CopilotSettings class >> resetToDefaultSettings [

	<script>
	Enabled := nil.
	Provider := nil.
	ModelName := nil.
	Host := nil.
	Port := nil.
	ModelMetadata := nil.
	OllamaClientFactory := nil.
	AutoInstallModelScriptEnabled := nil.
	LoggingEnabled := nil.
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
	LoggingEnabled := aDictionary at: #LoggingEnabled ifAbsent: [ nil ].
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

{ #category : 'accessing' }
CopilotSettings class >> saveModelMetadataFilesFor: metadata [

    | modelNameValue modelNameString logsDirectory modelDirectory |
    (self loggingEnabled and: [ metadata notNil ]) ifFalse: [ ^ self ].
    metadata isEmpty ifTrue: [ ^ self ].
    modelNameValue := metadata at: #model ifAbsent: [ self modelName ].
    modelNameString := modelNameValue ifNil: [ self modelName ].
    modelNameString isNil ifTrue: [ modelNameString := 'unknown-model' ].
    modelNameString := modelNameString asString.
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
        ^ self
    ].
    self removeMetadataTextFilesFrom: modelDirectory.
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
                stream nextPutAll: contents ]
        ] on: Error do: [ :ex |
            CoCopilotLogger
                logBackEndEvent: 'Failed to write Ollama metadata file'
                details: (Dictionary new
                    at: #model put: modelNameString;
                    at: #key put: keyLabel;
                    at: #file put: fileRef basename;
                    at: #errorClass put: ex class name;
                    at: #error put: ex description;
                    yourself) ]
    ]
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
		  at: #LoggingEnabled put: LoggingEnabled;
		at: #TemplatesDirectory put: TemplatesDirectory;
		  yourself
]

{ #category : 'accessing' }
CopilotSettings class >> shouldAutoInstallModelNamed: modelName [

    (self autoInstallModelScriptEnabled) ifFalse: [ ^ false ].
    modelName ifNil: [ ^ false ].
    ^ modelName = 'pharo-coder-1.5b-fim-f16.gguf:latest'
]

{ #category : 'accessing' }
CopilotSettings class >> shouldShowDetailedSettings [
    "Show detailed settings if copilot is enabled"
    
    ^ self copilotEnabled

]

{ #category : 'accessing' }
CopilotSettings class >> showInstallCompletionDialog [

| message uiClass uiManager transcript |
(SmalltalkImage current isHeadless or: [ OSEnvironment current includesKey: 'CI' ]) ifTrue: [ ^ self ].
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
