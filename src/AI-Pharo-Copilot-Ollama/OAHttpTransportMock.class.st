Class {
	#name : 'OAHttpTransportMock',
	#superclass : 'Object',
	#instVars : [
		'lastPath',
		'lastBody'
	],
	#category : 'AI-Pharo-Copilot-Ollama',
	#package : 'AI-Pharo-Copilot-Ollama'
}

{ #category : 'accessing' }
OAHttpTransportMock >> lastBody [
    ^ lastBody
]

{ #category : 'accessing' }
OAHttpTransportMock >> lastPath [
    ^ lastPath
]

{ #category : 'accessing' }
OAHttpTransportMock >> postJsonAt: aPath body: aDictionary [
    lastPath := aPath.
    lastBody := aDictionary.
    ^ Dictionary new
]
