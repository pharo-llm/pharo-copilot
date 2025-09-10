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
		spec baseline: 'NeoJSON' with: [ spec repository: 'github://svenvc/NeoJSON/repository' ].
			spec package: 'AI-Pharo-Copilot-Ollama'.
			spec package: 'AI-Pharo-Copilot' with: [ spec requires: #( 'AI-Pharo-Copilot-Ollama' ) ].
			spec package: 'AI-Pharo-Copilot-Tests' with: [ spec requires: #( 'AI-Pharo-Copilot' ) ] ]
]
