Class {
	#name : 'ErrorHandlingTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
ErrorHandlingTest >> testCleanedContentFromWithCorruptedData [
	| builder corruptedInputs |
	builder := CoPharoCopilotResultSetBuilder new.
	
	corruptedInputs := {
		nil.
		''.
		Character null asString.
		String new: 10 withAll: Character null.
		(String with: Character cr with: Character null with: Character lf)
	}.
	
	corruptedInputs do: [ :input |
		self shouldnt: [ builder cleanedContentFrom: input ] raise: Error ]
]

{ #category : 'tests' }
ErrorHandlingTest >> testEntryActivationWithNilContext [
	| entry |
	entry := CoCopilotEntry contents: 'test'.
	
	"Should handle nil context gracefully"
	self should: [ entry activateOn: nil ] raise: Error
]

{ #category : 'tests' }
ErrorHandlingTest >> testEvaluatorWithCorruptedStats [
	| evaluator |
	evaluator := CoSuggestionEvaluator new.
	
	"Corrupt the stats dictionary"
	evaluator sessionStats removeKey: #totalSuggestions ifAbsent: [].
	
	"Should handle missing keys gracefully"
	self shouldnt: [ evaluator acceptanceRate ] raise: Error
]

{ #category : 'tests' }
ErrorHandlingTest >> testHttpTransportWithInvalidData [
	| transport |
	transport := OAHttpTransport new.
	
	"Test with invalid host/port"
	transport host: nil.
	transport port: -1.
	
	"Should not crash immediately"
	self assert: transport host isNil.
	self assert: transport port equals: -1
]

{ #category : 'tests' }
ErrorHandlingTest >> testModelSpecWithNilValues [
	| spec |
	
	"Should handle nil values gracefully"
	self shouldnt: [ spec := OModelSpec family: nil tag: nil label: nil ] raise: Error.
	
	spec ifNotNil: [
		self shouldnt: [ spec fullName ] raise: Error.
		self shouldnt: [ spec family ] raise: Error ]
]

{ #category : 'tests' }
ErrorHandlingTest >> testOllamaClientWithBrokenTransport [
	| client brokenTransport |
	client := OllamaClient new.
	brokenTransport := OAHttpTransportMockExtended new.
	brokenTransport configureToThrowError.
	client instVarNamed: 'transport' put: brokenTransport.
	
	"Should propagate transport errors"
	self should: [ client generate: 'test' ] raise: Error.
	self should: [ client listModels ] raise: Error
]

{ #category : 'tests' }
ErrorHandlingTest >> testRegistryRebuildWithMissingClasses [
	| registry |
	registry := OModelRegistry new.
	
	"Should handle rebuild even if some classes are missing"
	self shouldnt: [ registry rebuild ] raise: Error.
	self assert: ((registry byFullName) isKindOf: Dictionary).
	self assert: ((registry byLabel) isKindOf: Dictionary)
]
