Class {
	#name : 'CoPharoCopilotResultSetBuilderStressTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderStressTest >> testCleanedContentFromWithDeeplyNestedCodeBlocks [ 
	| builder raw cleaned |
	builder := CoPharoCopilotResultSetBuilder new.
	raw := '```outer', String lf, 'start', String lf, '```inner', String lf, 'nested', String lf, '```', String lf, 'end', String lf, '```'.
	cleaned := builder cleanedContentFrom: raw.
	
	"Should extract from first complete block"
	self assert: cleaned equals: 'start', String lf, '```inner', String lf, 'nested', String lf, '```', String lf, 'end'

]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderStressTest >> testCleanedContentFromWithGiantString [
	| builder largeString cleaned |
	builder := CoPharoCopilotResultSetBuilder new.
	largeString := String new: 10000 withAll: $a.
	
	cleaned := builder cleanedContentFrom: largeString.
	self assert: cleaned equals: largeString
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderStressTest >> testCleanedContentFromWithManyLanguageSpecs [
	| builder languages |
	builder := CoPharoCopilotResultSetBuilder new.
	
	languages := #('smalltalk' 'pharo' 'javascript' 'python' 'java' 'c' 'cpp' 'ruby' 'go' 'rust').
	
	languages do: [ :lang |
		| raw cleaned |
		raw := '```', lang, String lf, 'code here', String lf, '```'.
		cleaned := builder cleanedContentFrom: raw.
		self assert: cleaned equals: 'code here' ]

]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderStressTest >> testCleanedContentFromWithSpecialCharacters [
	| builder raw cleaned |
	builder := CoPharoCopilotResultSetBuilder new.
	raw := '```smalltalk', String lf, 'äöüß €£¥', String lf, '∑∏∆√', String lf, '```'.
	cleaned := builder cleanedContentFrom: raw.
	
	self assert: cleaned equals: 'äöüß €£¥', String lf, '∑∏∆√'
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderStressTest >> testIsLanguageSpecWithCaseVariations [
	| builder |
	builder := CoPharoCopilotResultSetBuilder new.
	
	#('SMALLTALK' 'SmallTalk' 'smallTALK' 'SmaLLTalk') do: [ :variant |
		self assert: (builder isLanguageSpec: variant) ]
]

{ #category : 'tests' }
CoPharoCopilotResultSetBuilderStressTest >> testIsLanguageSpecWithWhitespace [
	| builder |
	builder := CoPharoCopilotResultSetBuilder new.
	
	self deny: (builder isLanguageSpec: ' smalltalk ').
	self deny: (builder isLanguageSpec: 'smalltalk ').
	self deny: (builder isLanguageSpec: ' smalltalk')
]
