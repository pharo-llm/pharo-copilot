Class {
	#name : 'CopilotMockModelTestCase',
	#superclass : 'TestCase',
	#instVars : [
		'mockContext'
	],
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
CopilotMockModelTestCase >> setUp [

    super setUp.
    mockContext := OTestModelSupport beginMockModels.
]

{ #category : 'running' }
CopilotMockModelTestCase >> tearDown [

    [ super tearDown ] ensure: [
        OTestModelSupport endMockModels: mockContext.
        mockContext := nil ].
]
