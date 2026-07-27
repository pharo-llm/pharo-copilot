Extension { #name : 'SpMorphicCodeAdapter' }

{ #category : '*AI-Pharo-Copilot-Spec' }
SpMorphicCodeAdapter >> newCompletionEngine: anInteractionModel [
	"Honor the completion engine selected for Rubric editors. Spec previously
	hard-coded SpMorphicCodeCompletionEngine, causing debugger code editors
	to bypass completion plugins."

	| engineClass engine |
	engineClass := RubSmalltalkEditor completionEngineClass
		ifNil: [ SpMorphicCodeCompletionEngine ].
	engine := engineClass new.

	(engine respondsTo: #smartCharacters:) ifTrue: [
		engine smartCharacters: self presenter hasSmartCharacters ].
	(engine respondsTo: #scripting:) ifTrue: [
		engine scripting: anInteractionModel isScripting ].
	(engine respondsTo: #doItRequestor:) ifTrue: [
		engine doItRequestor: anInteractionModel ].
	(engine respondsTo: #doItContext:) ifTrue: [
		engine doItContext: anInteractionModel doItContext ].
	(engine respondsTo: #completionClass:) ifTrue: [
		engine completionClass: anInteractionModel selectedClassOrMetaClass ].

	^ engine
]
