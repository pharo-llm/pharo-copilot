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
		'MaxSuggestions',
		'UseEnterToAccept',
		'FimTemplate'
	],
	#category : 'AI-Pharo-Copilot-Ollama',
	#package : 'AI-Pharo-Copilot-Ollama'
}

{ #category : 'settings' }
CopilotSettings class >> availableModelNames [

	^ OModelRegistry build domainValuesForSettings
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
CopilotSettings class >> fimTemplate [

    ^ FimTemplate ifNil: [ FimTemplate := '<PRE>%1<SUF>%2<MID>' ].
]

{ #category : 'accessing' }
CopilotSettings class >> fimTemplate: aString [

    FimTemplate := aString.
]

{ #category : 'accessing' }
CopilotSettings class >> maxSuggestions [

    ^ MaxSuggestions ifNil: [ MaxSuggestions := 3 ].

]

{ #category : 'accessing' }
CopilotSettings class >> maxSuggestions: anInteger [

    MaxSuggestions := anInteger max: 1.
]

{ #category : 'accessing' }
CopilotSettings class >> modelName [

	^ ModelName ifNil: [ ModelName := OllamaClient defaultModelFullName ]
]

{ #category : 'accessing' }
CopilotSettings class >> modelName: aString [

    ModelName := aString.
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

				(aBuilder setting: #maxSuggestions)
					label: 'Maximum suggestions';
					target: self;
					getSelector: #maxSuggestions;
					setSelector: #maxSuggestions:;
					default: self maxSuggestions.

				(aBuilder setting: #fimTemplate)
					label: 'FIM template';
					target: self;
					getSelector: #fimTemplate;
					setSelector: #fimTemplate:;
					default: self fimTemplate.
					
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
