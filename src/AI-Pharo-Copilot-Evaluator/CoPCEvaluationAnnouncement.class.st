Class {
	#name : 'CoPCEvaluationAnnouncement',
	#superclass : 'Announcement',
	#instVars : [
		'entry'
	],
	#category : 'AI-Pharo-Copilot-Evaluator',
	#package : 'AI-Pharo-Copilot-Evaluator'
}

{ #category : 'accessing' }
CoPCEvaluationAnnouncement >> entry [
	^ entry
]

{ #category : 'accessing' }
CoPCEvaluationAnnouncement >> entry: anEvaluationEntry [
	entry := anEvaluationEntry
]
