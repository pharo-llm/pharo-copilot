Class {
	#name : 'OModelRegistryTest',
	#superclass : 'CopilotMockModelTestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
OModelRegistryTest >> defaultModelsResponse [

^ OTestModelSupport mockModelsResponse
]

{ #category : 'tests' }
OModelRegistryTest >> setUp [
    super setUp.
    CoPCModelRegistry modelsFetcher: [ self defaultModelsResponse ].
    CoPCModelRegistry refresh
]

{ #category : 'running' }
OModelRegistryTest >> tearDown [
    CoPCModelRegistry modelsFetcher: nil.
    CoPCModelRegistry reset.
    super tearDown
]

{ #category : 'tests' }
OModelRegistryTest >> testAllSpecsReturnsSortedArray [ 
	| registry specs |
	registry := CoPCModelRegistry build.
	specs := registry allSpecs.
	
	self assert: specs isArray.
	self assert: specs size > 0.
	
	"Check sorting by label"
	specs overlappingPairsDo: [ :first :second |
		self assert: first label <= second label ]
]

{ #category : 'tests' }
OModelRegistryTest >> testBuildCreatesFilledRegistry [
	| registry |
	registry := CoPCModelRegistry build.
	
	self assert: ((registry byFullName) isKindOf: Dictionary).
	self assert: ((registry byLabel) isKindOf: Dictionary).
	self assert: registry byFullName size > 0.
	self assert: registry byLabel size > 0
]

{ #category : 'tests' }
OModelRegistryTest >> testCurrentReturnsValidRegistry [
	| registry |
	registry := CoPCModelRegistry current.
	
	self assert: (registry isKindOf: CoPCModelRegistry).
	self assert: registry byFullName notEmpty.
	self assert: registry byLabel notEmpty
]

{ #category : 'tests' }
OModelRegistryTest >> testDomainValuesForSettings [

	| registry domain |
	registry := CoPCModelRegistry build.
	domain := registry domainValuesForSettings.
	self assert: domain size > 0.
	self assert: (domain anySatisfy: [:assoc | assoc key = OTestModelSupport mockModelLabel and: [assoc value = OTestModelSupport mockModelName]]).
]

{ #category : 'tests' }
OModelRegistryTest >> testDomainValuesForSettingsReturnAssociations [

    | registry domain |
    registry := CoPCModelRegistry build.
    domain := registry domainValuesForSettings.
    self assert: (domain allSatisfy: [ :assoc | assoc isKindOf: Association ]).
]

{ #category : 'tests' }
OModelRegistryTest >> testDomainValuesForSettingsReturnsAssociations [ 
	| registry domain |
	registry := CoPCModelRegistry build.
	domain := registry domainValuesForSettings.
	
	self assert: domain isCollection.
	domain do: [ :assoc |
		self assert: (assoc isKindOf: Association).
		self assert: assoc key isString.
		self assert: assoc value isString ]
]

{ #category : 'tests' }
OModelRegistryTest >> testRebuildHandlesEmptyPragmas [
	"Test rebuilding works even when no pragmas are found"
	| registry oldMethod |
	registry := CoPCModelRegistry new.
	
	"This should not fail even if pragma lookup fails"
	registry rebuild.
	
	self assert: ((registry byFullName) isKindOf: Dictionary).
	self assert: ((registry byLabel) isKindOf: Dictionary)
]

{ #category : 'tests' }
OModelRegistryTest >> testRebuildWithoutRemoteModelsDoesNotIncludeCatalogEntries [

        | registry |
        CoPCModelRegistry modelsFetcher: [
                        Dictionary new
                                at: #models put: #(  );
                                yourself ].
        CoPCModelRegistry refresh.
        registry := CoPCModelRegistry current.
        self assert: registry byFullName size equals: 4.
    self assert: registry byLabel size equals: 4.
    self assert: (registry specByFullName: CopilotSettings nullModelFullName) notNil.
        CoPCModelRegistry modelsFetcher: [ self defaultModelsResponse ].
        CoPCModelRegistry refresh
]

{ #category : 'tests' }
OModelRegistryTest >> testRefreshRebuildsCurrent [

	| old new |
	old := CoPCModelRegistry current.
	new := CoPCModelRegistry refresh.
	self deny: old identicalTo: new.
	self assert: CoPCModelRegistry current identicalTo: new
]

{ #category : 'tests' }
OModelRegistryTest >> testRegistryAlwaysIncludesNullModel [

    | registry spec |
    registry := CoPCModelRegistry build.
    self assert: (registry specByFullName: CopilotSettings nullModelFullName) notNil.
    spec := registry specByLabel: 'Pharo Copilot (not configured)'.
    "self assert: spec notNil."
    "self assert: spec fullName equals: CopilotSettings nullModelFullName"
]

{ #category : 'tests' }
OModelRegistryTest >> testSpecLookupByFullNameAndLabel [

	| registry spec |
	registry := CoPCModelRegistry build.
	spec := registry specByFullName: OTestModelSupport mockModelName.
	self assert: spec notNil.
	self assert: spec label equals: OTestModelSupport mockModelLabel.
	self assert: spec notNil
]

{ #category : 'tests' }
OModelRegistryTest >> testSpecLookupByFullNameMissing [

    | registry |
    registry := CoPCModelRegistry build.
    self assert: (registry specByFullName: 'unknown') isNil.
]

{ #category : 'tests' }
OModelRegistryTest >> testSpecLookupHandlesMissingKeys [
	| registry |
	registry := CoPCModelRegistry build.
	
	self assert: (registry specByFullName: 'nonexistent:model') isNil.
	self assert: (registry specByLabel: 'Nonexistent Model') isNil
]
