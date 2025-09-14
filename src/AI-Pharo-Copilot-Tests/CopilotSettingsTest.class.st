Class {
	#name : 'CopilotSettingsTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
CopilotSettingsTest >> testAvailableModelName [
    | domain |
    domain := CopilotSettings availableModelNames.
    self assert: domain size > 0.
    self assert: (domain anySatisfy: [:assoc | assoc key = 'Code Llama 7B' and: [assoc value = 'codellama:7b']]).
self assert: (domain anySatisfy: [:assoc | assoc key = 'Code Llama 13B' and: [assoc value = 'codellama:13b']]).
]

{ #category : 'tests' }
CopilotSettingsTest >> testAvailableProvidersContainsOnlyValidSymbols [
	| providers |
	providers := CopilotSettings availableProviders.
	
	self assert: providers isCollection.
	providers do: [ :provider |
		self assert: provider isSymbol ]
]

{ #category : 'tests' }
CopilotSettingsTest >> testAvailableProvidersIncludesOllama [
    self assert: (CopilotSettings availableProviders includes: #ollama).
]

{ #category : 'tests' }
CopilotSettingsTest >> testCopilotEnabledAccessor [
    | old |
    old := CopilotSettings copilotEnabled.
    self assert: old equals: true.
    CopilotSettings copilotEnabled: false.
    self assert: CopilotSettings copilotEnabled equals: false.
    CopilotSettings copilotEnabled: true.
    self assert: CopilotSettings copilotEnabled equals: true.
    CopilotSettings copilotEnabled: old.
]

{ #category : 'tests' }
CopilotSettingsTest >> testCopilotProviderAccessor [
    | old |
    old := CopilotSettings copilotProvider.
    self assert: old equals: #ollama.
    CopilotSettings copilotProvider: #foo.
    self assert: CopilotSettings copilotProvider equals: #foo.
    CopilotSettings copilotProvider: old.
]

{ #category : 'tests' }
CopilotSettingsTest >> testDefaultValues [
	"Test that defaults are sensible without changing global state"

	| enabled provider model useEnter template |
	"Store current values"
	enabled := CopilotSettings copilotEnabled.
	provider := CopilotSettings copilotProvider.
	model := CopilotSettings modelName.
	useEnter := CopilotSettings useEnterToAccept.
	template := CopilotSettings fimTemplate. "Check defaults are reasonable"
	self assert: (enabled isKindOf: Boolean ).
	self assert: provider isSymbol.
	self assert: model isString.
	self assert: (useEnter isKindOf: Boolean).
	self assert: template isString.
	self assert: (template includesSubstring: '%1').
	self assert: (template includesSubstring: '%2')
]

{ #category : 'tests' }
CopilotSettingsTest >> testFimTemplateAccessor [
    | old |
    old := CopilotSettings fimTemplate.
    CopilotSettings fimTemplate: '<<PRE>>%1<<SUF>>%2<<MID>>'.
    self assert: CopilotSettings fimTemplate equals: '<<PRE>>%1<<SUF>>%2<<MID>>'.
    CopilotSettings fimTemplate: old.
]

{ #category : 'tests' }
CopilotSettingsTest >> testFimTemplateValidation [
	| template |
	template := CopilotSettings fimTemplate.
	
	"Template should contain placeholders for prefix and suffix"
	self assert: (template includesSubstring: '%1').
	self assert: (template includesSubstring: '%2')
]

{ #category : 'tests' }
CopilotSettingsTest >> testModelNameAccessor [
    | old |
    old := CopilotSettings modelName.
    self assert: old equals: OllamaClient defaultModelFullName.
    CopilotSettings modelName: 'foo'.
    self assert: CopilotSettings modelName equals: 'foo'.
    CopilotSettings modelName: old.
]

{ #category : 'tests' }
CopilotSettingsTest >> testModelNameReturnsString [
	| modelName |
	modelName := CopilotSettings modelName.
	
	self assert: modelName isString.
	self deny: modelName isEmpty
]

{ #category : 'tests' }
CopilotSettingsTest >> testUseEnterToAcceptAccessor [
    | old |
    old := CopilotSettings useEnterToAccept.
    self assert: old equals: true.
    CopilotSettings useEnterToAccept: false.
    self assert: CopilotSettings useEnterToAccept equals: false.
    CopilotSettings useEnterToAccept: old.
]
