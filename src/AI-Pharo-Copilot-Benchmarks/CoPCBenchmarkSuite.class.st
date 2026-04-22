"
The single entry point for benchmarking Pharo Copilot.

- Quick start (one-liner): `CoBenchmarkSuite run.`
- Multi-model comparison: `CoBenchmarkSuite runModels: #('qwen2.5-coder:1.5b' 'qwen2.5-coder:3b' 'qwen2.5-coder:7b').`
- Custom configuration:
	```
	CoBenchmarkSuite new
		models: #('qwen2.5-coder:3b' 'codellama:7b');
		runsPerScenario: 5;
		numPredict: 200;
		numCtx: 8192;
		temperature: 0.2;
		coldStart: true;
		includeContextScaling: true;
		includeCodeScenarios: true;
		includeFimQuality: true;
		run.
	```
	
The suite produces a 'benchmark_output/' directory containing:
	- results.csv          (every single run, all metrics)
	- results.json         (structured data with statistics)
	- summary.txt          (human-readable report with stats)
	- completions.txt      (all generated code)
	- model_comparison.txt (side-by-side model table)
	- context_scaling.csv  (context size vs performance)
"
Class {
	#name : 'CoPCBenchmarkSuite',
	#superclass : 'Object',
	#instVars : [
		'models',
		'runsPerScenario',
		'numPredict',
		'numCtx',
		'temperature',
		'coldStart',
		'includeCodeScenarios',
		'includeContextScaling',
		'includeFimQuality',
		'includeStrategyComparison',
		'outputDirectory',
		'results',
		'client'
	],
	#category : 'AI-Pharo-Copilot-Benchmarks',
	#package : 'AI-Pharo-Copilot-Benchmarks'
}

