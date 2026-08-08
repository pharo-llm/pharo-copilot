"
CoPCSessionArchiveUploader sends completed Pharo Copilot session zip archives to
the configured receiver. Upload failures are intentionally best-effort and are handled
by CoPharoCopilotLogger so archiving can still finish when the receiver is down.
"
Class {
	#name : 'CoPCSessionArchiveUploader',
	#superclass : 'Object',
	#classInstVars : [
		'enabled',
		'uploadUrl',
		'uploadToken',
		'timeoutSeconds'
	],
	#category : 'AI-Pharo-Copilot',
	#package : 'AI-Pharo-Copilot'
}

{ #category : 'defaults' }
CoPCSessionArchiveUploader class >> defaultPublicUploadUrl [

	^ 'http://rmod-xp.lille.inria.fr:3000/api/sessions'
]

{ #category : 'defaults' }
CoPCSessionArchiveUploader class >> defaultTimeoutSeconds [

	^ 3
]

{ #category : 'defaults' }
CoPCSessionArchiveUploader class >> defaultUploadUrl [

	^ self uploadUrlFromEnvironmentOrDefault
]

{ #category : 'connection' }
CoPCSessionArchiveUploader class >> authorizeConnection [

	self enabled ifFalse: [ ^ false ].
	^ self new authorizeConnection
]

{ #category : 'connection' }
CoPCSessionArchiveUploader class >> connectionPingUrl [

	^ self uploadUrlForEndpoint: '/api/connections/ping'
]

{ #category : 'connection' }
CoPCSessionArchiveUploader class >> connectionRegistrationUrl [

	^ self uploadUrlForEndpoint: '/api/connections/register'
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
CoPCSessionArchiveUploader class >> ensureUploadToken [

	^ self uploadToken ifNil: [
		self uploadToken: self newUploadToken.
		uploadToken ]
]

{ #category : 'accessing' }
CoPCSessionArchiveUploader class >> newUploadToken [

	^ 'cpc-' , UUID new asString36 , '-' , UUID new asString36
]

{ #category : 'accessing' }
CoPCSessionArchiveUploader class >> resetDefaults [

	enabled := nil.
	uploadUrl := nil.
	uploadToken := nil.
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
CoPCSessionArchiveUploader class >> uploadToken [

	^ uploadToken ifNil: [ uploadToken := self uploadTokenFromDiskOrNil ]
]

{ #category : 'accessing' }
CoPCSessionArchiveUploader class >> uploadToken: aString [

	uploadToken := aString.
	(aString notNil and: [ aString asString trimBoth isEmpty not ]) ifTrue: [
		self saveUploadToken: uploadToken asString trimBoth ]
]

{ #category : 'accessing' }
CoPCSessionArchiveUploader class >> uploadTokenFileReference [

	^ CoPharoCopilotLogger ensureLogsDirectory / 'server-upload-token.txt'
]

{ #category : 'accessing' }
CoPCSessionArchiveUploader class >> uploadTokenFromDiskOrNil [

	| file token |
	file := self uploadTokenFileReference.
	(file exists and: [ file isFile ]) ifFalse: [ ^ nil ].
	token := [ file contents trimBoth ] on: Error do: [ '' ].
	^ token isEmpty
		ifTrue: [ nil ]
		ifFalse: [ token ]
]

{ #category : 'accessing' }
CoPCSessionArchiveUploader class >> uploadUrl [

	^ uploadUrl ifNil: [ uploadUrl := self defaultUploadUrl ]
]

{ #category : 'accessing' }
CoPCSessionArchiveUploader class >> uploadUrl: aString [

	uploadUrl := aString
]

{ #category : 'accessing' }
CoPCSessionArchiveUploader class >> uploadUrlFromEnvironmentOrDefault [

	| environment url |
	environment := Smalltalk globals at: #OSEnvironment ifAbsent: [ nil ].
	environment ifNotNil: [
		url := [
			environment current
				at: 'PHARO_COPILOT_RECEIVER_URL'
				ifAbsent: [ nil ] ]
			on: Error
			do: [ nil ].
		(url notNil and: [ url asString trimBoth isEmpty not ]) ifTrue: [
			^ url asString trimBoth ] ].

	^ self defaultPublicUploadUrl
]

{ #category : 'private' }
CoPCSessionArchiveUploader class >> uploadUrlForEndpoint: endpointPath [

	| base |
	base := self uploadUrl asString.
	(base includesSubstring: '/api/sessions') ifTrue: [
		^ base copyReplaceAll: '/api/sessions' with: endpointPath ].
	^ base , endpointPath
]

{ #category : 'accessing' }
CoPCSessionArchiveUploader class >> saveUploadToken: aString [

	| file |
	file := self uploadTokenFileReference.
	file parent ifNotNil: [ :parent | parent ensureCreateDirectory ].
	file ensureCreateFile.
	file writeStreamDo: [ :stream |
		stream truncate.
		stream nextPutAll: aString ]
]

{ #category : 'connection' }
CoPCSessionArchiveUploader >> authorizeConnection [

	| token client payload |
	token := self class ensureUploadToken.
	client := self newJsonClientForUrl: self class connectionRegistrationUrl.
	payload := Dictionary new
		at: #userId put: CoPharoCopilotLogger userId;
		at: #token put: token;
		at: #client put: 'pharo-copilot';
		at: #clientVersion put: 'development';
		at: #imageVersion put: ([ Smalltalk version asString ] on: Error do: [ 'unknown' ]);
		at: #timestamp put: DateAndTime now asString;
		yourself.

	[
		client entity: (ZnEntity json: (STONJSON toString: payload)).
		client execute.
		((client respondsTo: #isSuccess) and: [ client isSuccess not ]) ifTrue: [
			self error: 'Server rejected Copilot connection registration' ].
		^ true
	] ensure: [
		(client respondsTo: #close) ifTrue: [
			[ client close ] on: Error do: [ :ignored | ] ] ]
]

{ #category : 'connection' }
CoPCSessionArchiveUploader >> newJsonClientForUrl: aUrlString [

	| client |
	client := ZnClient new
		url: aUrlString;
		method: #POST;
		yourself.

	(client respondsTo: #timeout:) ifTrue: [
		client timeout: self class timeoutSeconds ].

	client accept: ZnMimeType applicationJson.
	client headerAt: 'Content-Type' put: 'application/json'.
	^ client
]

{ #category : 'uploading' }
CoPCSessionArchiveUploader >> newUploadClientForFile: file sessionId: sessionId userId: userId [

	| client token |
	client := ZnClient new
		url: self class uploadUrl;
		method: #POST;
		yourself.

	(client respondsTo: #timeout:) ifTrue: [
		client timeout: self class timeoutSeconds ].

	client headerAt: 'Content-Type' put: 'application/zip'.
	client headerAt: 'X-File-Name' put: file basename.
	token := self class ensureUploadToken.
	client headerAt: 'Authorization' put: 'Bearer ' , token.
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
