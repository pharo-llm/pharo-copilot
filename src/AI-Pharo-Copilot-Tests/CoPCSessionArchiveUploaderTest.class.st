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
CoPCSessionArchiveUploaderTest >> testDefaultPublicUploadUrlTargetsInternetReachableServer [

	self
		assert: CoPCSessionArchiveUploader defaultPublicUploadUrl
		equals: 'http://193.49.213.134:3000/api/sessions'.
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
			equals: CoPCSessionArchiveUploader defaultPublicUploadUrl
	] ensure: [
		CoPCSessionArchiveUploader uploadUrl: originalUrl ]
]
