Class {
	#name : 'CoCopilotEntryTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoCopilotEntryTest >> testActivateOnReplacesToken [
    | entry context |
    entry := CoCopilotEntry contents: 'foo'.
    context := CoCopilotEntryTestContext new.
    entry activateOn: context.
    self assert: context replacedToken equals: 'foo'.
]

{ #category : 'tests' }
CoCopilotEntryTest >> testContentsAccessor [
    | entry |
    entry := CoCopilotEntry contents: 'foo'.
    self assert: entry contents equals: 'foo'.
]

{ #category : 'tests' }
CoCopilotEntryTest >> testDisplayStringExactly120Characters [

	| text entry |
	text := String new: 120 withAll: $a.
	entry := CoCopilotEntry contents: text.
	self assert: entry displayString equals: text
]

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

{ #category : 'tests' }
CoCopilotEntryTest >> testTextSetterUpdatesContents [

    | entry |
    entry := CoCopilotEntry new.
    entry text: 'bar'.
    self assert: entry contents equals: 'bar'.
]
