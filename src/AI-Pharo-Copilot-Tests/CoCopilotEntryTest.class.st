Class {
	#name : 'CoCopilotEntryTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
CoCopilotEntryTest >> testDisplayStringReturnsFullTextWhenShort [

    | text entry |
    text := 'hello world'.
    entry := CoCopilotEntry contents: text.
    self assert: entry displayString equals: text.
]

{ #category : 'tests' }
CoCopilotEntryTest >> testDisplayStringTruncatesLongText [

    | longText entry |
    longText := String new: 130 withAll: $a.
    entry := CoCopilotEntry contents: longText.
    self assert: entry displayString equals: (longText copyFrom: 1 to: 117), '…'.
]
