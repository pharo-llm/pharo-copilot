Class {
	#name : 'OAHttpTransportJsonWriterDouble',
	#superclass : 'Object',
	#instVars : [
		'lastWrittenObject'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
OAHttpTransportJsonWriterDouble >> lastWrittenObject [
        ^ lastWrittenObject
]

{ #category : 'accessing' }
OAHttpTransportJsonWriterDouble >> toString: anObject [

        lastWrittenObject := anObject.
        ^ 'encoded:' , anObject size asString
]
