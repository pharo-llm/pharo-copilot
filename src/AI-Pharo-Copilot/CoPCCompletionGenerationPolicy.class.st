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

	"A textual route cannot predict the length of a complete Smalltalk expression.
	Respect the configured budget, including for a partial variable or selector;
	the model's FIM stop tokens can still end a short completion immediately."
	^ CopilotSettings numPredict
]
