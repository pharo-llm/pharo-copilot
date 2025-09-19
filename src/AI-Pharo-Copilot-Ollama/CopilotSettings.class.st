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
		'UseEnterToAccept',
		'FimTemplate',
		'Host',
		'Port',
		'FimTemplateOption',
		'CustomFimTemplateFile'
	],
	#category : 'AI-Pharo-Copilot-Ollama',
	#package : 'AI-Pharo-Copilot-Ollama'
}

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

    ^ (FileLocator imageDirectory / 'pharo-copilot' / 'custom-fim-template.tmpl') asFileReference
]

{ #category : 'accessing' }
CopilotSettings class >> defaultFimTemplate [

    ^ '<PRE>%1<SUF>%2<MID>'
]

{ #category : 'accessing' }
CopilotSettings class >> ensureCustomFimTemplateFile [

    | file |
    file := self customFimTemplateFile.
    [ file parent ensureCreateDirectory ] on: Error do: [ :ignored | ].
    file exists ifFalse: [
        [ file ensureCreateFile ] on: Error do: [ :ignored | ].
    ].
    ^ file
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
]

{ #category : 'accessing' }
CopilotSettings class >> modelName [

	^ ModelName ifNil: [ ModelName := OllamaClient defaultModelFullName ]
]

{ #category : 'accessing' }
CopilotSettings class >> modelName: aString [

    ModelName := aString.
]

{ #category : 'accessing' }
CopilotSettings class >> port [

    ^ Port ifNil: [ Port := 11434 ].
]

{ #category : 'accessing' }
CopilotSettings class >> port: aNumber [
    Port := (aNumber isString)
            ifTrue: [
                [ aNumber asNumber ] on: Error do: [ self port ]
            ]
            ifFalse: [ aNumber ].
]

{ #category : 'settings' }
CopilotSettings class >> settingsOn: aBuilder [

	<systemsettings>
	(aBuilder setting: #Copilot)
		target: self;
		parentName: #codeBrowsing;
		selector: #copilotEnabled;
		default: true;
		iconName: #smallConfiguration;
		description: 'Enable Copilot inline suggestions and configure its backend.';
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
                                        description: 'Used when the source is set to "Custom template file". The file is created automatically if it does not exist.'.

				(aBuilder setting: #useEnterToAccept)
					label: 'Use ENTER to accept a suggestion';
					target: self;
					getSelector: #useEnterToAccept;
					setSelector: #useEnterToAccept:;
					default: self useEnterToAccept ]
]

{ #category : 'accessing' }
CopilotSettings class >> useEnterToAccept [

    ^ UseEnterToAccept ifNil: [ UseEnterToAccept := true ].
]

{ #category : 'accessing' }
CopilotSettings class >> useEnterToAccept: aBool [

    UseEnterToAccept := aBool.
]
