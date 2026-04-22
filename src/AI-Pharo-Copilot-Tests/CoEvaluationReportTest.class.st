Class {
	#name : 'CoEvaluationReportTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoEvaluationReportTest >> testGenerateCreatesNonEmptyReport [
	| evaluator report content |
	evaluator := CoPCSuggestionEvaluator new.
	report := CoPCEvaluationReport new evaluator: evaluator; yourself.
	
	content := report generate.
	
	self assert: content isString.
	self deny: content isEmpty.
	self assert: (content includesSubstring: 'Copilot Evaluation Report').
	self assert: (content includesSubstring: 'OVERVIEW').
	self assert: (content includesSubstring: 'Total suggestions: 0')
]

{ #category : 'tests' }
CoEvaluationReportTest >> testGenerateWithSampleData [
    | evaluator report content context entry |
    evaluator := CoPCSuggestionEvaluator new.
    context := CoPCContext new.  "source may be nil; that's fine now"
    entry := CoCopilotEntry contents: 'test code'.

    evaluator recordSuggestionAccepted: entry context: context.

    report := CoPCEvaluationReport new
        evaluator: evaluator;
        yourself.
    content := report generate.

    self assert: (content includesSubstring: 'Total suggestions: 1').
    self assert: (content includesSubstring: 'Accepted: 1').
]
