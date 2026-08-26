Class {
	#name : 'CopilotRecentCodeChangesTestBuilder',
	#superclass : 'CoPharoCopilotResultSetBuilder',
	#instVars : [
		'recentCodeChangesForPrompt',
		'semanticCompletionContextForPrompt',
		'interactionHistoryForPrompt'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
CopilotRecentCodeChangesTestBuilder >> appendInteractionHistoryToContext: contextString [

	interactionHistoryForPrompt ifNil: [
		^ super appendInteractionHistoryToContext: contextString ].

	^ self
		appendInteractionHistory: interactionHistoryForPrompt
		toContext: contextString
]

{ #category : 'accessing' }
CopilotRecentCodeChangesTestBuilder >> interactionHistoryForPrompt: aString [

	interactionHistoryForPrompt := aString
]

{ #category : 'accessing' }
CopilotRecentCodeChangesTestBuilder >> recentCodeChangesForPrompt [

	^ recentCodeChangesForPrompt ifNil: [ '' ]
]

{ #category : 'accessing' }
CopilotRecentCodeChangesTestBuilder >> recentCodeChangesForPrompt: aString [

	recentCodeChangesForPrompt := aString
]

{ #category : 'accessing' }
CopilotRecentCodeChangesTestBuilder >> semanticCompletionContextFor: aContext prefix: prefixString [

	semanticCompletionContextForPrompt ifNil: [
		^ super semanticCompletionContextFor: aContext prefix: prefixString ].

	^ semanticCompletionContextForPrompt
]

{ #category : 'accessing' }
CopilotRecentCodeChangesTestBuilder >> semanticCompletionContextForPrompt: aString [

	semanticCompletionContextForPrompt := aString
]
