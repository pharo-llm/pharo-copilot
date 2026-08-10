Class {
	#name : 'CopilotDetailMorphTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CopilotDetailMorphTest >> testForegroundColorForDarkBackgroundIsWhite [

	self
		assert: (CopilotDetailMorph foregroundColorForBackground: Color darkGray)
		equals: Color white
]

{ #category : 'tests' }
CopilotDetailMorphTest >> testForegroundColorForLightBackgroundIsBlack [

	self
		assert: (CopilotDetailMorph foregroundColorForBackground: Color white)
		equals: Color black
]

{ #category : 'tests' }
CopilotDetailMorphTest >> testInitializedStringMorphsUseForegroundColor [

	| detail foreground stringMorphs |
	detail := CopilotDetailMorph new.
	foreground := detail foregroundColor.
	stringMorphs := detail submorphs select: [ :each |
		each isKindOf: StringMorph ].

	self assert: stringMorphs size equals: 2.
	stringMorphs do: [ :each |
		self assert: each color equals: foreground ]
]

{ #category : 'tests' }
CopilotDetailMorphTest >> testInitializedTextMorphUsesForegroundColor [

	| detail foreground textMorph |
	detail := CopilotDetailMorph new.
	foreground := detail foregroundColor.
	textMorph := detail submorphs detect: [ :each |
		each isKindOf: TextMorph ].

	(textMorph respondsTo: #textColor)
		ifTrue: [
			self assert: textMorph textColor equals: foreground ]
		ifFalse: [
			self assert: textMorph color equals: foreground ]
]
