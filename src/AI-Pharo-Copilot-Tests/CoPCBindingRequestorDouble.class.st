Class {
	#name : 'CoPCBindingRequestorDouble',
	#superclass : 'Object',
	#instVars : [
		'bindings'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
CoPCBindingRequestorDouble >> bind: aName to: anObject [

	bindings at: aName asString put: (aName asString -> anObject)
]

{ #category : 'accessing' }
CoPCBindingRequestorDouble >> bindingOf: aName [

	^ bindings at: aName asString ifAbsent: [ nil ]
]

{ #category : 'accessing' }
CoPCBindingRequestorDouble >> hasBindingOf: aName [

	^ bindings includesKey: aName asString
]

{ #category : 'initialization' }
CoPCBindingRequestorDouble >> initialize [

	super initialize.
	bindings := Dictionary new
]

{ #category : 'accessing' }
CoPCBindingRequestorDouble >> model [

	^ self
]

{ #category : 'accessing' }
CoPCBindingRequestorDouble >> variableBindings [

	^ bindings
]
