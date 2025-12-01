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
FunctionalTest >> testEvaluationWorkflowWithReports [
        "Test complete evaluation workflow"
        | evaluator context entry report |

        "1. Setup evaluator"
        evaluator := CoSuggestionEvaluator new.
        context := CoPharoCopilotContext new.
        context source: 'Class { #name : ''TestClass'' }'.

        "2. Record various suggestions"
        entry := CoCopilotEntry contents: 'good suggestion'.
        evaluator recordSuggestionAccepted: entry context: context.

        entry := CoCopilotEntry contents: 'ignored suggestion'.
        evaluator recordSuggestionIgnored: entry context: context.

        "3. Generate report"
        report := evaluator generateReport.

        "4. Verify workflow results"
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
