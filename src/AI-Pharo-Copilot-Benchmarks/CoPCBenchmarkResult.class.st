"
Executes benchmark scenarios against one or more configured models.

This class is responsible for building prompts from benchmark scenarios,
sending requests to the completion backend, collecting timing and token metrics,
and storing the resulting benchmark data.

Use the runner when you want low-level control over benchmark execution
and raw result collection.
"
Class {
	#name : 'CoPCBenchmarkResult',
	#superclass : 'Object',
	#instVars : [
		'model',
		'scenario',
		'runIndex',
		'timestamp',
		'success',
		'errorMessage',
		'promptText',
		'completionText',
		'contextSizeBytes',
		'contextSizeChars',
		'prefixSizeChars',
		'suffixSizeChars',
		'promptTokens',
		'completionTokens',
		'totalTimeSeconds',
		'promptEvalTimeSeconds',
		'evalTimeSeconds',
		'tokensPerSecond',
		'numCtx',
		'numPredict',
		'temperature',
		'contextStrategy',
		'coldStart'
	],
	#category : 'AI-Pharo-Copilot-Benchmarks',
	#package : 'AI-Pharo-Copilot-Benchmarks'
}

{ #category : 'as yet unclassified' }
CoPCBenchmarkResult class >> csvHeader [

	^ #('model' 'scenario' 'run' 'success' 'cold_start' 'context_strategy'
	     'num_ctx' 'num_predict' 'temperature'
	     'context_size_chars' 'context_size_bytes' 'prefix_size_chars' 'suffix_size_chars'
	     'total_prompt_size_chars' 'estimated_prompt_tokens'
	     'prompt_tokens' 'completion_tokens'
	     'total_time_s' 'prompt_eval_time_s' 'eval_time_s' 'tokens_per_second'
	     'error')
]