{ #category : 'running' }
CoPCBenchmarkSuite class >> run [
	"One-liner: run the full benchmark suite with sensible defaults and print the summary."

	| suite report |
	suite := self new.
	suite run.
	report := suite report.
	Transcript show: report generateSummary; cr.
	report exportAll.
	^ report
]

{ #category : 'running' }
CoPCBenchmarkSuite class >> runContextCapacity [
	"Benchmark focused on context size scaling."

	| suite report |
	suite := self new.
	suite includeCodeScenarios: false.
	suite includeContextScaling: true.
	suite includeFimQuality: false.
	suite includeStrategyComparison: true.
	suite runsPerScenario: 5.
	suite run.
	report := suite report.
	Transcript show: report generateSummary; cr.
	report exportAll.
	^ report
]

{ #category : 'running' }
CoPCBenchmarkSuite class >> runModels: modelNames [
	"Run the full benchmark suite comparing the given models."

	| suite report |
	suite := self new.
	suite models: modelNames.
	suite run.
	report := suite report.
	Transcript show: report generateSummary; cr.
	report exportAll.
	^ report
]

{ #category : 'running' }
CoPCBenchmarkSuite class >> runQuick [
	"Fast benchmark: 1 run per scenario, code scenarios only."

	| suite report |
	suite := self new.
	suite runsPerScenario: 1.
	suite includeContextScaling: false.
	suite includeFimQuality: false.
	suite run.
	report := suite report.
	Transcript show: report generateSummary; cr.
	report exportAll.
	^ report
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> buildPromptFor: aScenario [

	| template |
	template := CoPCBenchmarkRunner defaultTemplate.
	^ (((template
		copyReplaceAll: '<|fim_prefix|>' with: aScenario prefix)
		copyReplaceAll: '<|fim_suffix|>' with: aScenario suffix)
		copyReplaceAll: '<|fim_context|>' with: aScenario context)
		copyReplaceAll: '<|fim_middle|>' with: ''
]

{ #category : 'private' }
CoPCBenchmarkSuite >> clearModelCacheFor: modelName [

	[ client transport
		postJsonAt: 'api/generate'
		body: (Dictionary new
			at: #model put: modelName;
			at: #keep_alive put: 0;
			yourself)
	] on: Error do: [ :ex | "ignore" ]
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> coldStart [
	^ coldStart
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> coldStart: aBoolean [

	coldStart := aBoolean
]

{ #category : 'private' }
CoPCBenchmarkSuite >> collectScenarios [

	| scenarios |
	scenarios := Dictionary new.
	includeCodeScenarios ifTrue: [ scenarios addAll: CoPCBenchmarkScenarioCatalog defaultScenarios ].
	scenarios addAll: CoPCBenchmarkCacheScenario allScenarios.
	includeContextScaling ifTrue: [ scenarios addAll: CoPCBenchmarkContextScenario contextSizeScenarios ].
	includeFimQuality ifTrue: [ scenarios addAll: CoPCBenchmarkContextScenario fimQualityScenarios ].
	includeStrategyComparison ifTrue: [ scenarios addAll: CoPCBenchmarkContextScenario contextStrategyScenarios ].
	^ scenarios
]

{ #category : 'private' }
CoPCBenchmarkSuite >> ensureModelAvailable: modelName [

	| modelsResponse modelNames |
	[
		modelsResponse := client listModels.
		modelNames := modelsResponse
			ifNil: [ #() ]
			ifNotNil: [
				| list |
				list := modelsResponse at: #models ifAbsent: [
					modelsResponse at: 'models' ifAbsent: [ #() ] ].
				list collect: [ :each |
					each at: #name ifAbsent: [ each at: 'name' ifAbsent: [ '' ] ] ] ].
		(modelNames includes: modelName) ifTrue: [ ^ true ].

		"Try to pull the model"
		client transport
			postJsonAt: 'api/pull'
			body: (Dictionary new at: #name put: modelName; at: #stream put: false; yourself).
		^ true
	] on: Error do: [ ^ false ]
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> executeScenario: aScenario model: modelName [

	| prompt payload options startMillis response endMillis result |
	prompt := self buildPromptFor: aScenario.
	options := Dictionary new
		at: #num_predict put: numPredict;
		at: #num_ctx put: numCtx;
		at: #temperature put: temperature;
		at: #top_p put: 0.95;
		yourself.
	payload := Dictionary new
		at: #model put: modelName;
		at: #prompt put: prompt;
		at: #stream put: false;
		at: #keep_alive put: '10m';
		at: #options put: options;
		yourself.

	startMillis := Time millisecondClockValue.
	[
		response := client transport postJsonAt: 'api/generate' body: payload.
		endMillis := Time millisecondClockValue.

		result := CoPCBenchmarkResult
			fromOllamaResponse: response
			scenario: aScenario
			model: modelName
			startMillis: startMillis
			endMillis: endMillis.
		result promptText: prompt.
		^ result
	] on: Error do: [ :ex |
		endMillis := Time millisecondClockValue.
		^ CoPCBenchmarkResult
			errorFor: aScenario
			model: modelName
			error: ex
			startMillis: startMillis
			endMillis: endMillis ]
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> includeCodeScenarios [

	^ includeCodeScenarios
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> includeCodeScenarios: aBoolean [

	includeCodeScenarios := aBoolean
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> includeContextScaling [

	^ includeContextScaling
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> includeContextScaling: aBoolean [

	includeContextScaling := aBoolean
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> includeFimQuality [

	^ includeFimQuality
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> includeFimQuality: aBoolean [

	includeFimQuality := aBoolean
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> includeStrategyComparison [

	^ includeStrategyComparison
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> includeStrategyComparison: aBoolean [

	includeStrategyComparison := aBoolean
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> initialize [

	super initialize.
	models := #( 'omarabedelkader/pharo-qwen-coder-plus-20296:3b' ).
	runsPerScenario := 3.
	numPredict := 150.
	numCtx := 8192.
	temperature := 0.2.
	coldStart := false.
	includeCodeScenarios := true.
	includeContextScaling := true.
	includeFimQuality := true.
	includeStrategyComparison := true.
	results := OrderedCollection new
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> models [

	^ models
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> models: anArray [

	models := anArray
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> numCtx [

	^ numCtx
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> numCtx: anInteger [

	numCtx := anInteger
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> numPredict [

	^ numPredict
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> numPredict: anInteger [

	numPredict := anInteger
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> outputDirectory [

	^ outputDirectory
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> outputDirectory: aFileReference [

	outputDirectory := aFileReference
]

{ #category : 'report' }
CoPCBenchmarkSuite >> report [
	"Return a CoBenchmarkReport for the collected results."

	| report |
	report := CoPCBenchmarkReport on: results.
	outputDirectory ifNotNil: [ report outputDirectory: outputDirectory ].
	^ report
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> results [

	^ results
]

{ #category : 'running' }
CoPCBenchmarkSuite >> run [
	"Execute the full benchmark suite."

	| scenarios |
	results := OrderedCollection new.
	client := OllamaClient new.
	scenarios := self collectScenarios.

	Transcript show: '=== Pharo Copilot Benchmark Suite ==='; cr.
	Transcript show: 'Models: ', ($, join: models); cr.
	Transcript show: 'Scenarios: ', scenarios size asString; cr.
	Transcript show: 'Runs per scenario: ', runsPerScenario asString; cr.
	Transcript show: 'Total runs: ', (models size * scenarios size * runsPerScenario) asString; cr.
	Transcript show: '===================================='; cr.

	models do: [ :modelName |
		Transcript show: '[+] Testing model: ', modelName; cr.
		(self ensureModelAvailable: modelName)
			ifTrue: [ self runModel: modelName scenarios: scenarios ]
			ifFalse: [
				Transcript show: '[-] Model not available: ', modelName; cr.
				scenarios keysAndValuesDo: [ :name :scenario |
					1 to: runsPerScenario do: [ :i |
						| r |
						r := CoPCBenchmarkResult new.
						r model: modelName; scenario: name; runIndex: i; success: false;
							errorMessage: 'Model not available'.
						results add: r ] ] ] ].

	Transcript show: '=== Benchmark complete: ', results size asString, ' results ==='; cr.
	^ results
]

{ #category : 'running' }
CoPCBenchmarkSuite >> runModel: modelName scenarios: scenarios [

	scenarios keysAndValuesDo: [ :name :scenario |
		Transcript show: '  [*] Scenario: ', name; cr.
		1 to: runsPerScenario do: [ :runIndex |
			| result |
			coldStart ifTrue: [ self clearModelCacheFor: modelName ].
			result := self executeScenario: scenario model: modelName.
			result runIndex: runIndex.
			result coldStart: coldStart.
			result numCtx: numCtx.
			result numPredict: numPredict.
			result temperature: temperature.
			results add: result.
			Transcript show: '    Run ', runIndex asString, ': ',
				(result success
					ifTrue: [ (result totalTimeSeconds printShowingDecimalPlaces: 3), 's  ',
						(result tokensPerSecond printShowingDecimalPlaces: 1), ' tok/s  ',
						result completionTokens asString, ' tokens' ]
					ifFalse: [ 'FAILED - ', result errorMessage ]); cr ] ]
]

{ #category : 'running' }
CoPCBenchmarkSuite >> runsPerScenario [

	^ runsPerScenario
]

{ #category : 'running' }
CoPCBenchmarkSuite >> runsPerScenario: anInteger [

	runsPerScenario := anInteger
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> temperature [

	^ temperature
]

{ #category : 'initialization' }
CoPCBenchmarkSuite >> temperature: aNumber [

	temperature := aNumber
]
