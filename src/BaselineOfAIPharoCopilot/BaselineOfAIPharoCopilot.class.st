"
Baseline
"
Class {
	#name : 'BaselineOfAIPharoCopilot',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfAIPharoCopilot',
	#package : 'BaselineOfAIPharoCopilot'
}

{ #category : 'baselines' }
BaselineOfAIPharoCopilot class >> showFirstLaunchSetupIfNeeded [
	"Show the setup dialog if ChatPharo is not yet configured.
	Deferred to run after UI is ready."

	<script>

		(Delay forMilliseconds: 500) wait.
		World ifNotNil: [
						WorldMorph doOneCycle.
						PharoCopilotSetupPresenter open ] 
]

{ #category : 'baselines' }
BaselineOfAIPharoCopilot >> baseline: spec [

	<baseline>
	spec for: #common do: [
			spec postLoadDoIt: #postLoad.
			spec package: 'AI-Pharo-Copilot-Ollama'.
			spec package: 'AI-Pharo-Copilot' with: [ spec requires: #( 'AI-Pharo-Copilot-Ollama' ) ].
			spec package: 'AI-Pharo-Copilot-Evaluator' with: [ spec requires: #( 'AI-Pharo-Copilot' ) ].
			spec package: 'AI-Pharo-Copilot-Benchmarks' with: [ spec requires: #( 'AI-Pharo-Copilot-Ollama' ) ].
		   spec package: 'AI-Pharo-Copilot-Context' with: [ spec requires: #( 'AI-Pharo-Copilot' ) ].
			spec package: 'AI-Pharo-Copilot-Spec' with: [ spec requires: #( 'AI-Pharo-Copilot' ) ].
			spec package: 'AI-Pharo-Copilot-Tests' with: [ spec requires: #( 'AI-Pharo-Copilot' ) ] ]
]

{ #category : 'baselines' }
BaselineOfAIPharoCopilot >> postLoad [

	CopilotSettings ensureDefaultCompletionModelSelected.
	CopilotSettings installCompletionEngineIfAvailable.
	[ CoPCImageCloseSurvey registerSessionHandler ] on: Error do: [ :ignored | ].
	self class showFirstLaunchSetupIfNeeded
]
