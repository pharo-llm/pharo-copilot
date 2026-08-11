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

	(completionRoute = #selector or: [ completionRoute = #messageTail ]) ifTrue: [
		^ 8 ].
	completionRoute = #variable ifTrue: [ ^ 8 ].
	completionRoute = #statement ifTrue: [ ^ 24 ].
	^ 24
]
