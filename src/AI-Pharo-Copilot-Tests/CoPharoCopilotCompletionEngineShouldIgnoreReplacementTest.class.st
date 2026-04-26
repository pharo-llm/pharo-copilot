Class {
	#name : 'CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldIgnoreNil [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine shouldIgnoreReplacement: nil)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldIgnoreEmptyString [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine shouldIgnoreReplacement: '')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldIgnoreEmptyStringViaNewString [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine shouldIgnoreReplacement: String new)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldIgnoreEmptyStringViaCopy [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine shouldIgnoreReplacement: '' copy)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldIgnoreEmptyStringViaConcatenation [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine shouldIgnoreReplacement: '', '')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldIgnoreEmptyStringAsSymbolEmpty [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine shouldIgnoreReplacement: '' asSymbol)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldIgnoreEmptyStreamContents [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self assert: (engine shouldIgnoreReplacement: (String streamContents: [ :s | ]))
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreSingleLetter [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'a')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreSingleDigit [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '1')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreSingleSpace [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: ' ')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreSingleTab [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: String tab)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreSingleNewline [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: String lf)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreSingleCarriageReturn [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: String cr)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreCrLf [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: String crlf)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreTwoSpaces [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '  ')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreWord [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'hello')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreSentence [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'hello world')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreNumber [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '42')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreKeyword [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'foo: ')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreBinaryOp [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '+ ')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreExpression [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'self yourself')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreAssignmentSyntax [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'x := 1')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreKeywordSelector [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'self assert: x equals: y')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreUnicode [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'caf' , (String with: (Character value: 233)))
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreUnicodeEmoji [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: (String with: (Character value: 128512)))
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreMultilineMessage [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'line1' , String lf , 'line2')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreIndentedMessage [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '    indented')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreTrailingSpace [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'value ')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreLeadingSpace [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: ' value')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnorePunctuationOnly [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '.;,:')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreSmalltalkReturnArrow [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '^ nil')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreLongString [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: (String new: 10000 withAll: $a))
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreVeryLongString [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: (String new: 50000 withAll: $x))
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreContainsNullChar [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: (String with: Character null))
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreStringWithSingleQuote [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '''')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreStringWithDoubleQuote [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '"')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreStringWithBackslash [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '\')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreStringWithForwardSlash [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '/')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreStringWithHash [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '#')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreStringWithDollar [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '$')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreStringWithPipe [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '|')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreStringWithBang [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '!')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreStringWithAmpersand [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '&')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreStringWithQuestionMark [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '?')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreOnlyNewlines [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: String lf , String lf , String lf)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreOnlyTabs [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: String tab , String tab)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreOnlySpaces [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '     ')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreMixedWhitespace [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: ' ' , String tab , String lf)
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreArrayLiteralSource [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '#(1 2 3)')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreBlockLiteralSource [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '[ :x | x + 1 ]')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreByteArrayLiteralSource [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '#[1 2 3]')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreClassDefinitionSnippet [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'Object subclass: #Foo')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreCascadeSnippet [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'self x; y; z')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreReturnExpression [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '^ self')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreSingleHyphen [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '-')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreSingleEquals [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '=')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreNumericDecimal [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '3.14')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreNegativeNumber [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '-5')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreLargeNumber [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: '1000000')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreBooleanTrue [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'true')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreBooleanFalse [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'false')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreNilLiteral [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'nil')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreSelfKeyword [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'self')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreSuperKeyword [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'super')
]

{ #category : 'tests' }
CoPharoCopilotCompletionEngineShouldIgnoreReplacementTest >> testShouldNotIgnoreThisContextKeyword [
	| engine |
	engine := CoPharoCopilotCompletionEngine new.
	self deny: (engine shouldIgnoreReplacement: 'thisContext')
]
