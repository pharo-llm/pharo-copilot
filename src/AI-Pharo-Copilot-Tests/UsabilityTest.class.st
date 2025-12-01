Class {
	#name : 'UsabilityTest',
	#superclass : 'CopilotMockModelTestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
UsabilityTest >> testAvailableModelNamesAreUserFriendly [
        | modelNames |
        modelNames := CopilotSettings availableModelNames.

        modelNames do: [ :assoc |
                "Keys should be human-readable labels"
                self assert: assoc key isString.
                self deny: assoc key isEmpty.
                "Values should be valid model identifiers"
                self assert: assoc value isString.
                self deny: assoc value isEmpty.
                "Labels should be more readable than identifiers"
                self deny: assoc key equals: assoc value ]
]

{ #category : 'tests' }
UsabilityTest >> testContextBuilderIntuitiveAPI [
	| context |
	context := CoPharoCopilotContext new.
	
	"Should have sensible defaults"
	self assert: context completionBuilder notNil.
	self assert: context completionBuilder class equals: CoPharoCopilotResultSetBuilder
]

{ #category : 'tests' }
UsabilityTest >> testEngineBuilderMemoizationIsTransparent [
	| engine builder1 builder2 |
	engine := CoCompletionEnginePharoCopilot new.
	
	builder1 := engine completionBuilder.
	builder2 := engine completionBuilder.
	
	"Memoization should be transparent to users"
	self assert: builder1 notNil.
	self assert: builder2 notNil.
	self assert: builder1 identicalTo: builder2
]

{ #category : 'tests' }
UsabilityTest >> testEntryDisplayStringIsInformative [
	| shortEntry longEntry |
	shortEntry := CoCopilotEntry contents: 'def method'.
	longEntry := CoCopilotEntry contents: (String new: 200 withAll: $x).
	
	"Short content should be shown completely"
	self assert: shortEntry displayString equals: 'def method'.
	
	"Long content should be truncated with indicator"
	self assert: longEntry displayString size < 200.
	self assert: (longEntry displayString endsWith: '…')
]

{ #category : 'tests' }
UsabilityTest >> testEvaluatorReportIsReadable [
	| evaluator context report |
	evaluator := CoSuggestionEvaluator new.
	context := CoPharoCopilotContext new.
	
	"Add sample data"
	evaluator recordSuggestionAccepted: (CoCopilotEntry contents: 'accepted') context: context.
	
	report := evaluator generateReport.
	
	"Report should contain user-friendly sections"
	#('OVERVIEW' 'MODEL PERFORMANCE' 'CONTEXT ANALYSIS' 'RECOMMENDATIONS') do: [ :section |
		self assert: (report includesSubstring: section) ]
]

{ #category : 'tests' }
UsabilityTest >> testModelSpecDisplayIsIntuitive [

	| spec |
	spec := OModelSpec family: 'mock' tag: 'model' label: 'Mock Model Friendly'. "Full name should be technical identifier"
	self assert: spec fullName equals: 'mock:model'. "Label should be human-readable"
	self assert: spec label equals: 'Mock Model Friendly'. "Label should be more descriptive than full name"
	self assert: spec label size > spec fullName size
]
