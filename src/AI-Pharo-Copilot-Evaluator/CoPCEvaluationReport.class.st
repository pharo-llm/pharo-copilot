"
I generate a textual summary of a Copilot evaluation session.
I report overview metrics, context and model statistics, rejection reasons, and recommendations.
"
Class {
	#name : 'CoPCEvaluationReport',
	#superclass : 'Object',
	#instVars : [
		'evaluator'
	],
	#category : 'AI-Pharo-Copilot-Evaluator',
	#package : 'AI-Pharo-Copilot-Evaluator'
}

{ #category : 'accessing' }
CoPCEvaluationReport >> addContextStatsTo: stream [
	stream nextPutAll: 'CONTEXT ANALYSIS'; lf.
	stream nextPutAll: '----------------'; lf.
	
	(evaluator sessionStats at: #contextStats) keysAndValuesDo: [ :context :contextStats |
		| total accepted rate |
		total := (contextStats at: #accepted) + (contextStats at: #rejected) + (contextStats at: #ignored).
		accepted := contextStats at: #accepted.
		rate := total > 0 ifTrue: [ (accepted / total * 100) rounded ] ifFalse: [ 0 ].
		
		stream nextPutAll: context asString, ': ', accepted asString, '/', total asString,
			' accepted (', rate asString, '%)'; lf ].
	stream lf.
]

{ #category : 'accessing' }
CoPCEvaluationReport >> addLengthStatsTo: stream [
	stream nextPutAll: 'SUGGESTION LENGTH ANALYSIS'; lf.
	stream nextPutAll: '--------------------------'; lf.
	
	"stream nextPullAll:'--------------------------'."
	
	(evaluator sessionStats at: #lengthStats) keysAndValuesDo: [ :length :lengthStats |
		| total accepted rate |
		total := (lengthStats at: #accepted) + (lengthStats at: #rejected) + (lengthStats at: #ignored).
		accepted := lengthStats at: #accepted.
		rate := total > 0 ifTrue: [ (accepted / total * 100) rounded ] ifFalse: [ 0 ].
		
		stream nextPutAll: length asString, ' suggestions: ', accepted asString, '/', total asString,
			' accepted (', rate asString, '%)'; lf ].
	stream lf.
]

{ #category : 'accessing' }
CoPCEvaluationReport >> addModelStatsTo: stream [ 
	stream nextPutAll: 'MODEL PERFORMANCE'; lf.
	stream nextPutAll: '----------------'; lf.
	
	(evaluator sessionStats at: #modelStats) keysAndValuesDo: [ :model :modelStats |
		| total accepted rate |
		total := (modelStats at: #accepted) + (modelStats at: #rejected) + (modelStats at: #ignored).
		accepted := modelStats at: #accepted.
		rate := total > 0 ifTrue: [ (accepted / total * 100) rounded ] ifFalse: [ 0 ].
		
		stream nextPutAll: model, ': ', accepted asString, '/', total asString,
			' accepted (', rate asString, '%)'; lf ].
	stream lf.
]

{ #category : 'accessing' }
CoPCEvaluationReport >> addOverviewTo: stream [
	| stats total |
	stats := evaluator sessionStats.
	total := stats at: #totalSuggestions.
	
	stream nextPutAll: 'OVERVIEW'; lf.
	stream nextPutAll: '--------'; lf.
	stream nextPutAll: 'Session started: ', (stats at: #sessionStartTime) asString; lf.
	stream nextPutAll: 'Total suggestions: ', total asString; lf.
	stream nextPutAll: 'Accepted: ', (stats at: #totalAccepted) asString, 
		' (', evaluator acceptanceRate asString, '%)'; lf.
	stream nextPutAll: 'Rejected: ', (stats at: #totalRejected) asString,
		' (', evaluator rejectionRate asString, '%)'; lf.
	stream nextPutAll: 'Ignored: ', (total - (stats at: #totalAccepted) - (stats at: #totalRejected)) asString; lf; lf.

]

{ #category : 'accessing' }
CoPCEvaluationReport >> addRecommendationsTo: stream [
	stream nextPutAll: 'RECOMMENDATIONS'; lf.
	stream nextPutAll: '---------------'; lf.
	
	evaluator acceptanceRate < 30 ifTrue: [
		stream nextPutAll: '• Low acceptance rate - consider adjusting model parameters or FIM template'; lf ].
		
	evaluator acceptanceRate > 80 ifTrue: [
		stream nextPutAll: '• High acceptance rate - model is performing well'; lf ].
		
	stream nextPutAll: '• Export data to CSV for detailed analysis: CoSuggestionEvaluator default exportToCSV: ''evaluation.csv'''; lf.

]

{ #category : 'accessing' }
CoPCEvaluationReport >> addTopRejectionReasonsTo: stream [

	| reasons |
	reasons := Bag new.

	evaluator rejectedEntries do: [ :entry | entry rejectionReason ifNotNil: [ :reason | reasons add: reason ] ].

	stream
		nextPutAll: 'TOP REJECTION REASONS';
		lf.
	stream
		nextPutAll: '--------------------';
		lf.

	(reasons sortedCounts first: (5 min: reasons size)) do: [ :assoc |
		stream nextPutAll: assoc value, ': ', assoc key asString, ' times'; lf ].
	stream lf
]

{ #category : 'accessing' }
CoPCEvaluationReport >> evaluator: anEvaluator [ 
	evaluator := anEvaluator
]

{ #category : 'accessing' }
CoPCEvaluationReport >> generate [
	| report stats |
	stats := evaluator sessionStats.
	
	report := WriteStream on: String new.
	
	report nextPutAll: '=== Copilot Evaluation Report ==='; lf; lf.
	
	self addOverviewTo: report.
	self addModelStatsTo: report.
	self addContextStatsTo: report.
	self addLengthStatsTo: report.
	self addTopRejectionReasonsTo: report.
	self addRecommendationsTo: report.
	
	^ report contents
]
