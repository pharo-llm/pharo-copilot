Class {
	#name : 'CoPCTestEpMethodChange',
	#superclass : 'Object',
	#instVars : [
		'behaviorAffectedName',
		'methodAffectedSelector',
		'affectedPackageName'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'instance creation' }
CoPCTestEpMethodChange class >> behavior: behaviorNameString selector: selectorSymbol package: packageNameString [

	^ self new
		behaviorAffectedName: behaviorNameString;
		methodAffectedSelector: selectorSymbol;
		affectedPackageName: packageNameString;
		yourself
]

{ #category : 'accessing' }
CoPCTestEpMethodChange >> affectedPackageName [

	^ affectedPackageName
]

{ #category : 'accessing' }
CoPCTestEpMethodChange >> affectedPackageName: aString [

	affectedPackageName := aString
]

{ #category : 'accessing' }
CoPCTestEpMethodChange >> behaviorAffectedName [

	^ behaviorAffectedName
]

{ #category : 'accessing' }
CoPCTestEpMethodChange >> behaviorAffectedName: aString [

	behaviorAffectedName := aString
]

{ #category : 'testing' }
CoPCTestEpMethodChange >> isEpMethodChange [

	^ true
]

{ #category : 'accessing' }
CoPCTestEpMethodChange >> methodAffectedSelector [

	^ methodAffectedSelector
]

{ #category : 'accessing' }
CoPCTestEpMethodChange >> methodAffectedSelector: aSymbol [

	methodAffectedSelector := aSymbol
]

