"
I announce that a Copilot suggestion evaluation entry was produced or updated.
I carry the evaluation entry through the Announcements framework.
"
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
