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
    self assert: domain first key equals: 'Code Llama 7B'.
    self assert: domain first value equals: 'codellama:7b'.
]

{ #category : 'tests' }
OModelRegistryTest >> testSpecLookupByFullNameAndLabel [

    | registry spec |
    registry := OModelRegistry build.
    spec := registry specByFullName: 'codellama:7b'.
    self assert: spec notNil.
    self assert: spec label equals: 'Code Llama 7B'.
    self assert: (registry specByLabel: 'Code Llama 7B') == spec.
]
