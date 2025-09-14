Class {
	#name : 'OllamaClientRobustnessTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
OllamaClientRobustnessTest >> testGenerateForPrefixSuffixWithEmptyInputs [
		| client mock payload expected |
		client := OllamaClient new.
		mock := OAHttpTransportMock new.
		client instVarNamed: 'transport' put: mock.

		client generateForPrefix: '' suffix: ''.

		payload := mock lastBody.
		expected := CopilotSettings fimTemplate format: { ''. '' }.
		self assert: (payload at: #prompt) equals: expected
]

{ #category : 'tests' }
OllamaClientRobustnessTest >> testGenerateForPrefixSuffixWithLargeInputs [
	| client mock largePrefix largeSuffix payload |
	client := OllamaClient new.
	mock := OAHttpTransportMock new.
	client instVarNamed: 'transport' put: mock.
	
	largePrefix := String new: 5000 withAll: $a.
	largeSuffix := String new: 5000 withAll: $b.
	
	client generateForPrefix: largePrefix suffix: largeSuffix.
	
	payload := mock lastBody.
	self assert: (payload at: #prompt) size > 10000
]

{ #category : 'tests' }
OllamaClientRobustnessTest >> testGenerateForPrefixSuffixWithNilInputs [
	| client mock |
	client := OllamaClient new.
	mock := OAHttpTransportMock new.
	client instVarNamed: 'transport' put: mock.
	
	"Test with nil inputs - should not crash"
	self shouldnt: [ client generateForPrefix: nil suffix: nil ] raise: Error
]

{ #category : 'tests' }
OllamaClientRobustnessTest >> testGenerateForPrefixSuffixWithSpecialCharacters [
	| client mock prefix suffix payload |
	client := OllamaClient new.
	mock := OAHttpTransportMock new.
	client instVarNamed: 'transport' put: mock.
	
	prefix := 'äöüß €£¥ 🚀'.
	suffix := '∑∏∆√ ♠♥♦♣'.
	
	client generateForPrefix: prefix suffix: suffix.

	payload := mock lastBody.
	self assert: ((payload at: #prompt) includesSubstring: prefix).
	self assert: ((payload at: #prompt) includesSubstring: suffix)
]

{ #category : 'tests' }
OllamaClientRobustnessTest >> testNormalizeResponseWithCorruptedJsonStructures [
	| client testCases |
	client := OllamaClient new.
	
	testCases := {
		'{"response":}' -> '{"response":}'.
		'{"response":"incomplete' -> '{"response":"incomplete'.
		'{response: "no quotes"}' -> '{response: "no quotes"}'.
		'{"response":null}' -> 'null'.
		'{"response":{"nested":"object"}}' -> '{"nested":"object"}'
	}.
	
	testCases do: [ :case |
		| result |
		result := client normalizeResponse: case key.
		"Should not crash and return some reasonable value"
		self assert: result isString ]

]

{ #category : 'tests' }
OllamaClientRobustnessTest >> testNormalizeResponseWithDeeplyNestedJson [
	| client deepJson result |
	client := OllamaClient new.
	deepJson := '{"level1":{"level2":{"level3":{"response":"deep value"}}}}'.
	
	result := client normalizeResponse: deepJson.
	self assert: result equals: deepJson
]

{ #category : 'tests' }
OllamaClientRobustnessTest >> testNormalizeResponseWithLargeJsonResponse [
	| client largeContent jsonString result |
	client := OllamaClient new.
	largeContent := String new: 10000 withAll: $x.
	jsonString := '{"response":"', largeContent, '","done":true}'.
	
	result := client normalizeResponse: jsonString.
	self assert: result equals: largeContent
]

{ #category : 'tests' }
OllamaClientRobustnessTest >> testUseModelNamedWithInvalidCharacters [
	| client spec |
	client := OllamaClient new.
	client useModelNamed: 'invalid/model:name'.
	
	spec := client instVarNamed: 'modelSpec'.
	self assert: spec family equals: 'invalid/model'.
	self assert: spec tag equals: 'name'
]

{ #category : 'tests' }
OllamaClientRobustnessTest >> testUseModelNamedWithMultipleColons [
	| client spec |
	client := OllamaClient new.
	client useModelNamed: 'family:tag:extra:parts'.
	
	spec := client instVarNamed: 'modelSpec'.
	self assert: spec family equals: 'family'.
	self assert: spec tag equals: 'tag:extra:parts'
]
