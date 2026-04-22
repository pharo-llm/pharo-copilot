Class {
	#name : 'CoPCEvaluationEntry',
	#superclass : 'Object',
	#instVars : [
		'suggestion',
		'context',
		'timestamp',
		'action',
		'rejectionReason',
		'metadata'
	],
	#category : 'AI-Pharo-Copilot-Evaluator',
	#package : 'AI-Pharo-Copilot-Evaluator'
}

{ #category : 'accessing' }
CoPCEvaluationEntry >> action [
	^ action
]

{ #category : 'accessing' }
CoPCEvaluationEntry >> action: aSymbol [ 
	"#accepted, #rejected, or #ignored"
	action := aSymbol
]

{ #category : 'accessing' }
CoPCEvaluationEntry >> context [
	^ context
]

{ #category : 'accessing' }
CoPCEvaluationEntry >> context: aCompletionContext [
	context := aCompletionContext
]

{ #category : 'accessing' }
CoPCEvaluationEntry >> metadata [
	^ metadata ifNil: [ metadata := Dictionary new ]
]

{ #category : 'accessing' }
CoPCEvaluationEntry >> metadata: aDictionary [
	metadata := aDictionary
]

{ #category : 'accessing' }
CoPCEvaluationEntry >> rejectionReason [
	^ rejectionReason
]

{ #category : 'accessing' }
CoPCEvaluationEntry >> rejectionReason: aString [
	rejectionReason := aString
]

{ #category : 'accessing' }
CoPCEvaluationEntry >> suggestion [ 
	^ suggestion
]

{ #category : 'accessing' }
CoPCEvaluationEntry >> suggestion: aCopilotEntry [
	suggestion := aCopilotEntry
]

{ #category : 'accessing' }
CoPCEvaluationEntry >> timestamp [
	^ timestamp
]

{ #category : 'accessing' }
CoPCEvaluationEntry >> timestamp: aDateAndTime [
	timestamp := aDateAndTime
]
