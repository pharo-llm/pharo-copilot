Class {
	#name : 'OModelSpecTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
OModelSpecTest >> testCreationWithNilTag [
	| spec |
	spec := OModelSpec family: 'test' tag: nil label: 'Test Model'.
	
	self assert: spec family equals: 'test'.
	self assert: spec tag isNil.
	self assert: spec label equals: 'Test Model'.
	self assert: spec fullName equals: 'test'
]

{ #category : 'tests' }
OModelSpecTest >> testCreationWithTag [
	| spec |
	spec := OModelSpec family: 'test' tag: '7b' label: 'Test Model 7B'.
	
	self assert: spec family equals: 'test'.
	self assert: spec tag equals: '7b'.
	self assert: spec label equals: 'Test Model 7B'.
	self assert: spec fullName equals: 'test:7b'
]

{ #category : 'tests' }
OModelSpecTest >> testFamilyAccessor [

    | spec |
    spec := OModelSpec family: 'abc' tag: nil label: 'ABC'.
    self assert: spec family equals: 'abc'.
]

{ #category : 'tests' }
OModelSpecTest >> testFamilySetter [

    | spec |
    spec := OModelSpec family: 'abc' tag: nil label: 'ABC'.
    spec family: 'xyz'.
    self assert: spec family equals: 'xyz'.
]

{ #category : 'tests' }
OModelSpecTest >> testFullNameWithEmptyTag [ 
	| spec |
	spec := OModelSpec family: 'test' tag: '' label: 'Test'.
	
	"Empty string should behave like nil for tag"
	self assert: spec fullName equals: 'test:'
]

{ #category : 'tests' }
OModelSpecTest >> testFullNameWithTag [ 

    | spec |
    spec := OModelSpec family: 'foo' tag: 'bar' label: 'Foo Bar'.
    self assert: spec fullName equals: 'foo:bar'.
]

{ #category : 'tests' }
OModelSpecTest >> testFullNameWithoutTag [

    | spec |
    spec := OModelSpec family: 'foo' tag: nil label: 'Foo'.
    self assert: spec fullName equals: 'foo'.
]

{ #category : 'tests' }
OModelSpecTest >> testLabelAccessor [

    | spec |
    spec := OModelSpec family: 'abc' tag: nil label: 'ABC'.
    self assert: spec label equals: 'ABC'.
]

{ #category : 'tests' }
OModelSpecTest >> testLabelSetter [

    | spec |
    spec := OModelSpec family: 'abc' tag: nil label: 'ABC'.
    spec label: 'XYZ'.
    self assert: spec label equals: 'XYZ'.
]

{ #category : 'tests' }
OModelSpecTest >> testTagAccessor [

    | spec |
    spec := OModelSpec family: 'abc' tag: 'def' label: 'ABC'.
    self assert: spec tag equals: 'def'.
]

{ #category : 'tests' }
OModelSpecTest >> testTagSetter [
	| spec |
	spec := OModelSpec family: 'test' tag: 'old' label: 'Test'.
	spec tag: 'new'.
	
	self assert: spec tag equals: 'new'.
	self assert: spec fullName equals: 'test:new'
]
