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
CoPCImageCloseSurveyUIManagerDouble >> imageCloseSurveyFormWithSpec: surveySpec [

	| requiredAnswerCount response ratingAnswers task experience comment |
	requests add: (Dictionary new
		at: #surveyFormSpec put: surveySpec;
		yourself).

	requiredAnswerCount := CoPCImageCloseSurvey surveyQuestions size + 2.
	ratings size < requiredAnswerCount ifTrue: [ ^ nil ].

	ratingAnswers := Dictionary new.
	CoPCImageCloseSurvey surveyQuestions do: [ :question |
		ratingAnswers at: question key put: ratings removeFirst ].
	task := ratings removeFirst.
	experience := ratings removeFirst.
	comment := comments isEmpty
		ifTrue: [ '' ]
		ifFalse: [ comments removeFirst ].

	response := Dictionary new
		at: #ratings put: ratingAnswers;
		at: #task put: task;
		at: #experienceYears put: experience;
		at: #feedbackComment put: comment;
		yourself.
	^ response
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
