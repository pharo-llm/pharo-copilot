Extension { #name : 'WorldState' }

{ #category : '*AI-Pharo-Copilot' }
WorldState class >> quitSession [

	| response |
	response := MorphicUIManager new
		confirm: 'Save changes before quitting?'
		trueChoice: 'Save'
		falseChoice: 'Discard'
		cancelChoice: 'Cancel'
		default: nil.

	response ifNil: [ ^ self ].

	CoPCImageCloseSurvey promptBeforeImageQuit.
	response
		ifTrue: [ Smalltalk snapshot: true andQuit: true ]
		ifFalse: [ Smalltalk snapshot: false andQuit: true ]
]

{ #category : '*AI-Pharo-Copilot' }
WorldState class >> saveAndQuit [

	CoPCImageCloseSurvey promptBeforeImageQuit.
	Cursor write showWhile: [
		Smalltalk snapshot: true andQuit: true ]
]
