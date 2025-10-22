Class {
	#name : 'OTestModelSupport',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'as yet unclassified' }
OTestModelSupport class >> beginMockModels [

	| context |
	context := Dictionary new
		           at: #modelsFetcher put: OModelRegistry modelsFetcher;
		           at: #modelName put: CopilotSettings modelName;
		           yourself.
	CopilotSettings clearCachedModelMetadata.
	CopilotSettings modelName: self mockModelName.
	OModelRegistry modelsFetcher: [ self mockModelsResponse ].
	OModelRegistry refresh.
	^ context
]

{ #category : 'as yet unclassified' }
OTestModelSupport class >> endMockModels: context [

	| previousFetcher |
	context ifNil: [ ^ self ].
	previousFetcher := context at: #modelsFetcher ifAbsent: [ nil ].
	OModelRegistry modelsFetcher: previousFetcher.
	OModelRegistry reset.
	    CopilotSettings modelName: ((context at: #modelName ifAbsent: [ nil ])
            ifNil: [ CopilotSettings nullModelFullName ]).
	CopilotSettings clearCachedModelMetadata
]

{ #category : 'as yet unclassified' }
OTestModelSupport class >> mockModelLabel [

    ^ 'Mock Model'
]

{ #category : 'as yet unclassified' }
OTestModelSupport class >> mockModelName [

    ^ 'mock:model'
]

{ #category : 'as yet unclassified' }
OTestModelSupport class >> mockModelProLabel [

    ^ 'Mock Model Pro'
]

{ #category : 'as yet unclassified' }
OTestModelSupport class >> mockModelProName [

    ^ 'mock:model-pro'
]

{ #category : 'as yet unclassified' }
OTestModelSupport class >> mockModelsResponse [

    ^ Dictionary new
        at: #models put: {
            Dictionary new
                at: #name put: self mockModelName;
                yourself.
            Dictionary new
                at: #name put: self mockModelProName;
                yourself };
        yourself
]
