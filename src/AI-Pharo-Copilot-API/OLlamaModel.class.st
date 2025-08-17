"
Base class and specific implementations for different models used in API interactions.

•	fullName: Constructs the full name of the model for API requests.
•	name: Abstract method to return the model's name, implemented by subclasses.
"
Class {
	#name : 'OLlamaModel',
	#superclass : 'OModel',
	#category : 'AI-Pharo-Copilot-API',
	#package : 'AI-Pharo-Copilot-API'
}

{ #category : 'accessing' }
OLlamaModel >> name [

	^ 'llama3'
]
