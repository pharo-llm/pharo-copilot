Class {
	#name : 'CoBenchmarkScenario',
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
CoBenchmarkScenario class >> defaultScenarios [
	self shouldBeImplemented.
]

{ #category : 'as yet unclassified' }
CoBenchmarkScenario class >> named: aName prefix: prefixString suffix: suffixString context: contextString description: descriptionString [

	^ self new
		name: aName;
		prefix: prefixString;
		suffix: suffixString;
		context: contextString;
		description: descriptionString;
		yourself
]

{ #category : 'accessing' }
CoBenchmarkScenario >> context [

	^ context
]

{ #category : 'accessing' }
CoBenchmarkScenario >> context: aString [

	context := aString
]

{ #category : 'accessing' }
CoBenchmarkScenario >> description [

	^ description
]

{ #category : 'accessing' }
CoBenchmarkScenario >> description: aString [

	description := aString
]

{ #category : 'accessing' }
CoBenchmarkScenario >> name [

	^ name
]

{ #category : 'accessing' }
CoBenchmarkScenario >> name: aString [

	name := aString
]

{ #category : 'accessing' }
CoBenchmarkScenario >> prefix [

	^ prefix

]

{ #category : 'accessing' }
CoBenchmarkScenario >> prefix: aString [

	prefix := aString

]

{ #category : 'accessing' }
CoBenchmarkScenario >> suffix [

	^ suffix
]

{ #category : 'accessing' }
CoBenchmarkScenario >> suffix: aString [

	suffix := aString
]
