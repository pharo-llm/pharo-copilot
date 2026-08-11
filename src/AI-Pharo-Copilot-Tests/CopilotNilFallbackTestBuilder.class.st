Class {
	#name : 'CopilotNilFallbackTestBuilder',
	#superclass : 'CopilotTestableBuilder',
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
CopilotNilFallbackTestBuilder >> fallbackResultSetFor: aContext [

	fallbackCallCount := self fallbackCallCount + 1.
	^ nil
]
