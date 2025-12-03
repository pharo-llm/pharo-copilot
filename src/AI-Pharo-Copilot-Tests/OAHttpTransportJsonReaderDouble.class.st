Class {
	#name : 'OAHttpTransportJsonReaderDouble',
	#superclass : 'Object',
	#instVars : [
		'lastString',
		'lastResult'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'instance creation' }
OAHttpTransportJsonReaderDouble >> fromString: aString [
        lastString := aString asString.
        lastResult := Dictionary newFromPairs: { 'decoded'. lastString }.
        ^ lastResult
]

{ #category : 'accessing' }
OAHttpTransportJsonReaderDouble >> lastResult [

	^ lastResult
]

{ #category : 'accessing' }
OAHttpTransportJsonReaderDouble >> lastString [

	^ lastString
]
