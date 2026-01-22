Class {
	#name : 'CoBenchmarkScenarioCatalog',
	#superclass : 'Object',
	#category : 'AI-Pharo-Copilot-Benchmarks',
	#package : 'AI-Pharo-Copilot-Benchmarks'
}

{ #category : 'scenarios' }
CoBenchmarkScenarioCatalog class >> defaultScenarios [

	^ Dictionary new
		at: 'method_simple' put: (CoBenchmarkScenario
			named: 'method_simple'
			prefix: 'factorial\n\t"Calculate the factorial of a number"\n\t'
			suffix: ''
			context: 'Number >> factorial\n\t"Return the factorial of the receiver"\n\t^ self = 0\n\t\tifTrue: [ 1 ]\n\t\tifFalse: [ self * (self - 1) factorial ]'
			description: 'Simple method implementation');
		at: 'method_with_suffix' put: (CoBenchmarkScenario
			named: 'method_with_suffix'
			prefix: 'sortBy: aBlock\n\t"Sort the collection using the given block"\n\t'
			suffix: '\n\t^ sorted'
			context: 'Collection >> sorted\n\t"Return a sorted copy of the receiver"\n\t^ self asArray sort'
			description: 'Method with suffix context');
		at: 'test_method' put: (CoBenchmarkScenario
			named: 'test_method'
			prefix: 'testAddition\n\t'
			suffix: ''
			context: 'TestCase subclass: #MyTest\n\nMyTest >> setUp\n\tsuper setUp.\n\tcollection := OrderedCollection new'
			description: 'Test method creation');
		at: 'class_method' put: (CoBenchmarkScenario
			named: 'class_method'
			prefix: 'createDefault\n\t"Create a default instance"\n\t'
			suffix: ''
			context: 'MyClass class >> new\n\t"Create a new instance"\n\t^ super new initialize'
			description: 'Class-side method');
		at: 'iteration' put: (CoBenchmarkScenario
			named: 'iteration'
			prefix: 'sum\n\t"Return the sum of all elements"\n\t| total |\n\ttotal := 0.\n\t'
			suffix: '\n\t^ total'
			context: 'Collection >> average\n\t"Return the average of all elements"\n\t^ self sum / self size'
			description: 'Iteration pattern');
		at: 'conditionals' put: (CoBenchmarkScenario
			named: 'conditionals'
			prefix: 'max: aNumber\n\t"Return the maximum of self and aNumber"\n\t'
			suffix: ''
			context: 'Number >> min: aNumber\n\t"Return the minimum of self and aNumber"\n\t^ self < aNumber\n\t\tifTrue: [ self ]\n\t\tifFalse: [ aNumber ]'
			description: 'Conditional logic');
		at: 'error_handling' put: (CoBenchmarkScenario
			named: 'error_handling'
			prefix: 'divide: aDivisor\n\t"Divide self by aDivisor with error handling"\n\t'
			suffix: ''
			context: 'Number >> safeDivide: aDivisor\n\t"Safely divide, return nil if error"\n\t[ ^ self / aDivisor ]\n\t\ton: Error\n\t\tdo: [ :ex | ^ nil ]'
			description: 'Error handling pattern');
		at: 'block_creation' put: (CoBenchmarkScenario
			named: 'block_creation'
			prefix: 'filterBy: aBlock\n\t"Filter elements matching the block"\n\t| result |\n\tresult := OrderedCollection new.\n\t'
			suffix: '\n\t^ result'
			context: 'Collection >> select: aBlock\n\t"Select elements matching the block"\n\t^ self inject: OrderedCollection new into: [ :col :each |\n\t\t(aBlock value: each) ifTrue: [ col add: each ].\n\t\tcol ]'
			description: 'Block usage pattern');
		at: 'accessor_method' put: (CoBenchmarkScenario
			named: 'accessor_method'
			prefix: 'name: aString\n\t"Set the name of this object"\n\t'
			suffix: ''
			context: 'Object >> name\n\t"Return the name"\n\t^ name'
			description: 'Accessor/mutator pattern');
		at: 'collection_creation' put: (CoBenchmarkScenario
			named: 'collection_creation'
			prefix: 'initialize\n\t"Initialize the receiver"\n\tsuper initialize.\n\t'
			suffix: ''
			context: 'Object >> initialize\n\t"Initialize the receiver"\n\t^ self'
			description: 'Initialization with collections');
		at: 'string_manipulation' put: (CoBenchmarkScenario
			named: 'string_manipulation'
			prefix: 'capitalize\n\t"Return a capitalized version of the string"\n\t'
			suffix: ''
			context: 'String >> asUppercase\n\t"Return uppercase version"\n\t^ self collect: [ :char | char asUppercase ]'
			description: 'String manipulation');
		at: 'cascade_pattern' put: (CoBenchmarkScenario
			named: 'cascade_pattern'
			prefix: 'buildReport\n\t"Build and configure a report"\n\t| report |\n\treport := Report new.\n\t'
			suffix: '\n\t^ report'
			context: 'Report >> title: aString\n\t"Set the title"\n\ttitle := aString'
			description: 'Message cascade pattern');
		yourself
]
