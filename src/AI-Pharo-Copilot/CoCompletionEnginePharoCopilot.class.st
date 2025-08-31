"
Completion engine that retrieves suggestions from the Pharo Copilot service.

"
Class {
	#name : 'CoCompletionEnginePharoCopilot',
	#superclass : 'CoCompletionEngine',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'accessing' }
CoCompletionEnginePharoCopilot >> completionBuilder [
    ^ completionBuilder ifNil: [ completionBuilder := CoPharoCopilotResultSetBuilder new ]
]
