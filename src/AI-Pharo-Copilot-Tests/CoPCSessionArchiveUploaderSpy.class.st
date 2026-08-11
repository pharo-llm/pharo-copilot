Class {
	#name : 'CoPCSessionArchiveUploaderSpy',
	#superclass : 'Object',
	#instVars : [
		'uploadedArchive',
		'uploadedTelemetrySummary',
		'uploadedSession',
		'uploadedUser',
		'telemetrySession',
		'telemetryUser',
		'uploadSawExistingArchive',
		'uploadSawZipArchive',
		'uploadSawExistingTelemetrySummary',
		'telemetryPayload'
	],
	#category : 'AI-Pharo-Copilot-Tests-Mock',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Mock'
}

{ #category : 'initialization' }
CoPCSessionArchiveUploaderSpy >> initialize [

	super initialize.
	uploadSawExistingArchive := false.
	uploadSawZipArchive := false.
	uploadSawExistingTelemetrySummary := false
]

{ #category : 'uploading' }
CoPCSessionArchiveUploaderSpy >> uploadArchive: archiveFile sessionId: sessionId userId: userId [

	uploadedArchive := archiveFile.
	uploadedSession := sessionId.
	uploadedUser := userId.
	uploadSawExistingArchive := archiveFile exists.
	uploadSawZipArchive := ZipArchive isZipArchive: archiveFile
]

{ #category : 'uploading' }
CoPCSessionArchiveUploaderSpy >> uploadTelemetrySummary: summaryFile sessionId: sessionId userId: userId [

	uploadedTelemetrySummary := summaryFile.
	telemetrySession := sessionId.
	telemetryUser := userId.
	uploadSawExistingTelemetrySummary := summaryFile exists.
	telemetryPayload := STONJSON fromString: summaryFile contents
]

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> uploadedArchive [

	^ uploadedArchive
]

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> uploadedTelemetrySummary [

	^ uploadedTelemetrySummary
]

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> uploadedSession [

	^ uploadedSession
]

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> uploadedUser [

	^ uploadedUser
]

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> telemetrySession [

	^ telemetrySession
]

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> telemetryUser [

	^ telemetryUser
]

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> uploadSawExistingArchive [

	^ uploadSawExistingArchive
]

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> uploadSawZipArchive [

	^ uploadSawZipArchive
]

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> uploadSawExistingTelemetrySummary [

	^ uploadSawExistingTelemetrySummary
]

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> telemetryPayload [

	^ telemetryPayload
]
