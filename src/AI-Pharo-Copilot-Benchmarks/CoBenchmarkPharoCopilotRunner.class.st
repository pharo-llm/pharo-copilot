Class {
	#name : 'CoBenchmarkPharoCopilotRunner',
	#superclass : 'Object',
	#instVars : [
		'client',
		'options',
		'template',
		'numPredict',
		'coldStart',
		'scenarios',
		'results'
	],
	#category : 'AI-Pharo-Copilot-Benchmarks',
	#package : 'AI-Pharo-Copilot-Benchmarks'
}

{ #category : 'accessing - defaults' }
CoBenchmarkPharoCopilotRunner class >> defaultConfiguration [

	^ Dictionary new
		at: #models put: #('qwen2.5-coder:3b');
		at: #scenarios put: #('all');
		at: #runs put: 3;
		at: #numPredict put: 150;
		at: #template put: nil;
		at: #coldStart put: false;
		at: #outputCsv put: 'benchmark_results.csv';
		at: #outputCompletions put: 'benchmark_completions.txt';
		yourself
]

{ #category : 'as yet unclassified' }
CoBenchmarkPharoCopilotRunner class >> defaultTemplate [

	^ 'You are a Pharo Smalltalk code completion assistant. Complete the code at the cursor position.\n\nContext:\n<|fim_context|>\n\nPrefix:\n<|fim_prefix|>\n\nSuffix:\n<|fim_suffix|>\n\nComplete the code at <|fim_middle|>:'
]

{ #category : 'accessing - defaults' }
CoBenchmarkPharoCopilotRunner class >> runWithConfiguration: aDictionary [

	| runner results outputCsv outputCompletions |
	runner := self new.
	results := runner
		runForModels: (aDictionary at: #models)
		scenarios: (aDictionary at: #scenarios)
		runs: (aDictionary at: #runs)
		numPredict: (aDictionary at: #numPredict)
		template: (aDictionary at: #template)
		coldStart: (aDictionary at: #coldStart).

	outputCsv := FileLocator workingDirectory / (aDictionary at: #outputCsv).
	outputCompletions := FileLocator workingDirectory / (aDictionary at: #outputCompletions).
	runner saveCsvTo: outputCsv.
	runner saveCompletionsTo: outputCompletions.

	^ results
]

{ #category : 'as yet unclassified' }
CoBenchmarkPharoCopilotRunner >> availableScenarioNames [

	^ scenarios keys asSortedCollection
]

{ #category : 'as yet unclassified' }
CoBenchmarkPharoCopilotRunner >> buildPromptFor: aScenario [

	| prompt safeTemplate |
	safeTemplate := template ifNil: [ self class defaultTemplate ].
	prompt := safeTemplate copyReplaceAll: '<|fim_prefix|>' with: aScenario prefix.
	prompt := prompt copyReplaceAll: '<|fim_suffix|>' with: aScenario suffix.
	prompt := prompt copyReplaceAll: '<|fim_context|>' with: aScenario context.
	prompt := prompt copyReplaceAll: '<|fim_middle|>' with: ''.

	^ prompt
]

{ #category : 'as yet unclassified' }
CoBenchmarkPharoCopilotRunner >> clearModelCacheFor: modelNameString [

	[ client
		transport
			postJsonAt: 'api/generate'
			body: (Dictionary new
				at: #model put: modelNameString;
				at: #keep_alive put: 0;
				yourself)
	] on: Error do: [ :ex | ex return ]
]

{ #category : 'as yet unclassified' }
CoBenchmarkPharoCopilotRunner >> defaultOptions [

	^ Dictionary new
		at: #num_predict put: (numPredict ifNil: [ 150 ]);
		at: #num_ctx put: 8192;
		at: #temperature put: 0.2;
		at: #top_p put: 0.95;
		yourself
]

{ #category : 'as yet unclassified' }
CoBenchmarkPharoCopilotRunner >> ensureModelAvailable: modelNameString [

	| modelsResponse modelNames |
	modelsResponse := self listAvailableModels.
	modelNames := self modelNamesFrom: modelsResponse.
	(modelNames includes: modelNameString) ifTrue: [ ^ true ].

	^ self pullModelNamed: modelNameString
]

{ #category : 'as yet unclassified' }
CoBenchmarkPharoCopilotRunner >> generateCompletionFor: aScenario model: modelNameString [

	| prompt payload startMillis response doneMillis promptEval evalDuration promptTokens completionTokens completionText |
	prompt := self buildPromptFor: aScenario.
	payload := Dictionary new
		at: #model put: modelNameString;
		at: #prompt put: prompt;
		at: #stream put: false;
		at: #keep_alive put: '10m';
		at: #options put: options;
		yourself.

	startMillis := Time millisecondClockValue.
	[
		response := client transport postJsonAt: 'api/generate' body: payload.
		doneMillis := Time millisecondClockValue.

		promptEval := (self numberFromResponse: response key: #prompt_eval_duration) / 1e9.
		evalDuration := (self numberFromResponse: response key: #eval_duration) / 1e9.
		promptTokens := self numberFromResponse: response key: #prompt_eval_count.
		completionTokens := self numberFromResponse: response key: #eval_count.
		completionText := self responseTextFrom: response.

		^ Dictionary new
			at: #ttft put: nil;
			at: #total_time put: (doneMillis - startMillis) / 1000.0;
			at: #prompt_eval_time put: promptEval;
			at: #eval_time put: evalDuration;
			at: #prompt_tokens put: promptTokens;
			at: #completion_tokens put: completionTokens;
			at: #tokens_per_second put: (evalDuration > 0 ifTrue: [ completionTokens / evalDuration ] ifFalse: [ 0 ]);
			at: #completion_text put: completionText;
			at: #success put: true;
			at: #error put: nil;
			yourself
	] on: Error do: [ :ex |
		doneMillis := Time millisecondClockValue.
		^ Dictionary new
			at: #ttft put: nil;
			at: #total_time put: (doneMillis - startMillis) / 1000.0;
			at: #prompt_eval_time put: nil;
			at: #eval_time put: nil;
			at: #prompt_tokens put: nil;
			at: #completion_tokens put: nil;
			at: #tokens_per_second put: nil;
			at: #completion_text put: nil;
			at: #success put: false;
			at: #error put: ex description;
			yourself ]
]

{ #category : 'as yet unclassified' }
CoBenchmarkPharoCopilotRunner >> initialize [

	super initialize.
	client := OllamaClient new.
	options := Dictionary new.
	scenarios :=CoBenchmarkScenarioCatalog defaultScenarios.
	results := OrderedCollection new
]

{ #category : 'as yet unclassified' }
CoBenchmarkPharoCopilotRunner >> listAvailableModels [

	^ client listModels
]

{ #category : 'as yet unclassified' }
CoBenchmarkPharoCopilotRunner >> modelNamesFrom: modelsResponse [

	| modelList |
	modelsResponse ifNil: [ ^ #() ].
	modelList := modelsResponse at: #models ifAbsent: [ modelsResponse at: 'models' ifAbsent: [ #() ] ].
	^ modelList collect: [ :each | each at: #name ifAbsent: [ each at: 'name' ifAbsent: [ '' ] ] ]
]

{ #category : 'as yet unclassified' }
CoBenchmarkPharoCopilotRunner >> numberFromResponse: response key: keySymbol [

	| value |
	value := response at: keySymbol ifAbsent: [ response at: keySymbol asString ifAbsent: [ 0 ] ].
	^ value ifNil: [ 0 ] ifNotNil: [ value ]
]

{ #category : 'as yet unclassified' }
CoBenchmarkPharoCopilotRunner >> pullModelNamed: modelNameString [

	| response |
	[
		response := client transport
			postJsonAt: 'api/pull'
			body: (Dictionary new
				at: #name put: modelNameString;
				at: #stream put: false;
				yourself)
	] on: Error do: [ :ex | ^ false ].

	^ response notNil
]

{ #category : 'as yet unclassified' }
CoBenchmarkPharoCopilotRunner >> responseTextFrom: response [

	response isNil ifTrue: [ ^ '' ].
	^ response at: #response ifAbsent: [ response at: 'response' ifAbsent: [ '' ] ]
]

{ #category : 'as yet unclassified' }
CoBenchmarkPharoCopilotRunner >> runForModels: modelNames scenarios: scenarioNames runs: runCount numPredict: maxTokens template: templateString coldStart: coldStartFlag [

	| scenarioKeys selectedScenarios |
	results removeAll.
	numPredict := maxTokens.
	template := templateString.
	coldStart := coldStartFlag.
	options := self defaultOptions.

	scenarioKeys := scenarioNames ifNil: [ #('all') ].
	selectedScenarios := (scenarioKeys includes: 'all')
		ifTrue: [ self availableScenarioNames ]
		ifFalse: [ scenarioKeys select: [ :each | scenarios includesKey: each ] ].

	modelNames do: [ :modelName |
		(self ensureModelAvailable: modelName)
			ifFalse: [
				selectedScenarios do: [ :scenarioName |
					results add: (Dictionary new
						at: #model put: modelName;
						at: #scenario put: scenarioName;
						at: #run put: 0;
						at: #cold_start put: coldStart;
						at: #success put: false;
						at: #error put: 'Model not available';
						yourself) ] ]
			ifTrue: [
				selectedScenarios do: [ :scenarioName |
					| scenario |
					scenario := scenarios at: scenarioName.
					1 to: runCount do: [ :runIndex |
						| result |
						coldStart ifTrue: [ self clearModelCacheFor: modelName ].
						result := self generateCompletionFor: scenario model: modelName.
						result
							at: #model put: modelName;
							at: #scenario put: scenarioName;
							at: #run put: runIndex;
							at: #cold_start put: coldStart;
							yourself.
						results add: result ] ] ] ].

	^ results
]

{ #category : 'as yet unclassified' }
CoBenchmarkPharoCopilotRunner >> saveCompletionsTo: aFileReference [

	| stream |
	stream := aFileReference writeStream.
	results do: [ :result |
		(result at: #completion_text ifAbsent: [ '' ]) ifNotEmpty: [
			stream
				nextPutAll: (String new: 60 withAll: $=); lf;
				nextPutAll: 'Model: ', (result at: #model) asString; lf;
				nextPutAll: 'Scenario: ', (result at: #scenario) asString; lf;
				nextPutAll: 'Run: ', (result at: #run) asString; lf;
				nextPutAll: (String new: 60 withAll: $=); lf;
				nextPutAll: (result at: #completion_text) asString; lf; lf ] ].
	stream close
]

{ #category : 'as yet unclassified' }
CoBenchmarkPharoCopilotRunner >> saveCsvTo: aFileReference [
	| stream fields |
	
	fields := #(model scenario run cold_start success ttft total_time
	            prompt_eval_time eval_time prompt_tokens completion_tokens
	            tokens_per_second error).

	stream := aFileReference writeStream.

	"Write header"
	stream
		nextPutAll: (String streamContents: [ :s |
			fields
				doWithIndex: [ :field :i |
					i > 1 ifTrue: [ s nextPut: $, ].
					s nextPutAll: field asString ] ]);
		lf.

	"Write rows"
	results do: [ :result |
		stream
			nextPutAll: (String streamContents: [ :s |
				fields
					doWithIndex: [ :field :i |
						i > 1 ifTrue: [ s nextPut: $, ].
						s nextPutAll: ((result at: field ifAbsent: [ '' ]) asString) ] ]);
			lf ].

	stream close

]
