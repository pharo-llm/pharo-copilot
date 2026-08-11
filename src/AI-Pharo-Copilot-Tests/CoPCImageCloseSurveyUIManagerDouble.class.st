Class {
	#name : 'CoPCImageCloseSurveyUIManagerDouble',
	#superclass : 'Object',
	#instVars : [
		'ratings',
		'comments',
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

{ #category : 'accessing' }
CoPCImageCloseSurveyUIManagerDouble >> comments: aCollection [

	comments := OrderedCollection withAll: aCollection
]

{ #category : 'initialization' }
CoPCImageCloseSurveyUIManagerDouble >> initialize [

	super initialize.
	ratings := OrderedCollection new.
	comments := OrderedCollection new.
	requests := OrderedCollection new
]

{ #category : 'accessing' }
CoPCImageCloseSurveyUIManagerDouble >> multiLineRequest: requestString initialAnswer: initialAnswerString answerHeight: answerHeight [

	requests add: (Dictionary new
		at: #request put: requestString;
		at: #initialAnswer put: initialAnswerString;
		at: #answerHeight put: answerHeight;
		yourself).

	comments isEmpty ifTrue: [ ^ '' ].
	^ comments removeFirst
]

{ #category : 'accessing' }
CoPCImageCloseSurveyUIManagerDouble >> request: requestString initialAnswer: initialAnswerString title: titleString [

	requests add: (Dictionary new
		at: #request put: requestString;
		at: #initialAnswer put: initialAnswerString;
		at: #title put: titleString;
		yourself).

	comments isEmpty ifTrue: [ ^ '' ].
	^ comments removeFirst
]

{ #category : 'accessing' }
CoPCImageCloseSurveyUIManagerDouble >> ratings: aCollection [

	ratings := OrderedCollection withAll: aCollection
]

{ #category : 'accessing' }
CoPCImageCloseSurveyUIManagerDouble >> requests [

	^ requests
]
