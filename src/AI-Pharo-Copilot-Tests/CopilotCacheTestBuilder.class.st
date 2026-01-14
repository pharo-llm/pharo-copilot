Class {
	#name : 'CopilotCacheTestBuilder',
	#superclass : 'CoPharoCopilotResultSetBuilder',
	#instVars : [
		'methodSourcesCallCount'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'initialization' }
CopilotCacheTestBuilder >> classDefinition: classDef instanceMethods: inst classMethods: cls [

	^ classDef , '|' , inst , '|' , cls
]

{ #category : 'initialization' }
CopilotCacheTestBuilder >> classStampFor: aBehavior [

	"Constant stamp so caching should hit."
	^ #(123 456)
]

{ #category : 'initialization' }
CopilotCacheTestBuilder >> deferUI: aBlock [

	^ aBlock value
]

{ #category : 'initialization' }
CopilotCacheTestBuilder >> initialize [

	super initialize.
	methodSourcesCallCount := 0.
]

{ #category : 'initialization' }
CopilotCacheTestBuilder >> methodSourcesCallCount [

	^ methodSourcesCallCount
]

{ #category : 'initialization' }
CopilotCacheTestBuilder >> methodSourcesFor: aBehavior around: aSelector limit: limitInteger [
	methodSourcesCallCount := methodSourcesCallCount + 1.
	^ 'METHODS'
]

{ #category : 'initialization' }
CopilotCacheTestBuilder >> safeDefinitionStringFor: aBehavior [

	^ 'DEF'
]
