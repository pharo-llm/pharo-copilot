Class {
	#name : 'CoPharoCopilot',
	#superclass : 'CoCompletionEngine',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'accessing' }
CoPharoCopilot >> completionBuilder [
    ^ completionBuilder ifNil: [ completionBuilder := CoCopilotResultSetBuilder new ]
]
