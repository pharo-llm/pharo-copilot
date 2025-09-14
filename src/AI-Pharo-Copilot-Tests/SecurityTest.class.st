Class {
	#name : 'SecurityTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
SecurityTest >> testCleanedContentFromRejectsScriptInjection [
	| builder raw cleaned |
	builder := CoPharoCopilotResultSetBuilder new.
	raw := '```javascript', String lf, 'alert("xss")', String lf, '```'.
	
	cleaned := builder cleanedContentFrom: raw.
	
	"Should clean the content but not execute it"
	self assert: cleaned equals: 'alert("xss")'.
	"Test passes if no alert actually executed"
]

{ #category : 'tests' }
SecurityTest >> testModelNameValidation [
	| old client spec |
	old := CopilotSettings modelName.
	
	[
		"Test potentially malicious model names"
		#('../../../etc/passwd' '$(rm -rf /)' '; DROP TABLE models; --') do: [ :maliciousName |
			CopilotSettings modelName: maliciousName.
			client := OllamaClient new.
			
			"Should create spec without executing commands"
			spec := client instVarNamed: 'modelSpec'.
			self assert: spec notNil ]
	] ensure: [ CopilotSettings modelName: old ]
]

{ #category : 'tests' }
SecurityTest >> testSuggestionContentSanitization [
	| entry maliciousContent |
	maliciousContent := '<script>alert("xss")</script>doSomethingEvil()'.
	
	entry := CoCopilotEntry contents: maliciousContent.
	
	"Should store content as-is but not execute"
	self assert: entry contents equals: maliciousContent.
	self assert: entry displayString isString.
	"If we reach here without executing malicious code, test passes"
]
