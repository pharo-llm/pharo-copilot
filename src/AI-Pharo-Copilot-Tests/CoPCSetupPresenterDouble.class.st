Class {
	#name : 'CoPCSetupPresenterDouble',
	#superclass : 'PharoCopilotSetupPresenter',
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'initialization' }
CoPCSetupPresenterDouble >> deferUI: aBlock [

	^ aBlock value
]

{ #category : 'initialization' }
CoPCSetupPresenterDouble >> startSetupDownloads [
	"Run synchronously with the test's Ollama client."

	self performSetupDownloads
]
