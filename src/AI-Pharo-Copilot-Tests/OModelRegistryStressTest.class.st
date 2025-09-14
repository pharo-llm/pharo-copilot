Class {
	#name : 'OModelRegistryStressTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
OModelRegistryStressTest >> testMassiveModelRegistry [
	| registry |
	registry := OModelRegistry new.
	
	"Simulate adding many models programmatically"
	1 to: 100 do: [ :i |
		| spec |
		spec := OModelSpec 
			family: 'model', i asString
			tag: 'v', i asString
			label: 'Model ', i asString.
		registry byFullName at: spec fullName put: spec.
		registry byLabel at: spec label put: spec ].
	
	self assert: registry byFullName size equals: 100.
	self assert: registry byLabel size equals: 100.
	self assert: registry allSpecs size equals: 100
]

{ #category : 'tests' }
OModelRegistryStressTest >> testRegistryConsistencyAfterMultipleRefreshes [
	| initialSpecs |
	initialSpecs := OModelRegistry current allSpecs.
	
	"Refresh multiple times rapidly"
	5 timesRepeat: [
		| refreshedRegistry |
		refreshedRegistry := OModelRegistry refresh.
		self assert: refreshedRegistry identicalTo: OModelRegistry current ].
		
	"Verify specs are still consistent"
	self assert: OModelRegistry current allSpecs size equals: initialSpecs size
]

{ #category : 'tests' }
OModelRegistryStressTest >> testRegistryWithDuplicateSpecs [
	| registry spec1 spec2 |
	registry := OModelRegistry new.
	
	"Add same model with different objects"
	spec1 := OModelSpec family: 'test' tag: '1' label: 'Test 1'.
	spec2 := OModelSpec family: 'test' tag: '1' label: 'Test 1 Duplicate'.
	
	registry byFullName at: spec1 fullName put: spec1.
	registry byFullName at: spec2 fullName put: spec2.  "Should overwrite"
	
	self assert: registry byFullName size equals: 1.
	self assert: (registry specByFullName: 'test:1') identicalTo: spec2
]

{ #category : 'tests' }
OModelRegistryStressTest >> testSpecLookupPerformance [
	| registry lookupTime |
	registry := OModelRegistry current.
	
	"Measure lookup performance"
	lookupTime := Time millisecondsToRun: [
		1000 timesRepeat: [
			registry specByFullName: 'codellama:7b'.
			registry specByLabel: 'Code Llama 7B' ] ].
	
	"Should be fast (less than 100ms for 2000 lookups)"
	self assert: lookupTime < 100
]
