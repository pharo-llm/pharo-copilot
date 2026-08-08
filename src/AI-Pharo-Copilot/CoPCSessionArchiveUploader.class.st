"
CoPCSessionArchiveUploader sends completed Pharo Copilot session zip archives to
the local receiver. Upload failures are intentionally best-effort and are handled
by CoPharoCopilotLogger so archiving can still finish when the receiver is down.
"
Class {
	#name : 'CoPCSessionArchiveUploader',
	#superclass : 'Object',
	#classInstVars : [
		'enabled',
		'uploadUrl',
		'timeoutSeconds'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'defaults' }
CoPCSessionArchiveUploader class >> defaultTimeoutSeconds [

	^ 3
]

{ #category : 'defaults' }
CoPCSessionArchiveUploader class >> defaultUploadUrl [

	^ 'http://127.0.0.1:3000/api/sessions'
]

{ #category : 'accessing' }
CoPCSessionArchiveUploader class >> enabled [

	^ enabled ifNil: [ enabled := true ]
]

{ #category : 'accessing' }
CoPCSessionArchiveUploader class >> enabled: aBoolean [

	enabled := aBoolean = true
]

{ #category : 'accessing' }
CoPCSessionArchiveUploader class >> resetDefaults [

	enabled := nil.
	uploadUrl := nil.
	timeoutSeconds := nil
]

{ #category : 'accessing' }
CoPCSessionArchiveUploader class >> timeoutSeconds [

	^ timeoutSeconds ifNil: [ timeoutSeconds := self defaultTimeoutSeconds ]
]

{ #category : 'accessing' }
CoPCSessionArchiveUploader class >> timeoutSeconds: aNumber [

	timeoutSeconds := aNumber
]

{ #category : 'uploading' }
CoPCSessionArchiveUploader class >> uploadArchive: archiveFile sessionId: sessionId userId: userId [

	self enabled ifFalse: [ ^ nil ].
	archiveFile ifNil: [ ^ nil ].
	((archiveFile exists) and: [ archiveFile isFile ]) ifFalse: [ ^ nil ].

	^ self new
		uploadArchive: archiveFile
		sessionId: sessionId
		userId: userId
]

{ #category : 'accessing' }
CoPCSessionArchiveUploader class >> uploadUrl [

	^ uploadUrl ifNil: [ uploadUrl := self defaultUploadUrl ]
]

{ #category : 'accessing' }
CoPCSessionArchiveUploader class >> uploadUrl: aString [

	uploadUrl := aString
]

{ #category : 'uploading' }
CoPCSessionArchiveUploader >> newUploadClientForFile: file sessionId: sessionId userId: userId [

	| client |
	client := ZnClient new
		url: self class uploadUrl;
		method: #POST;
		yourself.

	(client respondsTo: #timeout:) ifTrue: [
		client timeout: self class timeoutSeconds ].

	client headerAt: 'Content-Type' put: 'application/zip'.
	client headerAt: 'X-File-Name' put: file basename.
	sessionId ifNotNil: [
		client headerAt: 'X-Session-Id' put: sessionId asString ].
	userId ifNotNil: [
		client headerAt: 'X-User-Id' put: userId asString ].

	^ client
]

{ #category : 'uploading' }
CoPCSessionArchiveUploader >> uploadArchive: archiveFile sessionId: sessionId userId: userId [

	| file bytes client |
	file := archiveFile asFileReference.
	bytes := file binaryReadStreamDo: [ :stream | stream upToEnd ].
	client := self
		newUploadClientForFile: file
		sessionId: sessionId
		userId: userId.

	[
		client entity: (ZnEntity bytes: bytes).
		^ client execute
	] ensure: [
		(client respondsTo: #close) ifTrue: [
			[ client close ] on: Error do: [ :ignored | ] ] ]
]
