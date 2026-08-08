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
		equals: 'http://rmod-xp.lille.inria.fr:3000/api/sessions'.
	self deny: (CoPCSessionArchiveUploader defaultPublicUploadUrl includesSubstring: '127.0.0.1')
]
