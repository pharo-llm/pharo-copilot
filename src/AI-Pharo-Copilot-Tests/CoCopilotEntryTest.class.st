Class {
	#name : 'CoCopilotEntryTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoCopilotEntryTest >> testActivateOnCollapsesSelectionAtEndOfInsertedText [

    | entry context editor suggestion |
    suggestion := 'foo'.
    editor := CoCopilotMockEditor new.
    editor startIndex: 5.
    context := CoCopilotEditorOnlyContext new
        editor: editor;
        yourself.
    entry := CoCopilotEntry contents: suggestion.

    entry activateOn: context.

    self assert: editor insertedText equals: suggestion.
    self assert: editor selectionIsCollapsed.
    self assert: editor startIndex equals: 5 + suggestion size
]

{ #category : 'tests' }
CoCopilotEntryTest >> testActivateOnPrefersTokenReplacementWhenEditorIsAvailable [

    | entry context editor suggestion |
    suggestion := 'assert:'.
    editor := CoCopilotMockEditor new.
    context := CoCopilotContextMock new
        editor: editor;
        yourself.
    entry := CoCopilotEntry contents: suggestion.

    entry activateOn: context.

    self assert: context lastReplacement equals: suggestion.
    self assert: editor insertedText equals: ''
]

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
CoCopilotEntryTest >> testDisplayStringReturnsFullTextWhenShort [

    | text entry |
    text := 'hello world'.
    entry := CoCopilotEntry contents: text.
    self assert: entry displayString equals: text.
]

{ #category : 'tests' }
CoCopilotEntryTest >> testTextSetterUpdatesContents [

    | entry |
    entry := CoCopilotEntry new.
    entry text: 'bar'.
    self assert: entry contents equals: 'bar'.
]
