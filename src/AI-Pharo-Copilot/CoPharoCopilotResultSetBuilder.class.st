Class {
	#name : 'CoPharoCopilotResultSetBuilder',
	#superclass : 'CoResultSetBuilder',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'instance creation' }
CoPharoCopilotResultSetBuilder class >> initializeOnContext: aSystemCompletionContext [ 
    ^ self new
        initializeOnContext: aSystemCompletionContext;
        yourself
]

{ #category : 'API - building' }
CoPharoCopilotResultSetBuilder >> buildCompletion [

	| textUpToCaret response suggestions completion api |
	textUpToCaret := completionContext source
		                 copyFrom: 1
		                 to: completionContext position.
	api := OllamaAPI new.
	response := api query: textUpToCaret.
	suggestions := OrderedCollection new.
	(response at: #content ifAbsent: [ '' ]) ifNotEmpty: [ :someText |
		suggestions add: someText ].

	completion := CoCompletionEngine new.
	completion items: suggestions.
	^ completion
]

{ #category : 'initialization' }
CoPharoCopilotResultSetBuilder >> initializeOnContext: aSystemCompletionContext [ 
    "Store the passed-in context so we can access source, position, etc."
    completionContext := aSystemCompletionContext
]
