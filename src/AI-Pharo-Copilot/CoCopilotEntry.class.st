"
Represents a single completion suggestion returned by Pharo Copilot.
"
Class {
	#name : 'CoCopilotEntry',
	#superclass : 'Object',
	#instVars : [
		'text'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'accessing' }
CoCopilotEntry class >> contents: aString [

  ^ self new text: aString; yourself.
]

{ #category : 'accessing' }
CoCopilotEntry >> activateOn: aCoCompletionContext [

	aCoCompletionContext replaceTokenInEditorWith: text.
]

{ #category : 'accessing' }
CoCopilotEntry >> contents [
  ^ text
]

{ #category : 'displaying' }
CoCopilotEntry >> displayString [

  ^ text size > 120
    ifTrue: [ (text copyFrom: 1 to: 117), '…' ]
    ifFalse: [ text ]
]

{ #category : 'accessing' }
CoCopilotEntry >> text: aString [
  text := aString
]
