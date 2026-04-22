Class {
	#name : 'CoPCBenchmarkContextScenario',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot-Benchmarks',
	#package : 'AI-Pharo-Copilot-Benchmarks'
}

{ #category : 'scenarios' }
CoPCBenchmarkContextScenario class >> allScenarios [
	"Return all context benchmark scenarios combined."
	| all |
	all := Dictionary new.
	all addAll: self contextSizeScenarios.
	all addAll: self contextStrategyScenarios.
	all addAll: self fimQualityScenarios.
	^ all
]

{ #category : 'scenarios' }
CoPCBenchmarkContextScenario class >> contextSizeScenarios [

	"Scenarios that test increasing context window sizes.
	 Each one has the same prefix/suffix but growing context."

	| sizes scenarios basePrefix baseSuffix |
	basePrefix := 'printOn: aStream
	"Print a human-readable representation"
	'.
	baseSuffix := ''.
	sizes := #(0 256 512 1024 2048 4096 8192).

	scenarios := Dictionary new.
	sizes do: [ :size |
		| context name |
		context := self generateContextOfSize: size.
		name := 'context_', size asString, '_chars'.
		scenarios at: name put: (CoPCBenchmarkScenario
			named: name
			prefix: basePrefix
			suffix: baseSuffix
			context: context
			description: 'Context capacity test: ', size asString, ' chars') ].
	^ scenarios
]

{ #category : 'scenarios' }
CoPCBenchmarkContextScenario class >> contextStrategyScenarios [
	"Scenarios comparing full-source vs selectors-only context."

	^ Dictionary new
		at: 'strategy_full_source' put: (CoPCBenchmarkScenario
			named: 'strategy_full_source'
			prefix: 'visitNode: aNode
	"Visit an AST node and collect metrics"
	'
			suffix: ''
			context: (self realisticClassContext)
			description: 'Full source context');
		at: 'strategy_selectors_only' put: (CoPCBenchmarkScenario
			named: 'strategy_selectors_only'
			prefix: 'visitNode: aNode
	"Visit an AST node and collect metrics"
	'
			suffix: ''
			context: (self selectorsOnlyContext)
			description: 'Selectors-only context');
		yourself
]

{ #category : 'scenarios' }
CoPCBenchmarkContextScenario class >> fimQualityScenarios [
	"Scenarios with known expected completions for quality measurement."

	^ Dictionary new
		at: 'fim_accessor' put: (CoPCBenchmarkScenario
			named: 'fim_accessor'
			prefix: 'name
	^ '
			suffix: ''
			context: 'Object subclass: #Person
	instanceVariableNames: ''name age email''
Person >> age
	^ age
Person >> email
	^ email'
			description: 'Simple accessor - expected: name');
		at: 'fim_setter' put: (CoPCBenchmarkScenario
			named: 'fim_setter'
			prefix: 'name: aString
	'
			suffix: ''
			context: 'Object subclass: #Person
	instanceVariableNames: ''name age email''
Person >> age: anInteger
	age := anInteger
Person >> email: aString
	email := aString'
			description: 'Simple setter - expected: name := aString');
		at: 'fim_collection_iterate' put: (CoPCBenchmarkScenario
			named: 'fim_collection_iterate'
			prefix: 'do: aBlock
	"Iterate over all elements"
	'
			suffix: ''
			context: 'SequenceableCollection subclass: #MyList
	instanceVariableNames: ''elements''
MyList >> size
	^ elements size
MyList >> at: anIndex
	^ elements at: anIndex'
			description: 'Collection iteration');
		at: 'fim_with_suffix' put: (CoPCBenchmarkScenario
			named: 'fim_with_suffix'
			prefix: 'between: min and: max
	"Clamp the receiver between min and max"
	'
			suffix: '
	^ self'
			context: 'Number >> max: aNumber
	^ self > aNumber ifTrue: [ self ] ifFalse: [ aNumber ]
Number >> min: aNumber
	^ self < aNumber ifTrue: [ self ] ifFalse: [ aNumber ]'
			description: 'FIM with suffix constraint');
		yourself
]

{ #category : 'context-generation' }
CoPCBenchmarkContextScenario class >> generateContextOfSize: targetSize [
	"Generate realistic Pharo method context of approximately targetSize characters."

	| methods stream currentSize counter |
	targetSize = 0 ifTrue: [ ^ '' ].
	methods := self syntheticMethods.
	stream := WriteStream on: String new.
	currentSize := 0.

	stream nextPutAll: 'Object subclass: #BenchmarkTarget'; cr.
	stream nextPutAll: '	instanceVariableNames: ''data cache config'''; cr; cr.
	currentSize := stream position.

	methods do: [ :method |
		currentSize >= targetSize ifTrue: [ ^ stream contents copyFrom: 1 to: (targetSize min: stream contents size) ].
		stream nextPutAll: method; cr; cr.
		currentSize := stream position ].

	counter := 1.
	[ currentSize < targetSize ] whileTrue: [
		methods do: [ :method |
			| varied |
			currentSize >= targetSize ifTrue: [ ^ stream contents copyFrom: 1 to: (targetSize min: stream contents size) ].
			varied := method copyReplaceAll: 'method' with: 'method', counter asString.
			stream nextPutAll: varied; cr; cr.
			currentSize := stream position.
			counter := counter + 1 ] ].

	^ stream contents copyFrom: 1 to: (targetSize min: stream contents size)
]

{ #category : 'context-generation' }
CoPCBenchmarkContextScenario class >> realisticClassContext [
	^ 'RBProgramNode subclass: #ASTMetricsVisitor
	instanceVariableNames: ''methodCount messageCount assignmentCount blockDepth maxBlockDepth''

ASTMetricsVisitor >> initialize
	super initialize.
	methodCount := 0.
	messageCount := 0.
	assignmentCount := 0.
	blockDepth := 0.
	maxBlockDepth := 0

ASTMetricsVisitor >> visitMethodNode: aMethodNode
	methodCount := methodCount + 1.
	aMethodNode body acceptVisitor: self

ASTMetricsVisitor >> visitMessageNode: aMessageNode
	messageCount := messageCount + 1.
	aMessageNode arguments do: [ :arg | arg acceptVisitor: self ]

ASTMetricsVisitor >> visitAssignmentNode: anAssignmentNode
	assignmentCount := assignmentCount + 1.
	anAssignmentNode value acceptVisitor: self

ASTMetricsVisitor >> visitBlockNode: aBlockNode
	blockDepth := blockDepth + 1.
	maxBlockDepth := maxBlockDepth max: blockDepth.
	aBlockNode body acceptVisitor: self.
	blockDepth := blockDepth - 1

ASTMetricsVisitor >> report
	^ Dictionary new
		at: #methods put: methodCount;
		at: #messages put: messageCount;
		at: #assignments put: assignmentCount;
		at: #maxBlockDepth put: maxBlockDepth;
		yourself

ASTMetricsVisitor >> complexity
	^ messageCount + (assignmentCount * 2) + (maxBlockDepth * 3)'
]

{ #category : 'context-generation' }
CoPCBenchmarkContextScenario class >> selectorsOnlyContext [

	^ 'ASTMetricsVisitor: initialize visitMethodNode: visitMessageNode: visitAssignmentNode: visitBlockNode: report complexity'
]

{ #category : 'context-generation' }
CoPCBenchmarkContextScenario class >> syntheticMethods [

	^ #(
		'BenchmarkTarget >> initialize
	super initialize.
	data := OrderedCollection new.
	cache := Dictionary new.
	config := Dictionary new'
		'BenchmarkTarget >> add: anObject
	data add: anObject.
	cache removeAll.
	^ anObject'
		'BenchmarkTarget >> remove: anObject
	data remove: anObject ifAbsent: [ ^ nil ].
	cache removeAll.
	^ anObject'
		'BenchmarkTarget >> size
	^ data size'
		'BenchmarkTarget >> includes: anObject
	^ data includes: anObject'
		'BenchmarkTarget >> do: aBlock
	data do: aBlock'
		'BenchmarkTarget >> collect: aBlock
	^ data collect: aBlock'
		'BenchmarkTarget >> select: aBlock
	^ data select: aBlock'
		'BenchmarkTarget >> reject: aBlock
	^ data reject: aBlock'
		'BenchmarkTarget >> detect: aBlock ifNone: exceptionBlock
	^ data detect: aBlock ifNone: exceptionBlock'
		'BenchmarkTarget >> configAt: aKey
	^ config at: aKey ifAbsent: [ nil ]'
		'BenchmarkTarget >> configAt: aKey put: aValue
	config at: aKey put: aValue.
	^ aValue'
		'BenchmarkTarget >> cachedResultFor: aKey
	^ cache at: aKey ifAbsent: [
		| result |
		result := self computeResultFor: aKey.
		cache at: aKey put: result.
		result ]'
		'BenchmarkTarget >> computeResultFor: aKey
	^ data inject: 0 into: [ :sum :each | sum + (each perform: aKey) ]'
		'BenchmarkTarget >> printOn: aStream
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: data size;
		nextPutAll: '' items)'';
		yourself'
	)
]
