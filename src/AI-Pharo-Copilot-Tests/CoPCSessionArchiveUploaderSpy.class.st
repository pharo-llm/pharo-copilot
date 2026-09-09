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

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> telemetryPayload [

	^ telemetryPayload
]

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> telemetrySession [

	^ telemetrySession
]

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> telemetryUser [

	^ telemetryUser
]

{ #category : 'uploading' }
CoPCSessionArchiveUploaderSpy >> uploadArchive: archiveFile sessionId: sessionId userId: userId [

	uploadedArchive := archiveFile.
	uploadedSession := sessionId.
	uploadedUser := userId.
	uploadSawExistingArchive := archiveFile exists.
	uploadSawZipArchive := ZipArchive isZipArchive: archiveFile
]

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> uploadSawExistingArchive [

	^ uploadSawExistingArchive
]

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> uploadSawExistingTelemetrySummary [

	^ uploadSawExistingTelemetrySummary
]

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> uploadSawZipArchive [

	^ uploadSawZipArchive
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
CoPCSessionArchiveUploaderSpy >> uploadedSession [

	^ uploadedSession
]

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> uploadedTelemetrySummary [

	^ uploadedTelemetrySummary
]

{ #category : 'accessing' }
CoPCSessionArchiveUploaderSpy >> uploadedUser [

	^ uploadedUser
]
