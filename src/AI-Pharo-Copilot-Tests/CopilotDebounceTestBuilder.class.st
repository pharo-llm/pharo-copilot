Class {
	#name : 'CopilotDebounceTestBuilder',
	#superclass : 'CoPharoCopilotResultSetBuilder',
	#instVars : [
		'processedPrefix',
		'semaphore'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'initialization' }
CopilotDebounceTestBuilder >> contextInfoFor: aContext prefix: prefix suffix: suffix [

	^ Dictionary new
]

{ #category : 'initialization' }
CopilotDebounceTestBuilder >> deferUI: aBlock [

	^ aBlock value
]

{ #category : 'initialization' }
CopilotDebounceTestBuilder >> initialize [

	super initialize.
	semaphore := Semaphore new.
]

{ #category : 'initialization' }
CopilotDebounceTestBuilder >> processCompletionFor: aContext prefix: prefixString suffix: suffixString contextInfo: contextInf [

	processedPrefix := prefixString.
	semaphore signal
]

{ #category : 'initialization' }
CopilotDebounceTestBuilder >> processedPrefix [

	^ processedPrefix
]

{ #category : 'initialization' }
CopilotDebounceTestBuilder >> waitProcessedForMilliseconds: ms [

	^ semaphore waitTimeoutMilliseconds: ms
]
