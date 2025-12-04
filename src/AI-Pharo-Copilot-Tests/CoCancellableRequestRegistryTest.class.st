Class {
	#name : 'CoCancellableRequestRegistryTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
CoCancellableRequestRegistryTest >> setUp [
        super setUp.
        CoCancellableRequestRegistry reset
]
