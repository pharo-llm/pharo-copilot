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
CoBenchmarkSuite >> coldStart [
	^ coldStart
]

{ #category : 'initialization' }
CoBenchmarkSuite >> coldStart: aBoolean [

	coldStart := aBoolean
]

{ #category : 'initialization' }
CoBenchmarkSuite >> includeCodeScenarios [

	^ includeCodeScenarios
]

{ #category : 'initialization' }
CoBenchmarkSuite >> initialize [

	super initialize.
	models := #('qwen2.5-coder:3b').
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
CoBenchmarkSuite >> runsPerScenario [

	^ runsPerScenario
]

{ #category : 'initialization' }
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
