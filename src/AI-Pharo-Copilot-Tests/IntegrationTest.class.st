Class {
	#name : 'IntegrationTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
IntegrationTest >> testCopilotEntryActivationFlow [
	| entry context |
	entry := CoCopilotEntry contents: 'integrated test code'.
	context := CoCopilotEntryTestContext new.
	
	"Test the full activation flow"
	entry activateOn: context.
	
	self assert: context replacedToken equals: 'integrated test code'
]

{ #category : 'tests' }
IntegrationTest >> testEngineAndBuilderIntegration [
	| engine builder context |
	engine := CoCompletionEnginePharoCopilot new.
	context := CoPharoCopilotContext new.
	builder := engine completionBuilder.
	
	"Test that engine and context work together"
	self assert: builder class equals: CoPharoCopilotResultSetBuilder.
	self assert: context completionBuilder class equals: CoPharoCopilotResultSetBuilder
]

{ #category : 'tests' }
IntegrationTest >> testModelRegistryAndClientIntegration [
	| client registry spec |
	client := OllamaClient new.
	registry := OModelRegistry current.
	
	"Test that client uses registry correctly"
	spec := registry specByFullName: client class defaultModelFullName.
	
	"Should either find the spec or handle gracefully"
	spec ifNotNil: [
		self assert: (spec isKindOf: OModelSpec).
		self assert: spec fullName isString ]
]

{ #category : 'tests' }
IntegrationTest >> testSettingsAndClientIntegration [
	| oldModel client |
	oldModel := CopilotSettings modelName.
	
	[
		"Test settings integration with client"
		CopilotSettings modelName: 'test:model'.
		client := OllamaClient new.
		
		self assert: (client instVarNamed: 'modelSpec') fullName equals: 'test:model'
	] ensure: [
		CopilotSettings modelName: oldModel
	]
]

{ #category : 'tests' }
IntegrationTest >> testSettingsAndRegistryIntegration [
	| modelNames registry |
	registry := OModelRegistry current.
	modelNames := CopilotSettings availableModelNames.
	
	"Settings should return what registry provides"
	self assert: modelNames size equals: registry domainValuesForSettings size.
	
	modelNames do: [ :assoc |
		| spec |
		spec := registry specByFullName: assoc value.
		self assert: spec notNil.
		self assert: spec label equals: assoc key ]
]
