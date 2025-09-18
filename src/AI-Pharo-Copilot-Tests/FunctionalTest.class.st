Class {
	#name : 'FunctionalTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
FunctionalTest >> testCompleteWorkflowWithMockedClient [
	"Test the complete workflow from context to suggestion activation"
	| context engine builder entry testContext |
	
	"1. Create context"
	context := CoPharoCopilotContext new.
	context source: 'myMethod: arg | result | result := arg * 2. '.
	context position: context source size.
	
	"2. Get engine and builder"
	engine := CoCompletionEnginePharoCopilot new.
	builder := engine completionBuilder.
	
	"3. Create a mock entry (simulating AI response)"
	entry := CoCopilotEntry contents: '^ result'.
	
	"4. Activate the suggestion"
	testContext := CoCopilotEntryTestContext new.
	entry activateOn: testContext.
	
	"5. Verify the workflow"
	self assert: testContext replacedToken equals: '^ result'
]

{ #category : 'tests' }
FunctionalTest >> testModelManagementWorkflow [
	"Test model selection and usage workflow"
	| oldModel registry client spec |
	oldModel := CopilotSettings modelName.
	
	[
		"1. Get available models"
		registry := OModelRegistry current.
		
		"2. Select a model"
		spec := registry allSpecs first.
		CopilotSettings modelName: spec fullName.
		
		"3. Create client with selected model"
		client := OllamaClient new.
		
		"4. Verify model is used"
		self assert: (client instVarNamed: 'modelSpec') fullName equals: spec fullName
	] ensure: [ CopilotSettings modelName: oldModel ]
]

{ #category : 'tests' }
FunctionalTest >> testSettingsConfigurationWorkflow [
	"Test complete settings configuration workflow"
	| originalSettings newSettings client template |
	
	"1. Save current settings"
	originalSettings := Dictionary new
		at: #enabled put: CopilotSettings copilotEnabled;
		at: #provider put: CopilotSettings copilotProvider;
		at: #model put: CopilotSettings modelName;
		at: #template put: CopilotSettings fimTemplate;
		yourself.
	
	[
		"2. Configure new settings"
		CopilotSettings copilotEnabled: true.
		CopilotSettings copilotProvider: #ollama.
		CopilotSettings modelName: 'codellama:7b'.
		CopilotSettings fimTemplate: '<PRE>%1<SUF>%2<MID>'.
		
		"3. Create components with new settings"
		client := OllamaClient new.
		template := CopilotSettings fimTemplate format: { 'prefix'. 'suffix' }.
		
		"4. Verify settings are applied"
		self assert: CopilotSettings copilotEnabled.
		self assert: (client instVarNamed: 'modelSpec') fullName equals: 'codellama:7b'.
		self assert: template equals: '<PRE>prefix<SUF>suffix<MID>'
	] ensure: [
		"5. Restore original settings"
		originalSettings keysAndValuesDo: [ :key :value |
			key = #enabled ifTrue: [ CopilotSettings copilotEnabled: value ].
			key = #provider ifTrue: [ CopilotSettings copilotProvider: value ].
			key = #model ifTrue: [ CopilotSettings modelName: value ].
			key = #template ifTrue: [ CopilotSettings fimTemplate: value ] ] ]
]
