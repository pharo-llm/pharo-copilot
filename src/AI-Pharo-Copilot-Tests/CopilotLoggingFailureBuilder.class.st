Class {
	#name : 'CopilotLoggingFailureBuilder',
	#superclass : 'CoPharoCopilotResultSetBuilder',
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'logging' }
CopilotLoggingFailureBuilder >> completionTypeInfoForSuggestion: suggestionString prefix: prefixString suffix: suffixString contextInfo: contextInfo [

	self error: 'forced logging metadata failure'
]
