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
	#name : 'CoBenchmarkSuite',
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
CoBenchmarkSuite class >> run [
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
CoBenchmarkSuite class >> runContextCapacity [
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
CoBenchmarkSuite class >> runModels: modelNames [
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
CoBenchmarkSuite class >> runQuick [
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
CoBenchmarkSuite >> buildPromptFor: aScenario [

	| template |
	template := CoBenchmarkPharoCopilotRunner defaultTemplate.
	^ (((template
		copyReplaceAll: '<|fim_prefix|>' with: aScenario prefix)
		copyReplaceAll: '<|fim_suffix|>' with: aScenario suffix)
		copyReplaceAll: '<|fim_context|>' with: aScenario context)
		copyReplaceAll: '<|fim_middle|>' with: ''
]

{ #category : 'private' }
CoBenchmarkSuite >> clearModelCacheFor: modelName [

	[ client transport
		postJsonAt: 'api/generate'
		body: (Dictionary new
			at: #model put: modelName;
			at: #keep_alive put: 0;
			yourself)
	] on: Error do: [ :ex | "ignore" ]
]

{ #category : 'initialization' }
CoBenchmarkSuite >> coldStart [
	^ coldStart
]

{ #category : 'initialization' }
CoBenchmarkSuite >> coldStart: aBoolean [

	coldStart := aBoolean
]

{ #category : 'private' }
CoBenchmarkSuite >> collectScenarios [

	| scenarios |
	scenarios := Dictionary new.
	includeCodeScenarios ifTrue: [ scenarios addAll: CoBenchmarkScenarioCatalog defaultScenarios ].
	scenarios addAll: CoBenchmarkCacheScenario allScenarios.
	includeContextScaling ifTrue: [ scenarios addAll: CoBenchmarkContextScenario contextSizeScenarios ].
	includeFimQuality ifTrue: [ scenarios addAll: CoBenchmarkContextScenario fimQualityScenarios ].
	includeStrategyComparison ifTrue: [ scenarios addAll: CoBenchmarkContextScenario contextStrategyScenarios ].
	^ scenarios
]

{ #category : 'private' }
CoBenchmarkSuite >> ensureModelAvailable: modelName [

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
CoBenchmarkSuite >> executeScenario: aScenario model: modelName [

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

		result := CoBenchmarkResult
			fromOllamaResponse: response
			scenario: aScenario
			model: modelName
			startMillis: startMillis
			endMillis: endMillis.
		result promptText: prompt.
		^ result
	] on: Error do: [ :ex |
		endMillis := Time millisecondClockValue.
		^ CoBenchmarkResult
			errorFor: aScenario
			model: modelName
			error: ex
			startMillis: startMillis
			endMillis: endMillis ]
]

{ #category : 'initialization' }
CoBenchmarkSuite >> includeCodeScenarios [

	^ includeCodeScenarios
]

{ #category : 'initialization' }
CoBenchmarkSuite >> includeCodeScenarios: aBoolean [

	includeCodeScenarios := aBoolean
]

{ #category : 'initialization' }
CoBenchmarkSuite >> includeContextScaling [

	^ includeContextScaling
]

{ #category : 'initialization' }
CoBenchmarkSuite >> includeContextScaling: aBoolean [

	includeContextScaling := aBoolean
]

{ #category : 'initialization' }
CoBenchmarkSuite >> includeFimQuality [

	^ includeFimQuality
]

{ #category : 'initialization' }
CoBenchmarkSuite >> includeFimQuality: aBoolean [

	includeFimQuality := aBoolean
]

{ #category : 'initialization' }
CoBenchmarkSuite >> includeStrategyComparison [

	^ includeStrategyComparison
]

{ #category : 'initialization' }
CoBenchmarkSuite >> includeStrategyComparison: aBoolean [

	includeStrategyComparison := aBoolean
]

{ #category : 'initialization' }
CoBenchmarkSuite >> initialize [

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
CoBenchmarkSuite >> models [

	^ models
]

{ #category : 'initialization' }
CoBenchmarkSuite >> models: anArray [

	models := anArray
]

{ #category : 'initialization' }
CoBenchmarkSuite >> numCtx [

	^ numCtx
]

{ #category : 'initialization' }
CoBenchmarkSuite >> numCtx: anInteger [

	numCtx := anInteger
]

{ #category : 'initialization' }
CoBenchmarkSuite >> numPredict [

	^ numPredict
]

{ #category : 'initialization' }
CoBenchmarkSuite >> numPredict: anInteger [

	numPredict := anInteger
]

{ #category : 'initialization' }
CoBenchmarkSuite >> outputDirectory [

	^ outputDirectory
]

{ #category : 'initialization' }
CoBenchmarkSuite >> outputDirectory: aFileReference [

	outputDirectory := aFileReference
]

{ #category : 'report' }
CoBenchmarkSuite >> report [
	"Return a CoBenchmarkReport for the collected results."

	| report |
	report := CoBenchmarkReport on: results.
	outputDirectory ifNotNil: [ report outputDirectory: outputDirectory ].
	^ report
]

{ #category : 'initialization' }
CoBenchmarkSuite >> results [

	^ results
]

{ #category : 'running' }
CoBenchmarkSuite >> run [
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
						r := CoBenchmarkResult new.
						r model: modelName; scenario: name; runIndex: i; success: false;
							errorMessage: 'Model not available'.
						results add: r ] ] ] ].

	Transcript show: '=== Benchmark complete: ', results size asString, ' results ==='; cr.
	^ results
]

{ #category : 'running' }
CoBenchmarkSuite >> runModel: modelName scenarios: scenarios [

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
CoBenchmarkSuite >> runsPerScenario [

	^ runsPerScenario
]

{ #category : 'running' }
CoBenchmarkSuite >> runsPerScenario: anInteger [

	runsPerScenario := anInteger
]

{ #category : 'initialization' }
CoBenchmarkSuite >> temperature [

	^ temperature
]

{ #category : 'initialization' }
CoBenchmarkSuite >> temperature: aNumber [

	temperature := aNumber
]
