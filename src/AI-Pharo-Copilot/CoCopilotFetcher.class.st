Class {
	#name : 'CoCopilotFetcher',
	#superclass : 'CoFetcher',
	#instVars : [
		'context',
		'suggestions'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'accessing' }
CoCopilotFetcher >> context [ 

    ^ context
]

{ #category : 'accessing' }
CoCopilotFetcher >> context: aContext [
    context := aContext
]

{ #category : 'enumerating' }
CoCopilotFetcher >> entriesDo: aBlock [ 

    suggestions ifNil: [ suggestions := self generateSuggestions ].
    suggestions do: [ :each | aBlock value: (NECEntry contents: each node: nil) ]
]

{ #category : 'accessing' }
CoCopilotFetcher >> generateSuggestions [ 

    | agent prompt response |
    context ifNil: [ ^ #() ].
    agent := ChatPharoSettings default agent.
    (agent isNil or: [ agent isConfigured not ]) ifTrue: [ ^ #() ].
    prompt := String streamContents: [ :s |
        s nextPutAll: 'Complete the following Smalltalk code:\n'.
        s nextPutAll: (context source copyFrom: 1 to: context position) ].
    [ response := agent getResponseForPrompt: prompt ] on: Error do: [ ^ #() ].
    ^ response lines collect: [ :each | each trimBoth ]
]
