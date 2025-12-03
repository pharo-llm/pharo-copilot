Class {
	#name : 'OAHttpTransportClientDouble',
	#superclass : 'Object',
	#instVars : [
		'acceptedMime',
		'writerBlock',
		'readerBlock',
		'host',
		'port',
		'path',
		'body',
		'jsonRestEnabled',
		'postEntity'
	],
	#classInstVars : [
		'lastCreated',
		'nextGetResult'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'instance creation' }
OAHttpTransportClientDouble class >> lastCreated [
        ^ lastCreated
]

{ #category : 'instance creation' }
OAHttpTransportClientDouble class >> new [ 
        | instance |
        instance := super new.
        lastCreated := instance.
        ^ instance
]

{ #category : 'instance creation' }
OAHttpTransportClientDouble class >> nextGetResult [
        ^ nextGetResult ifNil: [ Dictionary new ]
]

{ #category : 'instance creation' }
OAHttpTransportClientDouble class >> nextGetResult: anObject [
        nextGetResult := anObject
]

{ #category : 'class initialization' }
OAHttpTransportClientDouble class >> reset [
	<script>
	        lastCreated := nil.
        nextGetResult := nil

]

{ #category : 'visiting' }
OAHttpTransportClientDouble >> accept: aMimeType [
        acceptedMime := aMimeType
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> acceptedMime [

	^ acceptedMime
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> acceptedMime: anObject [

	acceptedMime := anObject
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> body [

	^ body
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> body: anObject [

	body := anObject
]

{ #category : 'as yet unclassified' }
OAHttpTransportClientDouble >> contentReader: aBlock [
        readerBlock := aBlock
]

{ #category : 'as yet unclassified' }
OAHttpTransportClientDouble >> contentWriter: aBlock [
        writerBlock := aBlock
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> contents: aDictionary [
        body := aDictionary
]

{ #category : 'as yet unclassified' }
OAHttpTransportClientDouble >> forJsonREST [
        jsonRestEnabled := true
]

{ #category : 'actions api' }
OAHttpTransportClientDouble >> get [
        ^ self class nextGetResult
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> host [

	^ host
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> host: anObject [

	host := anObject
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> jsonRestEnabled [

	^ jsonRestEnabled
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> jsonRestEnabled: anObject [

	jsonRestEnabled := anObject
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> path [

	^ path
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> path: anObject [

	path := anObject
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> port [

	^ port
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> port: anObject [

	port := anObject
]

{ #category : 'as yet unclassified' }
OAHttpTransportClientDouble >> post [
        | entity |
        entity := writerBlock value: body.
        postEntity := entity.
        ^ readerBlock
                ifNil: [ entity ]
                ifNotNil: [ readerBlock value: entity ]
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> postEntity [

	^ postEntity
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> postEntity: anObject [

	postEntity := anObject
]

{ #category : 'as yet unclassified' }
OAHttpTransportClientDouble >> postedBody [
        ^ body
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> readerBlock [

	^ readerBlock
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> readerBlock: anObject [

	readerBlock := anObject
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> writerBlock [

	^ writerBlock
]

{ #category : 'accessing' }
OAHttpTransportClientDouble >> writerBlock: anObject [

	writerBlock := anObject
]
