Class {
	#name : 'DataIntegrityTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
DataIntegrityTest >> testEvaluationEntryConsistency [
	| entry context suggestion timestamp |
	entry := CoEvaluationEntry new.
	context := CoPharoCopilotContext new.
	suggestion := CoCopilotEntry contents: 'test'.
	timestamp := DateAndTime now.
	
	"Set all properties"
	entry context: context.
	entry suggestion: suggestion.
	entry timestamp: timestamp.
	entry action: #accepted.
	entry rejectionReason: 'N/A'.
	
	"Verify all are preserved"
	self assert: entry context identicalTo: context.
	self assert: entry suggestion identicalTo: suggestion.
	self assert: entry timestamp identicalTo: timestamp.
	self assert: entry action equals: #accepted.
	self assert: entry rejectionReason equals: 'N/A'
]

{ #category : 'tests' }
DataIntegrityTest >> testModelSpecImmutability [
	| spec1 spec2 |
	spec1 := OModelSpec family: 'test' tag: 'v1' label: 'Test V1'.
	spec2 := OModelSpec family: 'test' tag: 'v1' label: 'Test V1'.
	
	"Different instances with same data should be equal in content"
	self assert: spec1 fullName equals: spec2 fullName.
	self assert: spec1 family equals: spec2 family.
	self assert: spec1 tag equals: spec2 tag.
	self assert: spec1 label equals: spec2 label
]

{ #category : 'tests' }
DataIntegrityTest >> testRegistryConsistency [
	| registry spec |
	registry := OModelRegistry build.
	
	"Test bi-directional lookup consistency"
	registry byFullName keysAndValuesDo: [ :fullName :spec |
		self assert: spec fullName equals: fullName.
		self assert: (registry specByFullName: fullName) identicalTo: spec ].
		
	registry byLabel keysAndValuesDo: [ :label :spec |
		self assert: spec label equals: label.
		self assert: (registry specByLabel: label) identicalTo: spec ]
]

{ #category : 'tests' }
DataIntegrityTest >> testSessionStatsConsistency [
	| evaluator context stats calculatedRate |
	evaluator := CoSuggestionEvaluator new.
	context := CoPharoCopilotContext new.
	
	"Add some entries"
	5 timesRepeat: [
		evaluator recordSuggestionAccepted: (CoCopilotEntry contents: 'accepted') context: context ].
	3 timesRepeat: [
		evaluator recordSuggestionIgnored: (CoCopilotEntry contents: 'ignored') context: context ].
	
	stats := evaluator sessionStats.
	
	"Verify totals match collections"
	self assert: (stats at: #totalSuggestions) equals: 8.
	self assert: (stats at: #totalAccepted) equals: evaluator acceptedEntries size.
	self assert: evaluator acceptedEntries size equals: 5.
	
	"Verify rates are consistent"
	calculatedRate := (evaluator acceptedEntries size / 8.0 * 100) rounded.
	self assert: evaluator acceptanceRate equals: calculatedRate
]

{ #category : 'tests' }
DataIntegrityTest >> testSettingsStateConsistency [

	| originalStates originalTemplate |
	originalStates := Dictionary new
		                  at: #enabled put: CopilotSettings copilotEnabled;
		                  at: #provider put: CopilotSettings copilotProvider;
		                  at: #model put: CopilotSettings modelName;
		                  at: #host put: CopilotSettings host;
		                  at: #port put: CopilotSettings port;
		                  yourself.
	originalTemplate := CopilotSettings fimTemplate.
	[ "Modify all settings"
		CopilotSettings copilotEnabled: (originalStates at: #enabled) not.
		CopilotSettings copilotProvider: #modified.
		CopilotSettings modelName: 'modified:model'.
		CopilotSettings host: 'modified.host'.
		CopilotSettings port: (originalStates at: #port) + 1. "Verify changes took effect"
		self assert: CopilotSettings copilotEnabled equals: (originalStates at: #enabled) not.
		self assert: CopilotSettings copilotProvider equals: #modified.
		self assert: CopilotSettings modelName equals: 'modified:model'.
		CopilotSettings fimTemplate: 'MODIFIED%1%2'.
		self assert: CopilotSettings fimTemplate equals: originalTemplate.
		self assert: CopilotSettings host equals: 'modified.host'.
		self assert: CopilotSettings port equals: (originalStates at: #port) + 1 ] ensure: [ "Restore original states"
			CopilotSettings copilotEnabled: (originalStates at: #enabled).
			CopilotSettings copilotProvider: (originalStates at: #provider).
			CopilotSettings modelName: (originalStates at: #model).
			CopilotSettings host: (originalStates at: #host).
			CopilotSettings port: (originalStates at: #port) ]
]
