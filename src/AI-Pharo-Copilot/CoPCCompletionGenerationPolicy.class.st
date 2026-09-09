"
Chooses request-local model generation budgets for different completion routes.
"
Class {
	#name : 'CoPCCompletionGenerationPolicy',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'generation' }
CoPCCompletionGenerationPolicy >> numPredictFor: completionRoute [

	"selector routes cover partial message sends (e.g. `self ass`) and need
	 enough room to finish an entire Smalltalk send such as `self assert: ...`.
	 messageTail is kept for forward-compatibility but routes the same budget."
	completionRoute = #selector ifTrue: [ ^ 32 ].
	completionRoute = #messageTail ifTrue: [ ^ 32 ].
	completionRoute = #variable ifTrue: [ ^ 8 ].
	completionRoute = #statement ifTrue: [ ^ 24 ].
	^ 24
]
