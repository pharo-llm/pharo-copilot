Class {
	#name : 'CoBenchmarkResult',
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
CoBenchmarkResult class >> csvHeader [

	^ #('model' 'scenario' 'run' 'success' 'cold_start' 'context_strategy'
	     'num_ctx' 'num_predict' 'temperature'
	     'context_size_chars' 'context_size_bytes' 'prefix_size_chars' 'suffix_size_chars'
	     'total_prompt_size_chars' 'estimated_prompt_tokens'
	     'prompt_tokens' 'completion_tokens'
	     'total_time_s' 'prompt_eval_time_s' 'eval_time_s' 'tokens_per_second'
	     'error')
]

{ #category : 'as yet unclassified' }
CoBenchmarkResult class >> errorFor: aScenario model: modelName error: anError startMillis: start endMillis: end [

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

{ #category : 'export' }
CoBenchmarkResult >> asCsvFields [

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
CoBenchmarkResult >> asDictionary [

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
		at: #timestamp put: self timestamp;
		yourself
]

{ #category : 'accessing' }
CoBenchmarkResult >> coldStart [

	^ coldStart ifNil: [ false ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> coldStart: aBoolean [

	coldStart := aBoolean
]

{ #category : 'accessing' }
CoBenchmarkResult >> completionText [

	^ completionText ifNil: [ '' ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> completionText: aString [

	completionText := aString
]

{ #category : 'accessing' }
CoBenchmarkResult >> completionTokens [

	^ completionTokens ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> completionTokens: anInteger [

	completionTokens := anInteger
]

{ #category : 'accessing' }
CoBenchmarkResult >> contextSizeBytes [

	^ contextSizeBytes ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> contextSizeBytes: anInteger [

	contextSizeBytes := anInteger
]

{ #category : 'accessing' }
CoBenchmarkResult >> contextSizeChars [

	^ contextSizeChars ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> contextSizeChars: anInteger [

	contextSizeChars := anInteger
]

{ #category : 'accessing' }
CoBenchmarkResult >> contextStrategy [

	^ contextStrategy ifNil: [ 'default' ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> contextStrategy: aString [

	contextStrategy := aString
]

{ #category : 'export' }
CoBenchmarkResult >> csvHeader [

	^ #('model' 'scenario' 'run' 'success' 'cold_start' 'context_strategy'
	     'num_ctx' 'num_predict' 'temperature'
	     'context_size_chars' 'context_size_bytes' 'prefix_size_chars' 'suffix_size_chars'
	     'total_prompt_size_chars' 'estimated_prompt_tokens'
	     'prompt_tokens' 'completion_tokens'
	     'total_time_s' 'prompt_eval_time_s' 'eval_time_s' 'tokens_per_second'
	     'error')
]

{ #category : 'accessing' }
CoBenchmarkResult >> errorMessage [

	^ errorMessage ifNil: [ '' ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> errorMessage: aString [

	errorMessage := aString
]

{ #category : 'derived' }
CoBenchmarkResult >> estimatedPromptTokens [


	"Rough estimate: 1 token ~ 4 chars for code"
	^ (self contextSizeChars + self prefixSizeChars + self suffixSizeChars) / 4.0
]

{ #category : 'accessing' }
CoBenchmarkResult >> evalTimeSeconds [

	^ evalTimeSeconds ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> evalTimeSeconds: aNumber [

	evalTimeSeconds := aNumber
]

{ #category : 'accessing' }
CoBenchmarkResult >> model [

	^ model ifNil: [ '' ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> model: aString [

	model := aString
]

{ #category : 'accessing' }
CoBenchmarkResult >> numCtx [ 

	^ numCtx ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> numCtx: anInteger [

	numCtx := anInteger
]

{ #category : 'accessing' }
CoBenchmarkResult >> numPredict [

	^ numPredict ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> numPredict: anInteger [

	numPredict := anInteger
]

{ #category : 'accessing' }
CoBenchmarkResult >> prefixSizeChars [

	^ prefixSizeChars ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> prefixSizeChars: anInteger [

	prefixSizeChars := anInteger
]

{ #category : 'accessing' }
CoBenchmarkResult >> promptEvalTimeSeconds [ 

	^ promptEvalTimeSeconds ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> promptEvalTimeSeconds: aNumber [

	promptEvalTimeSeconds := aNumber
]

{ #category : 'accessing' }
CoBenchmarkResult >> promptText [

	^ promptText ifNil: [ '' ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> promptText: aString [

	promptText := aString
]

{ #category : 'accessing' }
CoBenchmarkResult >> promptTokens [

	^ promptTokens ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> promptTokens: anInteger [ 

	promptTokens := anInteger
]

{ #category : 'accessing' }
CoBenchmarkResult >> runIndex [

	^ runIndex ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> runIndex: anInteger [

	runIndex := anInteger
]

{ #category : 'private' }
CoBenchmarkResult >> safeNumber: aDict key: aKey [


	| value |
	value := aDict at: aKey ifAbsent: [ aDict at: aKey asString ifAbsent: [ 0 ] ].
	^ value ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> scenario [

	^ scenario ifNil: [ '' ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> scenario: aString [ 

	scenario := aString
]

{ #category : 'accessing' }
CoBenchmarkResult >> success [

	^ success ifNil: [ false ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> success: aBoolean [ 

	success := aBoolean
]

{ #category : 'accessing' }
CoBenchmarkResult >> suffixSizeChars [

	^ suffixSizeChars ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> suffixSizeChars: anInteger [

	suffixSizeChars := anInteger
]

{ #category : 'accessing' }
CoBenchmarkResult >> temperature [

	^ temperature ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> temperature: aNumber [

	temperature := aNumber
]

{ #category : 'accessing' }
CoBenchmarkResult >> timestamp [

	^ timestamp
]

{ #category : 'accessing' }
CoBenchmarkResult >> timestamp: aDateAndTime [

	timestamp := aDateAndTime
]

{ #category : 'accessing' }
CoBenchmarkResult >> tokensPerSecond [

	^ tokensPerSecond ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> tokensPerSecond: aNumber [ 

	tokensPerSecond := aNumber
]

{ #category : 'derived' }
CoBenchmarkResult >> totalPromptSizeChars [


	^ self contextSizeChars + self prefixSizeChars + self suffixSizeChars
]

{ #category : 'accessing' }
CoBenchmarkResult >> totalTimeSeconds [

	^ totalTimeSeconds ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoBenchmarkResult >> totalTimeSeconds: aNumber [

	totalTimeSeconds := aNumber
]
