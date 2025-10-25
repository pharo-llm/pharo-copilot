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
		'FimTemplate',
		'Host',
		'Port',
		'FimTemplateOption',
		'CustomFimTemplateFile',
		'ModelMetadata',
		'OllamaClientFactory',
		'AutoInstallModelScriptEnabled',
		'LoggingEnabled'
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

{ #category : 'accessing' }
CopilotSettings class >> availableFimTemplateOptions [

    ^ {
        'Inline (edit below)' -> #inline.
        'Custom template file' -> #customFile
    }
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
CopilotSettings class >> customFimTemplateFile [

    ^ (CustomFimTemplateFile ifNil: [ CustomFimTemplateFile := self defaultCustomFimTemplateFile ]) asFileReference
]

{ #category : 'accessing' }
CopilotSettings class >> customFimTemplateFile: aFileReferenceOrString [

    CustomFimTemplateFile := aFileReferenceOrString asFileReference.
    ^ CustomFimTemplateFile
]

{ #category : 'accessing' }
CopilotSettings class >> customFimTemplateFilePath [

    ^ self customFimTemplateFile fullName
]

{ #category : 'accessing' }
CopilotSettings class >> customFimTemplateFilePath: aString [

    aString ifNil: [ ^ self ].
    aString isEmpty ifTrue: [ ^ self ].
    self customFimTemplateFile: aString.
    self fimTemplateOption = #customFile ifTrue: [ self ensureCustomFimTemplateFile ].
]

{ #category : 'accessing' }
CopilotSettings class >> customFimTemplateFromFile [

    | file contents |
    file := self ensureCustomFimTemplateFile.
    contents := [ file contents ]
        on: Error
        do: [ ^ FimTemplate ifNil: [ self defaultFimTemplate ] ].
    contents ifNil: [ ^ FimTemplate ifNil: [ self defaultFimTemplate ] ].
    contents isEmpty ifTrue: [ ^ FimTemplate ifNil: [ self defaultFimTemplate ] ].
    ^ contents
]

{ #category : 'accessing' }
CopilotSettings class >> defaultCustomFimTemplateFile [

	^ (self templatesDirectory / 'custom-fim-template.tmpl') asFileReference
]

{ #category : 'accessing' }
CopilotSettings class >> defaultFimTemplate [

	    | file contents |
    file := self ensureDefaultFimTemplateFile.
    contents := [ file contents ] on: Error do: [ ^ self defaultFimTemplateString ].
    (contents isNil or: [ contents isEmpty ]) ifTrue: [ ^ self defaultFimTemplateString ].
    ^ contents
]

{ #category : 'accessing' }
CopilotSettings class >> defaultFimTemplateFile [
    ^ self templatesDirectory / 'inline-fim-template.tmpl'
]

{ #category : 'accessing' }
CopilotSettings class >> defaultFimTemplateString [
    ^ '<PRE>%1<SUF>%2<MID>'
]

{ #category : 'accessing' }
CopilotSettings class >> ensureCustomFimTemplateFile [

	| file |
    file := self customFimTemplateFile.
    [ file parent ensureCreateDirectory ] on: Error do: [ :ignored | ].
    file exists ifFalse: [
	        | initialTemplate |
        initialTemplate := FimTemplate ifNil: [ self defaultFimTemplate ].
        [ file ensureCreateFile ] on: Error do: [ :ignored | ].
        [ file writeStreamDo: [ :stream | stream nextPutAll: initialTemplate ] ] on: Error do: [ :ignored | ].
    ].
    ^ file
]

{ #category : 'accessing' }
CopilotSettings class >> ensureDefaultFimTemplateFile [
    | file |
    file := self defaultFimTemplateFile.
    [ file parent ensureCreateDirectory ] on: Error do: [ :ignored | ].
    file exists ifFalse: [
        [ file ensureCreateFile ] on: Error do: [ :ignored | ].
        [ file writeStreamDo: [ :stream | stream nextPutAll: self defaultFimTemplateString ] ] on: Error do: [ :ignored | ].
    ].
    ^ file
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

	self fimTemplateOption = #customFile ifTrue: [ ^ self customFimTemplateFromFile ].
    ^ FimTemplate ifNil: [ FimTemplate := self defaultFimTemplate ].
]

{ #category : 'accessing' }
CopilotSettings class >> fimTemplate: aString [

	FimTemplate := aString.
	self fimTemplateOption: #inline.
]

{ #category : 'accessing' }
CopilotSettings class >> fimTemplateOption [

    ^ FimTemplateOption ifNil: [ FimTemplateOption := #inline ].
]

{ #category : 'accessing' }
CopilotSettings class >> fimTemplateOption: aSymbol [

    | normalized |
    normalized := aSymbol ifNil: [ #inline ].
    (normalized isSymbol) ifFalse: [
        (normalized respondsTo: #asSymbol)
            ifTrue: [ normalized := normalized asSymbol ]
            ifFalse: [ normalized := #inline ]
    ].
    (#(#inline #customFile) includes: normalized)
        ifFalse: [ normalized := #inline ].
    FimTemplateOption := normalized.
    normalized = #inline ifTrue: [ FimTemplate ifNil: [ FimTemplate := self defaultFimTemplate ] ].
    normalized = #customFile ifTrue: [ self ensureCustomFimTemplateFile ].
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
	FimTemplate := nil.
	Host := nil.
	Port := nil.
	FimTemplateOption := nil.
	CustomFimTemplateFile := nil.
	ModelMetadata := nil.
	OllamaClientFactory := nil.
	    AutoInstallModelScriptEnabled := nil.
    LoggingEnabled := nil.
]

{ #category : 'accessing' }
CopilotSettings class >> restoreSettingsFromSnapshot: aDictionary [

	Enabled := aDictionary at: #Enabled ifAbsent: [ nil ].
	Provider := aDictionary at: #Provider ifAbsent: [ nil ].
	ModelName := aDictionary at: #ModelName ifAbsent: [ nil ].
	FimTemplate := aDictionary at: #FimTemplate ifAbsent: [ nil ].
	Host := aDictionary at: #Host ifAbsent: [ nil ].
	Port := aDictionary at: #Port ifAbsent: [ nil ].
	FimTemplateOption := aDictionary at: #FimTemplateOption ifAbsent: [ nil ].
	CustomFimTemplateFile := aDictionary at: #CustomFimTemplateFile ifAbsent: [ nil ].
	ModelMetadata := aDictionary at: #ModelMetadata ifAbsent: [ nil ].
	OllamaClientFactory := aDictionary at: #OllamaClientFactory ifAbsent: [ nil ].
	AutoInstallModelScriptEnabled := aDictionary at: #AutoInstallModelScriptEnabled ifAbsent: [ nil ].
	        LoggingEnabled := aDictionary at: #LoggingEnabled ifAbsent: [ nil ].
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
	self isCopilotEngineSelected ifFalse: [ ^ self ].

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

				(aBuilder setting: #modelTemplate)
					order: 0.5;
					label: 'Model template (read only)';
					target: self;
					getSelector: #modelTemplate;
					setSelector: #modelTemplate:;
					default: self modelTemplate;
					description: 'Template provided by the selected Ollama model. This value is fetched from the server and cannot be edited.'.

				(aBuilder setting: #modelSystemPrompt)
					order: 0.6;
					label: 'Model system prompt (read only)';
					target: self;
					getSelector: #modelSystemPrompt;
					setSelector: #modelSystemPrompt:;
					default: self modelSystemPrompt;
					description: 'System prompt defined by the selected Ollama model, when available.'.


				(aBuilder setting: #modelParameters)
					order: 0.7;
					label: 'Model parameters (read only)';
					target: self;
					getSelector: #modelParameters;
					setSelector: #modelParameters:;
					default: self modelParameters;
					description: 'Model parameters provided by the Ollama model definition.'.


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

				(aBuilder pickOne: #fimTemplateOption)
					label: 'FIM template source';
					target: self;
					getSelector: #fimTemplateOption;
					setSelector: #fimTemplateOption:;
					default: self fimTemplateOption;
					domainValues: self availableFimTemplateOptions.

				(aBuilder setting: #fimTemplate)
					label: 'FIM template';
					target: self;
					getSelector: #fimTemplate;
					setSelector: #fimTemplate:;
					default: self fimTemplate;
					description: 'Inline template used when the source is set to "Inline (edit below)".'.

				(aBuilder setting: #customFimTemplateFilePath)
					label: 'Custom FIM template file';
					target: self;
					getSelector: #customFimTemplateFilePath;
					setSelector: #customFimTemplateFilePath:;
					default: self customFimTemplateFilePath;
					description: 'Used when the source is set to "Custom template file". The file is created automatically if it does not exist.' ]
]

{ #category : 'accessing' }
CopilotSettings class >> settingsSnapshot [

	^ Dictionary new
		  at: #Enabled put: Enabled;
		  at: #Provider put: Provider;
		  at: #ModelName put: ModelName;
		  at: #FimTemplate put: FimTemplate;
		  at: #Host put: Host;
		  at: #Port put: Port;
		  at: #FimTemplateOption put: FimTemplateOption;
		  at: #CustomFimTemplateFile put: CustomFimTemplateFile;
		  at: #ModelMetadata put: ModelMetadata;
		  at: #OllamaClientFactory put: OllamaClientFactory;
		        at: #AutoInstallModelScriptEnabled put: AutoInstallModelScriptEnabled;
        at: #LoggingEnabled put: LoggingEnabled;
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
CopilotSettings class >> templatesDirectory [
    ^ (FileLocator imageDirectory / 'pharo-copilot' / 'templates') asFileReference
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
