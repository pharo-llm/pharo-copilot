Class {
	#name : 'CoCopilotResultSetBuilder',
	#superclass : 'CoASTHeuristicsResultSetBuilder',
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'API - building' }
CoCopilotResultSetBuilder >> buildCompletion [ 

    | completion copilot |
    completion := super buildCompletion.
    copilot := CoCopilotFetcher new.
    completion fetcher: (completion fetcher , copilot).
    completion fetcher context: completionContext.
    completion fetcher filter: completion filter.
    ^ completion
]
