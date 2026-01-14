Class {
	#name : 'CopilotTestableBuilder',
	#superclass : 'CoPharoCopilotResultSetBuilder',
	#instVars : [
		'testContext',
		'snapshotCalled',
		'scheduledDelay',
		'scheduledPrefix',
		'scheduledSuffix'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
CopilotTestableBuilder >> completionContext [
	^ testContext
]

{ #category : 'accessing' }
CopilotTestableBuilder >> completionContext: aContext [

	^ testContext := aContext
]

{ #category : 'accessing' }
CopilotTestableBuilder >> contextInfoFor: aContext prefix: prefix suffix: suffix [

	"Keep tests cheap."
	^ Dictionary new
]

{ #category : 'accessing' }
CopilotTestableBuilder >> contextSnapshotFor: aContext [

	"Minimal snapshot; mark that we paid the cost."
	| src pos prefix suffix |
	snapshotCalled := true.
	src := aContext source.
	pos := aContext position.
	pos := (pos max: 0) min: src size.
	prefix := pos = 0 ifTrue: [ '' ] ifFalse: [ src copyFrom: 1 to: pos ].
	suffix := pos = src size ifTrue: [ '' ] ifFalse: [ src copyFrom: pos + 1 to: src size ].
	^ Dictionary new
		at: #prefix put: prefix;
		at: #suffix put: suffix;
		yourself
]

{ #category : 'accessing' }
CopilotTestableBuilder >> deferUI: aBlock [

	"Run immediately in tests."
	^ aBlock value
]

{ #category : 'accessing' }
CopilotTestableBuilder >> scheduleCompletionFor: aContext prefix: prefixString suffix: suffixString contextInfo: contextInfo delayMilliseconds: delayMs [
	"Don't fork in buildCompletion tests; just record."
	scheduledDelay := delayMs.
	scheduledPrefix := prefixString.
	scheduledSuffix := suffixString.
]

{ #category : 'accessing' }
CopilotTestableBuilder >> scheduledDelay [

	^ scheduledDelay
]

{ #category : 'accessing' }
CopilotTestableBuilder >> scheduledPrefix [

	^ scheduledPrefix
]

{ #category : 'accessing' }
CopilotTestableBuilder >> scheduledSuffix [

	^ scheduledSuffix
]

{ #category : 'accessing' }
CopilotTestableBuilder >> snapshotWasCalled [

	^ snapshotCalled = true
]
