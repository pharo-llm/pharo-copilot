Class {
	#name : 'CoPCBenchmarkReport',
	#superclass : 'Object',
	#instVars : [
		'results',
		'outputDirectory'
	],
	#category : 'AI-Pharo-Copilot-Benchmarks',
	#package : 'AI-Pharo-Copilot-Benchmarks'
}

{ #category : 'instance creation' }
CoPCBenchmarkReport class >> on: aCollectionOfResults [

	^ self new results: aCollectionOfResults
]

{ #category : 'export' }
CoPCBenchmarkReport >> exportAll [
	"Export everything: CSV, JSON, summary text, completions. Returns the output directory."

	self outputDirectory ensureCreateDirectory.
	self exportCsv.
	self exportJson.
	self exportSummary.
	self exportCompletions.
	self exportModelComparison.
	self exportContextScaling.
	^ self outputDirectory
]

{ #category : 'export' }
CoPCBenchmarkReport >> exportCompletions [

	| stream |
	stream := (self outputDirectory / 'completions.txt') writeStream.
	[
		results do: [ :r |
			r success ifTrue: [
				stream
					nextPutAll: (String new: 70 withAll: $=); lf;
					nextPutAll: 'Model: ', r model; lf;
					nextPutAll: 'Scenario: ', r scenario; lf;
					nextPutAll: 'Run: ', r runIndex asString; lf;
					nextPutAll: 'Tokens: ', r completionTokens asString; lf;
					nextPutAll: 'Time: ', (r totalTimeSeconds printShowingDecimalPlaces: 3), 's'; lf;
					nextPutAll: (String new: 70 withAll: $-); lf;
					nextPutAll: r completionText; lf; lf ] ]
	] ensure: [ stream close ]
]

{ #category : 'export' }
CoPCBenchmarkReport >> exportContextScaling [
	"Export context size scaling analysis."

	| contextResults stream grouped |
	contextResults := results select: [ :r |
		r scenario beginsWith: 'context_' ].
	contextResults isEmpty ifTrue: [ ^ self ].

	stream := (self outputDirectory / 'context_scaling.csv') writeStream.
	[
		stream nextPutAll: 'context_size_chars,model,avg_total_time_s,avg_prompt_eval_s,avg_eval_s,avg_tokens_per_sec,avg_prompt_tokens'; lf.

		grouped := contextResults groupedBy: [ :r | r scenario, '|', r model ].
		grouped keysAndValuesDo: [ :key :group |
			| successful |
			successful := group select: [ :r | r success ].
			successful isEmpty ifFalse: [
				stream
					nextPutAll: successful first contextSizeChars asString; nextPut: $,;
					nextPutAll: successful first model; nextPut: $,;
					nextPutAll: (self mean: (successful collect: [ :r | r totalTimeSeconds ])) asString; nextPut: $,;
					nextPutAll: (self mean: (successful collect: [ :r | r promptEvalTimeSeconds ])) asString; nextPut: $,;
					nextPutAll: (self mean: (successful collect: [ :r | r evalTimeSeconds ])) asString; nextPut: $,;
					nextPutAll: (self mean: (successful collect: [ :r | r tokensPerSecond ])) asString; nextPut: $,;
					nextPutAll: (self mean: (successful collect: [ :r | r promptTokens ])) asString; lf ] ]
	] ensure: [ stream close ]
]

{ #category : 'export' }
CoPCBenchmarkReport >> exportCsv [

	| stream |
	stream := (self outputDirectory / 'results.csv') writeStream.
	[
		"Header"
		stream nextPutAll: ($, join: CoPCBenchmarkResult csvHeader); lf.
		"Rows"
		results do: [ :r |
			stream nextPutAll: ($, join: (r asCsvFields collect: [ :f | f asString ])); lf ]
	] ensure: [ stream close ]
]

{ #category : 'export' }
CoPCBenchmarkReport >> exportJson [

	| data |
	data := Dictionary new
		        at: #metadata put: self metadataDictionary;
		        at: #results put: (results collect: [ :r | r asDictionary ]) asArray;
		        at: #statistics put: self statisticsDictionary;
		        yourself.
	(self outputDirectory / 'results.json') writeStream
		nextPutAll: (STONJSON toStringPretty: data);
		close
]

{ #category : 'export' }
CoPCBenchmarkReport >> exportModelComparison [
	"Export a model-vs-model comparison table."

	| models stream metrics |
	models := (results collect: [ :r | r model ]) asSet asSortedCollection.
	models size < 2 ifTrue: [ ^ self ].

	stream := (self outputDirectory / 'model_comparison.txt') writeStream.
	[
		stream nextPutAll: 'MODEL COMPARISON'; lf.
		stream nextPutAll: (String new: 70 withAll: $=); lf; lf.

		stream nextPutAll: (self padRight: 'Metric' to: 30).
		models do: [ :m | stream nextPutAll: (self padRight: m to: 20) ].
		stream lf.
		stream nextPutAll: (String new: 30 + (models size * 20) withAll: $-); lf.

		metrics := {
			{ 'Avg Total Time (s)'. [ :r | r totalTimeSeconds ] }.
			{ 'Avg Prompt Eval (s)'. [ :r | r promptEvalTimeSeconds ] }.
			{ 'Avg Eval Time (s)'. [ :r | r evalTimeSeconds ] }.
			{ 'Avg Tokens/sec'. [ :r | r tokensPerSecond ] }.
			{ 'Avg Prompt Tokens'. [ :r | r promptTokens ] }.
			{ 'Avg Completion Tokens'. [ :r | r completionTokens ] }.
			{ 'Success Rate (%)'. nil }
		}.

		metrics do: [ :spec |
			stream nextPutAll: (self padRight: spec first to: 30).
			models do: [ :m |
				| modelResults value |
				modelResults := results select: [ :r | r model = m and: [ r success ] ].
				value := spec second isNil
					ifTrue: [
						| total successful |
						total := (results select: [ :r | r model = m ]) size.
						successful := modelResults size.
						total > 0
							ifTrue: [ (successful / total * 100.0) printShowingDecimalPlaces: 1 ]
							ifFalse: [ '0.0' ] ]
					ifFalse: [
						modelResults isEmpty
							ifTrue: [ 'N/A' ]
							ifFalse: [ (self mean: (modelResults collect: spec second)) printShowingDecimalPlaces: 3 ] ].
				stream nextPutAll: (self padRight: value to: 20) ].
			stream lf ]
	] ensure: [ stream close ]
]

{ #category : 'export' }
CoPCBenchmarkReport >> exportSummary [

	(self outputDirectory / 'summary.txt') writeStream
		nextPutAll: self generateSummary;
		close
]

{ #category : 'report' }
CoPCBenchmarkReport >> generateSummary [

	^ String streamContents: [ :s |
		self writeBannerOn: s.
		self writeOverviewOn: s.
		self writePerModelStatsOn: s.
		self writePerScenarioStatsOn: s.
		self writeContextAnalysisOn: s.
		self writeTopResultsOn: s.
		self writeBottomResultsOn: s ]
]

{ #category : 'stat' }
CoPCBenchmarkReport >> mean: aCollection [

	aCollection isEmpty ifTrue: [ ^ 0 ].
	^ (aCollection inject: 0 into: [ :sum :each | sum + each ]) / aCollection size asFloat
]

{ #category : 'stat' }
CoPCBenchmarkReport >> median: aCollection [

	| sorted mid |
	aCollection isEmpty ifTrue: [ ^ 0 ].
	sorted := aCollection asSortedCollection.
	mid := sorted size // 2.
	sorted size even
		ifTrue: [ ^ ((sorted at: mid) + (sorted at: mid + 1)) / 2.0 ]
		ifFalse: [ ^ sorted at: mid + 1 ]
]

{ #category : 'report' }
CoPCBenchmarkReport >> metadataDictionary [

	^ Dictionary new
		at: #generatedAt put: DateAndTime now asString;
		at: #totalResults put: results size;
		at: #models put: (results collect: [ :r | r model ]) asSet asSortedCollection asArray;
		at: #scenarios put: (results collect: [ :r | r scenario ]) asSet asSortedCollection asArray;
		yourself
]

{ #category : 'accessing' }
CoPCBenchmarkReport >> outputDirectory [

	^ outputDirectory ifNil: [ FileLocator workingDirectory / 'benchmark_output' ]
]

{ #category : 'accessing' }
CoPCBenchmarkReport >> outputDirectory: aFileReference [

	outputDirectory := aFileReference
]

{ #category : 'private' }
CoPCBenchmarkReport >> padRight: aString to: anInteger [

	| s |
	s := aString asString.
	s size >= anInteger ifTrue: [ ^ s ].
	^ s , (String new: anInteger - s size withAll: Character space)
]

{ #category : 'accessing' }
CoPCBenchmarkReport >> results [

	^ results
]

{ #category : 'accessing' }
CoPCBenchmarkReport >> results: aCollection [

	results := aCollection
]

{ #category : 'stat' }
CoPCBenchmarkReport >> statisticsDictionary [

	| models stats |
	models := (results collect: [ :r | r model ]) asSet asSortedCollection.
	stats := Dictionary new.

	models do: [ :m |
		| successful modelStats |
		successful := results select: [ :r | r model = m and: [ r success ] ].
		modelStats := Dictionary new.
		successful isEmpty ifFalse: [
			modelStats
				at: #meanTotalTime put: (self mean: (successful collect: [ :r | r totalTimeSeconds ]));
				at: #medianTotalTime put: (self median: (successful collect: [ :r | r totalTimeSeconds ]));
				at: #stddevTotalTime put: (self stddev: (successful collect: [ :r | r totalTimeSeconds ]));
				at: #meanTokensPerSecond put: (self mean: (successful collect: [ :r | r tokensPerSecond ]));
				at: #medianTokensPerSecond put: (self median: (successful collect: [ :r | r tokensPerSecond ]));
				at: #meanPromptTokens put: (self mean: (successful collect: [ :r | r promptTokens ]));
				at: #meanCompletionTokens put: (self mean: (successful collect: [ :r | r completionTokens ]));
				at: #successRate put: (successful size / (results select: [ :r | r model = m ]) size * 100.0);
				at: #totalRuns put: (results select: [ :r | r model = m ]) size ].
		stats at: m put: modelStats ].

	^ stats
]

{ #category : 'stat' }
CoPCBenchmarkReport >> stddev: aCollection [

	| avg |
	aCollection size < 2 ifTrue: [ ^ 0 ].
	avg := self mean: aCollection.
	^ ((aCollection inject: 0 into: [ :sum :each |
		sum + ((each - avg) * (each - avg)) ]) / (aCollection size - 1)) sqrt
]

{ #category : 'report' }
CoPCBenchmarkReport >> writeBannerOn: s [

	s nextPutAll: (String new: 70 withAll: $#); lf.
	s nextPutAll: '#  PHARO COPILOT BENCHMARK REPORT'; lf.
	s nextPutAll: '#  Generated: ', DateAndTime now asString; lf.
	s nextPutAll: (String new: 70 withAll: $#); lf; lf
]

{ #category : 'report' }
CoPCBenchmarkReport >> writeBottomResultsOn: s [

	| successful sorted |
	successful := results select: [ :r | r success ].
	successful isEmpty ifTrue: [ ^ self ].

	s nextPutAll: 'SLOWEST COMPLETIONS (Bottom 5)'; lf.
	s nextPutAll: (String new: 40 withAll: $-); lf.

	sorted := successful asSortedCollection: [ :a :b | a totalTimeSeconds > b totalTimeSeconds ].
	(sorted first: (5 min: sorted size)) do: [ :r |
		s nextPutAll: '  ', r model, ' / ', r scenario,
			' - ', (r totalTimeSeconds printShowingDecimalPlaces: 3), 's',
			' (', (r tokensPerSecond printShowingDecimalPlaces: 1), ' tok/s)'; lf ].
	s lf
]

{ #category : 'report' }
CoPCBenchmarkReport >> writeContextAnalysisOn: s [

	| contextResults grouped sortedKeys |
	contextResults := results select: [ :r |
		r scenario beginsWith: 'context_' ].
	contextResults isEmpty ifTrue: [ ^ self ].

	s nextPutAll: 'CONTEXT SIZE SCALING ANALYSIS'; lf.
	s nextPutAll: (String new: 40 withAll: $-); lf.
	s nextPutAll: 'Shows how performance changes with context size.'; lf; lf.

	grouped := (contextResults select: [ :r | r success ]) groupedBy: [ :r | r contextSizeChars ].
	sortedKeys := grouped keys asSortedCollection.

	s nextPutAll: (self padRight: 'Ctx Chars' to: 12).
	s nextPutAll: (self padRight: 'Avg Time(s)' to: 14).
	s nextPutAll: (self padRight: 'Avg Tok/s' to: 14).
	s nextPutAll: (self padRight: 'Avg PromptTok' to: 16).
	s nextPutAll: 'Avg CompTok'; lf.
	s nextPutAll: (String new: 70 withAll: $-); lf.

	sortedKeys do: [ :ctxSize |
		| group |
		group := grouped at: ctxSize.
		s nextPutAll: (self padRight: ctxSize asString to: 12).
		s nextPutAll: (self padRight: ((self mean: (group collect: [ :r | r totalTimeSeconds ])) printShowingDecimalPlaces: 3) to: 14).
		s nextPutAll: (self padRight: ((self mean: (group collect: [ :r | r tokensPerSecond ])) printShowingDecimalPlaces: 1) to: 14).
		s nextPutAll: (self padRight: ((self mean: (group collect: [ :r | r promptTokens ])) printShowingDecimalPlaces: 0) to: 16).
		s nextPutAll: ((self mean: (group collect: [ :r | r completionTokens ])) printShowingDecimalPlaces: 0); lf ].
	s lf
]

{ #category : 'report' }
CoPCBenchmarkReport >> writeOverviewOn: s [

	| successful failed models scenarios |
	successful := results select: [ :r | r success ].
	failed := results reject: [ :r | r success ].
	models := (results collect: [ :r | r model ]) asSet asSortedCollection.
	scenarios := (results collect: [ :r | r scenario ]) asSet asSortedCollection.

	s nextPutAll: 'OVERVIEW'; lf.
	s nextPutAll: (String new: 40 withAll: $-); lf.
	s nextPutAll: 'Total runs:       ', results size asString; lf.
	s nextPutAll: 'Successful:       ', successful size asString; lf.
	s nextPutAll: 'Failed:           ', failed size asString; lf.
	s nextPutAll: 'Models tested:    ', ($, join: models); lf.
	s nextPutAll: 'Scenarios:        ', scenarios size asString; lf.
	s nextPutAll: 'Unique scenarios: ', ($, join: scenarios); lf; lf
]

{ #category : 'report' }
CoPCBenchmarkReport >> writePerModelStatsOn: s [

	| models |
	models := (results collect: [ :r | r model ]) asSet asSortedCollection.

	s nextPutAll: 'PER-MODEL STATISTICS'; lf.
	s nextPutAll: (String new: 40 withAll: $-); lf.

	models do: [ :m |
		| modelResults successful |
		modelResults := results select: [ :r | r model = m ].
		successful := modelResults select: [ :r | r success ].

		s nextPutAll: 'Model: ', m; lf.
		s nextPutAll: '  Runs: ', modelResults size asString,
			' (', successful size asString, ' successful)'; lf.

		successful isEmpty ifFalse: [
			| times tps promptToks compToks |
			times := successful collect: [ :r | r totalTimeSeconds ].
			tps := successful collect: [ :r | r tokensPerSecond ].
			promptToks := successful collect: [ :r | r promptTokens ].
			compToks := successful collect: [ :r | r completionTokens ].

			s nextPutAll: '  Total Time  - mean: ', (self mean: times) printString,
				's  median: ', (self median: times) printString,
				's  stddev: ', (self stddev: times) printString, 's'; lf.
			s nextPutAll: '  Tokens/sec  - mean: ', (self mean: tps) printString,
				'  median: ', (self median: tps) printString,
				'  stddev: ', (self stddev: tps) printString; lf.
			s nextPutAll: '  Prompt Tok  - mean: ', (self mean: promptToks) printString,
				'  median: ', (self median: promptToks) printString; lf.
			s nextPutAll: '  Compl Tok   - mean: ', (self mean: compToks) printString,
				'  median: ', (self median: compToks) printString; lf ].
		s lf ]
]

{ #category : 'report' }
CoPCBenchmarkReport >> writePerScenarioStatsOn: s [

	| scenarios |
	scenarios := (results collect: [ :r | r scenario ]) asSet asSortedCollection.

	s nextPutAll: 'PER-SCENARIO STATISTICS'; lf.
	s nextPutAll: (String new: 40 withAll: $-); lf.

	scenarios do: [ :sc |
		| scResults successful |
		scResults := results select: [ :r | r scenario = sc ].
		successful := scResults select: [ :r | r success ].

		s nextPutAll: 'Scenario: ', sc; lf.
		s nextPutAll: '  Context size: ', (successful isEmpty
			ifTrue: [ '?' ]
			ifFalse: [ successful first contextSizeChars asString ]), ' chars'; lf.

		successful isEmpty ifFalse: [
			| times |
			times := successful collect: [ :r | r totalTimeSeconds ].
			s nextPutAll: '  Avg time: ', (self mean: times) printString, 's'; lf.
			s nextPutAll: '  Avg tokens/sec: ', (self mean: (successful collect: [ :r | r tokensPerSecond ])) printString; lf ].
		s lf ]
]

{ #category : 'report' }
CoPCBenchmarkReport >> writeTopResultsOn: s [

	| successful sorted |
	successful := results select: [ :r | r success ].
	successful isEmpty ifTrue: [ ^ self ].

	s nextPutAll: 'FASTEST COMPLETIONS (Top 5)'; lf.
	s nextPutAll: (String new: 40 withAll: $-); lf.

	sorted := successful asSortedCollection: [ :a :b | a totalTimeSeconds < b totalTimeSeconds ].
	(sorted first: (5 min: sorted size)) do: [ :r |
		s nextPutAll: '  ', r model, ' / ', r scenario,
			' - ', (r totalTimeSeconds printShowingDecimalPlaces: 3), 's',
			' (', (r tokensPerSecond printShowingDecimalPlaces: 1), ' tok/s)'; lf ].
	s lf
]
