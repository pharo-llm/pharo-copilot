Class {
	#name : 'IntegrationTest',
	#superclass : 'CopilotMockModelTestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
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
	engine := CoPharoCopilotCompletionEngine new.
	context := CoPCContext new.
	builder := engine completionBuilder.
	
	"Test that engine and context work together"
	self assert: builder class equals: CoPharoCopilotResultSetBuilder.
	self assert: context completionBuilder class equals: CoPharoCopilotResultSetBuilder
]

{ #category : 'tests' }
IntegrationTest >> testModelRegistryAndClientIntegration [
	| client registry spec |
	client := CoPCOllamaClient new.
	registry := CoPCModelRegistry current.
	
	"Test that client uses registry correctly"
	spec := registry specByFullName: client class defaultModelFullName.
	
	"Should either find the spec or handle gracefully"
	spec ifNotNil: [
		self assert: (spec isKindOf: CoPCModelSpec).
		self assert: spec fullName isString ]
]

{ #category : 'tests' }
IntegrationTest >> testSettingsAndClientIntegration [
	| oldModel client |
	oldModel := CopilotSettings modelName.
	
	[
		"Test settings integration with client"
		CopilotSettings modelName: 'test:model'.
		client := CoPCOllamaClient new.
		
		self assert: (client instVarNamed: 'modelSpec') fullName equals: 'test:model'
	] ensure: [
		CopilotSettings modelName: oldModel
	]
]

{ #category : 'tests' }
IntegrationTest >> testSettingsAndRegistryIntegration [
	| modelNames registry |
	registry := CoPCModelRegistry current.
	modelNames := CopilotSettings availableModelNames.
	
	"Settings should return what registry provides"
	self assert: modelNames size equals: registry domainValuesForSettings size.
	
	modelNames do: [ :assoc |
		| spec |
		spec := registry specByFullName: assoc value.
		self assert: spec notNil.
		self assert: spec label equals: assoc key ]
]
