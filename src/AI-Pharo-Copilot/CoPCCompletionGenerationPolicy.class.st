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

	"Keep ordinary single-token completion extremely cheap. Message tails need
	 enough room to finish an entire Smalltalk send such as `self assert: ...`."
	completionRoute = #selector ifTrue: [ ^ 8 ].
	completionRoute = #messageTail ifTrue: [ ^ 32 ].
	completionRoute = #variable ifTrue: [ ^ 8 ].
	completionRoute = #statement ifTrue: [ ^ 24 ].
	^ 24
]
