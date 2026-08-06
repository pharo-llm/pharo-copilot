Class {
	#name : 'CoPCImageCloseSurveyUIManagerDouble',
	#superclass : 'Object',
	#instVars : [
		'ratings',
		'requests'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
CoPCImageCloseSurveyUIManagerDouble >> chooseFrom: labelList values: valueList title: titleString [

	requests add: (Dictionary new
		at: #labels put: labelList;
		at: #values put: valueList;
		at: #title put: titleString;
		yourself).

	ratings isEmpty ifTrue: [ ^ nil ].
	^ ratings removeFirst
]

{ #category : 'initialization' }
CoPCImageCloseSurveyUIManagerDouble >> initialize [

	super initialize.
	ratings := OrderedCollection new.
	requests := OrderedCollection new
]

{ #category : 'accessing' }
CoPCImageCloseSurveyUIManagerDouble >> ratings: aCollection [

	ratings := OrderedCollection withAll: aCollection
]

{ #category : 'accessing' }
CoPCImageCloseSurveyUIManagerDouble >> requests [

	^ requests
]
