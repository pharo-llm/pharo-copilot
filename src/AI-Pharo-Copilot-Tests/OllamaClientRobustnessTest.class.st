Class {
	#name : 'OllamaClientRobustnessTest',
	#superclass : 'CopilotMockModelTestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

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
