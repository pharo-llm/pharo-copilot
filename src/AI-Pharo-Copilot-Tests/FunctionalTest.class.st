Class {
	#name : 'FunctionalTest',
	#superclass : 'CopilotMockModelTestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
FunctionalTest >> testCompleteWorkflowWithMockedClient [
	"Test the complete workflow from context to suggestion activation"
	| context engine builder entry testContext |
	
	"1. Create context"
	context := CoPCContext new.
	context source: 'myMethod: arg | result | result := arg * 2. '.
	context position: context source size.
	
	"2. Get engine and builder"
	engine := CoPharoCopilotCompletionEngine new.
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
FunctionalTest >> testEvaluationWorkflowWithReports [

	| evaluator context entry report |
	evaluator := CoPCSuggestionEvaluator new.
	context := CoPCContext new.
	context source: 'Class { #name : ''TestClass'' }'.
	entry := CoCopilotEntry contents: 'good suggestion'.
	evaluator recordSuggestionAccepted: entry context: context.

	entry := CoCopilotEntry contents: 'bad suggestion'.
        evaluator recordSuggestionRejected: entry context: context reason: 'Incorrect'.
	report := evaluator generateReport.
	self assert: evaluator acceptanceRate equals: 50.
	self assert: (report includesSubstring: 'Total suggestions: 2').
	self assert: (report includesSubstring: 'classDef')
]

{ #category : 'tests' }
FunctionalTest >> testModelManagementWorkflow [
	"Test model selection and usage workflow"
	| oldModel registry client spec |
	oldModel := CopilotSettings modelName.
	
	[
		"1. Get available models"
		registry := CoPCModelRegistry current.
		
		"2. Select a model"
		spec := registry allSpecs first.
		CopilotSettings modelName: spec fullName.
		
		"3. Create client with selected model"
		client := CoPCOllamaClient new.
		
		"4. Verify model is used"
		self assert: (client instVarNamed: 'modelSpec') fullName equals: spec fullName
	] ensure: [ CopilotSettings modelName: oldModel ]
]