{ #category : 'as yet unclassified' }
CoPCBenchmarkResult class >> errorFor: aScenario model: modelName error: anError startMillis: start endMillis: end [

	| result |
	result := self new.
	result model: modelName.
	result scenario: aScenario name.
	result timestamp: DateAndTime now.
	result success: false.
	result errorMessage: anError description.
	result totalTimeSeconds: (end - start) / 1000.0.
	result contextSizeChars: aScenario context size.
	result prefixSizeChars: aScenario prefix size.
	result suffixSizeChars: aScenario suffix size.
	result contextSizeBytes: aScenario context utf8Encoded size.
	^ result
]

{ #category : 'as yet unclassified' }
CoPCBenchmarkResult class >> fromOllamaResponse: response scenario: aScenario model: modelName startMillis: start endMillis: end [
	"Build a successful benchmark result from a raw Ollama api/generate response dictionary."
 
	| result completionText promptEval evalDuration promptTokens completionTokens tokPerSec |
	result := self new.
	result model: modelName.
	result scenario: aScenario name.
	result timestamp: DateAndTime now.
	result success: true.
	result totalTimeSeconds: (end - start) / 1000.0.
	result contextSizeChars: aScenario context size.
	result prefixSizeChars: aScenario prefix size.
	result suffixSizeChars: aScenario suffix size.
	result contextSizeBytes: aScenario context utf8Encoded size.
 
	completionText := response
		ifNil: [ '' ]
		ifNotNil: [
			response at: #response ifAbsent: [
				response at: 'response' ifAbsent: [ '' ] ] ].
	result completionText: completionText.
 
	promptEval := (result safeNumber: response key: #prompt_eval_duration) / 1e9.
	evalDuration := (result safeNumber: response key: #eval_duration) / 1e9.
	promptTokens := result safeNumber: response key: #prompt_eval_count.
	completionTokens := result safeNumber: response key: #eval_count.
 
	result promptEvalTimeSeconds: promptEval.
	result evalTimeSeconds: evalDuration.
	result promptTokens: promptTokens.
	result completionTokens: completionTokens.
 
	tokPerSec := evalDuration > 0
		ifTrue: [ completionTokens / evalDuration ]
		ifFalse: [ 0 ].
	result tokensPerSecond: tokPerSec.
 
	^ result
]

{ #category : 'export' }
CoPCBenchmarkResult >> asCsvFields [

	^ OrderedCollection new
		add: self model;
		add: self scenario;
		add: self runIndex;
		add: self success;
		add: self coldStart;
		add: self contextStrategy;
		add: self numCtx;
		add: self numPredict;
		add: self temperature;
		add: self contextSizeChars;
		add: self contextSizeBytes;
		add: self prefixSizeChars;
		add: self suffixSizeChars;
		add: self totalPromptSizeChars;
		add: self estimatedPromptTokens;
		add: self promptTokens;
		add: self completionTokens;
		add: self totalTimeSeconds;
		add: self promptEvalTimeSeconds;
		add: self evalTimeSeconds;
		add: self tokensPerSecond;
		add: self errorMessage;
		yourself
]

{ #category : 'export' }
CoPCBenchmarkResult >> asDictionary [

	^ Dictionary new
		  at: #model put: self model;
		  at: #scenario put: self scenario;
		  at: #run put: self runIndex;
		  at: #success put: self success;
		  at: #coldStart put: self coldStart;
		  at: #contextStrategy put: self contextStrategy;
		  at: #numCtx put: self numCtx;
		  at: #numPredict put: self numPredict;
		  at: #temperature put: self temperature;
		  at: #contextSizeChars put: self contextSizeChars;
		  at: #contextSizeBytes put: self contextSizeBytes;
		  at: #prefixSizeChars put: self prefixSizeChars;
		  at: #suffixSizeChars put: self suffixSizeChars;
		  at: #totalPromptSizeChars put: self totalPromptSizeChars;
		  at: #estimatedPromptTokens put: self estimatedPromptTokens;
		  at: #promptTokens put: self promptTokens;
		  at: #completionTokens put: self completionTokens;
		  at: #totalTimeSeconds put: self totalTimeSeconds;
		  at: #promptEvalTimeSeconds put: self promptEvalTimeSeconds;
		  at: #evalTimeSeconds put: self evalTimeSeconds;
		  at: #tokensPerSecond put: self tokensPerSecond;
		  at: #completionText put: self completionText;
		  at: #errorMessage put: self errorMessage;
		  at: #timestamp put: self timestamp asString;
		  yourself
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> coldStart [

	^ coldStart ifNil: [ false ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> coldStart: aBoolean [

	coldStart := aBoolean
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> completionText [

	^ completionText ifNil: [ '' ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> completionText: aString [

	completionText := aString
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> completionTokens [

	^ completionTokens ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> completionTokens: anInteger [

	completionTokens := anInteger
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> contextSizeBytes [

	^ contextSizeBytes ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> contextSizeBytes: anInteger [

	contextSizeBytes := anInteger
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> contextSizeChars [

	^ contextSizeChars ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> contextSizeChars: anInteger [

	contextSizeChars := anInteger
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> contextStrategy [

	^ contextStrategy ifNil: [ 'default' ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> contextStrategy: aString [

	contextStrategy := aString
]

{ #category : 'export' }
CoPCBenchmarkResult >> csvHeader [

	^ #('model' 'scenario' 'run' 'success' 'cold_start' 'context_strategy'
	     'num_ctx' 'num_predict' 'temperature'
	     'context_size_chars' 'context_size_bytes' 'prefix_size_chars' 'suffix_size_chars'
	     'total_prompt_size_chars' 'estimated_prompt_tokens'
	     'prompt_tokens' 'completion_tokens'
	     'total_time_s' 'prompt_eval_time_s' 'eval_time_s' 'tokens_per_second'
	     'error')
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> errorMessage [

	^ errorMessage ifNil: [ '' ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> errorMessage: aString [

	errorMessage := aString
]

{ #category : 'derived' }
CoPCBenchmarkResult >> estimatedPromptTokens [


	"Rough estimate: 1 token ~ 4 chars for code"
	^ (self contextSizeChars + self prefixSizeChars + self suffixSizeChars) / 4.0
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> evalTimeSeconds [

	^ evalTimeSeconds ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> evalTimeSeconds: aNumber [

	evalTimeSeconds := aNumber
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> model [

	^ model ifNil: [ '' ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> model: aString [

	model := aString
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> numCtx [ 

	^ numCtx ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> numCtx: anInteger [

	numCtx := anInteger
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> numPredict [

	^ numPredict ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> numPredict: anInteger [

	numPredict := anInteger
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> prefixSizeChars [

	^ prefixSizeChars ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> prefixSizeChars: anInteger [

	prefixSizeChars := anInteger
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> promptEvalTimeSeconds [ 

	^ promptEvalTimeSeconds ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> promptEvalTimeSeconds: aNumber [

	promptEvalTimeSeconds := aNumber
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> promptText [

	^ promptText ifNil: [ '' ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> promptText: aString [

	promptText := aString
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> promptTokens [

	^ promptTokens ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> promptTokens: anInteger [ 

	promptTokens := anInteger
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> runIndex [

	^ runIndex ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> runIndex: anInteger [

	runIndex := anInteger
]

{ #category : 'private' }
CoPCBenchmarkResult >> safeNumber: aDict key: aKey [


	| value |
	value := aDict at: aKey ifAbsent: [ aDict at: aKey asString ifAbsent: [ 0 ] ].
	^ value ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> scenario [

	^ scenario ifNil: [ '' ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> scenario: aString [ 

	scenario := aString
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> success [

	^ success ifNil: [ false ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> success: aBoolean [ 

	success := aBoolean
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> suffixSizeChars [

	^ suffixSizeChars ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> suffixSizeChars: anInteger [

	suffixSizeChars := anInteger
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> temperature [

	^ temperature ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> temperature: aNumber [

	temperature := aNumber
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> timestamp [

	^ timestamp
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> timestamp: aDateAndTime [

	timestamp := aDateAndTime
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> tokensPerSecond [

	^ tokensPerSecond ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> tokensPerSecond: aNumber [ 

	tokensPerSecond := aNumber
]

{ #category : 'derived' }
CoPCBenchmarkResult >> totalPromptSizeChars [


	^ self contextSizeChars + self prefixSizeChars + self suffixSizeChars
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> totalTimeSeconds [

	^ totalTimeSeconds ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoPCBenchmarkResult >> totalTimeSeconds: aNumber [

	totalTimeSeconds := aNumber
]
