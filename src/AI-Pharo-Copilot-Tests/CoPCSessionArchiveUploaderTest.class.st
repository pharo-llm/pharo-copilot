Class {
	#name : 'CoPCSessionArchiveUploaderTest',
	#superclass : 'TestCase',
	#category : 'AI-Pharo-Copilot-Tests-Tests',
	#package : 'AI-Pharo-Copilot-Tests',
	#tag : 'Tests'
}

{ #category : 'tests' }
CoPCSessionArchiveUploaderTest >> testConnectionEndpointsAreDerivedFromSessionUploadEndpoint [

	| originalUrl |
	originalUrl := CoPCSessionArchiveUploader uploadUrl.
	[
		CoPCSessionArchiveUploader uploadUrl: 'http://example.com:3000/api/sessions'.

		self
			assert: CoPCSessionArchiveUploader connectionRegistrationUrl
			equals: 'http://example.com:3000/api/connections/register'.
		self
			assert: CoPCSessionArchiveUploader connectionPingUrl
			equals: 'http://example.com:3000/api/connections/ping'
	] ensure: [
		CoPCSessionArchiveUploader uploadUrl: originalUrl ]
]

{ #category : 'tests' }
CoPCSessionArchiveUploaderTest >> testTelemetrySummaryEndpointIsDerivedFromSessionUploadEndpoint [

	| originalUrl |
	originalUrl := CoPCSessionArchiveUploader uploadUrl.
	[
		CoPCSessionArchiveUploader uploadUrl: 'http://example.com:3000/api/sessions'.

		self
			assert: CoPCSessionArchiveUploader telemetrySummaryUploadUrl
			equals: 'http://example.com:3000/api/session-telemetry'
	] ensure: [
		CoPCSessionArchiveUploader uploadUrl: originalUrl ]
]

{ #category : 'tests' }
CoPCSessionArchiveUploaderTest >> testCandidateUploadUrlsPreferPublicReceiverAndKeepLegacyFallbacks [

	| originalUrl urls |
	originalUrl := CoPCSessionArchiveUploader uploadUrl.
	[
		CoPCSessionArchiveUploader uploadUrl: 'http://193.49.213.134:9093/api/sessions'.
		urls := CoPCSessionArchiveUploader candidateUploadUrlsForAuthorization.

		self
			assert: urls
			equals: #(
				'http://193.49.213.134:9092/api/sessions'
				'http://rmod-xp.lille.inria.fr:9092/api/sessions'
				'http://193.49.213.134:9093/api/sessions'
				'http://193.49.213.134:3000/api/sessions' )
	] ensure: [
		CoPCSessionArchiveUploader uploadUrl: originalUrl ]
]

{ #category : 'tests' }
CoPCSessionArchiveUploaderTest >> testDefaultPublicUploadUrlTargetsInternetReachableServer [

	self
		assert: CoPCSessionArchiveUploader defaultPublicUploadUrl
		equals: 'http://193.49.213.134:9092/api/sessions'.
	self deny: (CoPCSessionArchiveUploader defaultPublicUploadUrl includesSubstring: '127.0.0.1')
]

{ #category : 'tests' }
CoPCSessionArchiveUploaderTest >> testEnsureInternetUploadUrlReplacesKnownLocalOrHostDefaults [

	| originalUrl |
	originalUrl := CoPCSessionArchiveUploader uploadUrl.
	[
		CoPCSessionArchiveUploader uploadUrl: 'http://127.0.0.1:3000/api/sessions'.
		self
			assert: CoPCSessionArchiveUploader ensureInternetUploadUrl
			equals: CoPCSessionArchiveUploader defaultPublicUploadUrl.

		CoPCSessionArchiveUploader uploadUrl: 'http://rmod-xp.lille.inria.fr:3000/api/sessions'.
		self
			assert: CoPCSessionArchiveUploader ensureInternetUploadUrl
			equals: CoPCSessionArchiveUploader defaultPublicUploadUrl.

		CoPCSessionArchiveUploader uploadUrl: 'http://193.49.213.134:3000/api/sessions'.
		self
			assert: CoPCSessionArchiveUploader ensureInternetUploadUrl
			equals: CoPCSessionArchiveUploader defaultPublicUploadUrl.

		CoPCSessionArchiveUploader uploadUrl: 'http://193.49.213.134:9093/api/sessions'.
		self
			assert: CoPCSessionArchiveUploader ensureInternetUploadUrl
			equals: CoPCSessionArchiveUploader defaultPublicUploadUrl
	] ensure: [
		CoPCSessionArchiveUploader uploadUrl: originalUrl ]
]
