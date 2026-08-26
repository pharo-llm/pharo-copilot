Class {
	#name : 'CoPCTestEpClassChange',
	#superclass : 'Object',
	#instVars : [
		'affectedName',
		'affectedPackageName'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'instance creation' }
CoPCTestEpClassChange class >> affectedName: affectedNameString package: packageNameString [

	^ self new
		affectedName: affectedNameString;
		affectedPackageName: packageNameString;
		yourself
]

{ #category : 'accessing' }
CoPCTestEpClassChange >> affectedName [

	^ affectedName
]

{ #category : 'accessing' }
CoPCTestEpClassChange >> affectedName: aString [

	affectedName := aString
]

{ #category : 'accessing' }
CoPCTestEpClassChange >> affectedPackageName [

	^ affectedPackageName
]

{ #category : 'accessing' }
CoPCTestEpClassChange >> affectedPackageName: aString [

	affectedPackageName := aString
]

{ #category : 'testing' }
CoPCTestEpClassChange >> isEpMethodChange [

	^ false
]

