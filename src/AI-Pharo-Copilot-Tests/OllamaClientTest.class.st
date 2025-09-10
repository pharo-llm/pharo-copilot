Class {
	#name : 'OllamaClientTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests',
	#package : 'AI-Pharo-Copilot-Tests'
}

{ #category : 'tests' }
OllamaClientTest >> testGenerateForPrefixSuffixBuildsPrompt [

    | client mock prefix suffix payload |
    client := OllamaClient new.
    mock := OAHttpTransportMock new.
    client instVarNamed: 'transport' put: mock.
    prefix := 'foo'.
    suffix := 'bar'.
    client generateForPrefix: prefix suffix: suffix.
    payload := mock lastBody.
    self assert: (payload at: #prompt) equals: '<PRE>foo<SUF>bar<MID>'.
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponsePrefersResponse [

    | client dict result |
    client := OllamaClient new.
    dict := Dictionary new
        at: #response put: 'foo';
        at: #content put: 'bar';
        yourself.
    result := client normalizeResponse: dict.
    self assert: result equals: 'foo'.
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponseUsesContent [

    | client dict result |
    client := OllamaClient new.
    dict := Dictionary new
        at: #content put: 'bar';
        yourself.
    result := client normalizeResponse: dict.
    self assert: result equals: 'bar'.
]

{ #category : 'tests' }
OllamaClientTest >> testNormalizeResponseUsesString [

    | client result |
    client := OllamaClient new.
    result := client normalizeResponse: 'baz'.
    self assert: result equals: 'baz'.
]

{ #category : 'tests' }
OllamaClientTest >> testOptionAtPutAndGet [

    | client |
    client := OllamaClient new.
    client optionAt: #temperature put: 0.5.
    self assert: (client optionAt: #temperature) equals: 0.5.
]

{ #category : 'tests' }
OllamaClientTest >> testOptionAtReturnsNil [

    | client |
    client := OllamaClient new.
    self assert: (client optionAt: #missing) isNil.
]

{ #category : 'tests' }
OllamaClientTest >> testOptionsDefaultEmpty [

    | client |
    client := OllamaClient new.
    self assert: client options isEmpty.
]

{ #category : 'tests' }
OllamaClientTest >> testOptionsSetterNilCreatesEmptyDictionary [

    | client |
    client := OllamaClient new.
    client options: nil.
    self assert: client options isEmpty.
]

{ #category : 'tests' }
OllamaClientTest >> testOptionsSetterStoresDictionary [

    | client dict |
    client := OllamaClient new.
    dict := Dictionary new
        at: #temperature put: 0.8;
        yourself.
    client options: dict.
    self assert: client options identicalTo: dict.
]

{ #category : 'tests' }
OllamaClientTest >> testUseDefaultModelSetsModelSpec [

    | client spec |
    client := OllamaClient new.
    spec := client instVarNamed: 'modelSpec'.
    self assert: spec notNil.
    self assert: spec fullName equals: OllamaClient defaultModelFullName.
]
