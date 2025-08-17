Class {
	#name : 'CoCompletionEnignePharoCopilot',
	#superclass : 'CoCompletionEngine',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'accessing' }
CoCompletionEnignePharoCopilot >> completionBuilder [
    ^ completionBuilder ifNil: [ completionBuilder := CoPharoCopilotResultSetBuilder new ]
]
