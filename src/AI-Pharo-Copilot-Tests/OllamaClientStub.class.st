"
Mock
"
Class {
	#name : 'OllamaClientStub',
	#superclass : 'Object',
	#instVars : [
		'response',
		'responseBlock',
		'callCount',
		'lastRequestedModel',
		'modelsResponse',
		'modelsResponses'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
OllamaClientStub >> callCount [ 
    ^ callCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
OllamaClientStub >> defaultModelsResponse [

	^ Dictionary new
		  at: #models put: { (Dictionary new
				   at: #name put: (CopilotSettings modelName ifNil: [OTestModelSupport mockModelName ]);
				   yourself) };
		  yourself
]

{ #category : 'accessing' }
OllamaClientStub >> lastRequestedModel [
    ^ lastRequestedModel
]

{ #category : 'accessing' }
OllamaClientStub >> listModels [
(modelsResponses notNil and: [ modelsResponses isEmpty not ]) ifTrue: [
        ^ modelsResponses removeFirst
    ].
	^ modelsResponse ifNil: [ self defaultModelsResponse ]
]

{ #category : 'accessing' }
OllamaClientStub >> showModelNamed: aModelName [
    lastRequestedModel := aModelName.
    callCount := self callCount + 1.
    responseBlock ifNotNil: [ ^ responseBlock value: aModelName ].
    ^ response
]

{ #category : 'accessing' }
OllamaClientStub >> withModelsResponse: anObject [

	modelsResponse := anObject.
modelsResponses := nil.
    ^ self
]

{ #category : 'accessing' }
OllamaClientStub >> withModelsResponses: aCollection [
    modelsResponses := OrderedCollection withAll: aCollection.
    modelsResponse := nil.
^self
]

{ #category : 'accessing' }
OllamaClientStub >> withResponse: anObject [
    response := anObject.
    responseBlock := nil.
    ^ self
]

{ #category : 'accessing' }
OllamaClientStub >> withResponseBlock: aBlockClosure [
    responseBlock := aBlockClosure.
    response := nil.
    ^ self
]
