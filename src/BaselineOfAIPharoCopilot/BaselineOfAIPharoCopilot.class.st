Class {
	#name : 'BaselineOfAIPharoCopilot',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfAIPharoCopilot',
	#package : 'BaselineOfAIPharoCopilot'
}

{ #category : 'baselines' }
BaselineOfAIPharoCopilot >> baseline: spec [

	<baseline>
        spec for: #common do: [
                spec package: 'AI-Pharo-Copilot-API'.
                spec package: 'AI-Pharo-Copilot'
                        with: [ spec requires: #('AI-Pharo-Copilot-API') ].
                spec package: 'AI-Pharo-Copilot-Tests'
                        with: [ spec requires: #('AI-Pharo-Copilot') ]
                 ]
]
