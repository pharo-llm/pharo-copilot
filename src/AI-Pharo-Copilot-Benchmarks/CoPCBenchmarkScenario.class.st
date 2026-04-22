Class {
	#name : 'CoPCBenchmarkScenario',
	#superclass : 'Object',
	#instVars : [
		'name',
		'prefix',
		'suffix',
		'context',
		'description'
	],
	#category : 'AI-Pharo-Copilot-Benchmarks',
	#package : 'AI-Pharo-Copilot-Benchmarks'
}

{ #category : 'scenarios' }
CoPCBenchmarkScenario class >> defaultScenarios [
	self shouldBeImplemented.
]

{ #category : 'as yet unclassified' }
CoPCBenchmarkScenario class >> named: aName prefix: prefixString suffix: suffixString context: contextString description: descriptionString [

	^ self new
		name: aName;
		prefix: prefixString;
		suffix: suffixString;
		context: contextString;
		description: descriptionString;
		yourself
]

{ #category : 'accessing' }
CoPCBenchmarkScenario >> context [

	^ context
]

{ #category : 'accessing' }
CoPCBenchmarkScenario >> context: aString [

	context := aString
]

{ #category : 'accessing' }
CoPCBenchmarkScenario >> description [

	^ description
]

{ #category : 'accessing' }
CoPCBenchmarkScenario >> description: aString [

	description := aString
]

{ #category : 'accessing' }
CoPCBenchmarkScenario >> name [

	^ name
]

{ #category : 'accessing' }
CoPCBenchmarkScenario >> name: aString [

	name := aString
]

{ #category : 'accessing' }
CoPCBenchmarkScenario >> prefix [

	^ prefix

]

{ #category : 'accessing' }
CoPCBenchmarkScenario >> prefix: aString [

	prefix := aString

]

{ #category : 'accessing' }
CoPCBenchmarkScenario >> suffix [

	^ suffix
]

{ #category : 'accessing' }
CoPCBenchmarkScenario >> suffix: aString [

	suffix := aString
]
