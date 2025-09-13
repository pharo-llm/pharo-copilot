Class {
	#name : 'OModelRegistryTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
OModelRegistryTest >> testDomainValuesForSettings [ 

    | registry domain |
    registry := OModelRegistry build.
    domain := registry domainValuesForSettings.
    self assert: domain size > 0.
 self assert: (domain anySatisfy: [:assoc | assoc key = 'Code Llama 7B' and: [assoc value = 'codellama:7b']]).
    self assert: (domain anySatisfy: [:assoc | assoc key = 'Code Llama 13B' and: [assoc value = 'codellama:13b']]).
]

{ #category : 'tests' }
OModelRegistryTest >> testDomainValuesForSettingsReturnAssociations [

    | registry domain |
    registry := OModelRegistry build.
    domain := registry domainValuesForSettings.
    self assert: (domain allSatisfy: [ :assoc | assoc isKindOf: Association ]).
]

{ #category : 'tests' }
OModelRegistryTest >> testSpecLookupByFullNameAndLabel [

	| registry spec |
	registry := OModelRegistry build.
	spec := registry specByFullName: 'codellama:7b'.
	self assert: spec notNil.
	self assert: spec label equals: 'Code Llama 7B'.
	self assert: (registry specByLabel: 'Code Llama 7B') == spec.
	    spec := registry specByFullName: 'codellama:13b'.
    self assert: spec notNil.
    self assert: spec label equals: 'Code Llama 13B'.
    self assert: (registry specByLabel: 'Code Llama 13B') == spec.
]

{ #category : 'tests' }
OModelRegistryTest >> testSpecLookupByFullNameMissing [

    | registry |
    registry := OModelRegistry build.
    self assert: (registry specByFullName: 'unknown') isNil.
]
