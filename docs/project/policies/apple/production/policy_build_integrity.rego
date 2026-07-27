package scanfair.apple.g_as_build_integrity

import rego.v1
import data.scanfair.apple.lib

deny contains "G-AS-BUILD-INTEGRITY: apple_guidelines_version must identify the reviewed baseline" if {
	not lib.present(input.apple_guidelines_version)
}

deny contains "G-AS-BUILD-INTEGRITY: PrivacyInfo.xcprivacy is required for release readiness" if {
	lib.release_profile
	not input.privacy_manifest_present
}

warn contains "G-AS-BUILD-INTEGRITY: PrivacyInfo.xcprivacy is not present yet" if {
	not lib.release_profile
	not input.privacy_manifest_present
}

deny contains "G-AS-BUILD-INTEGRITY: PrivacyInfo.xcprivacy is invalid" if {
	input.privacy_manifest_present
	not input.privacy_manifest_valid
}

deny contains "G-AS-BUILD-INTEGRITY: versioned iOS privacy review does not match the current dependency set" if {
	lib.release_profile
	not input.ios_privacy_review_current
}

warn contains "G-AS-BUILD-INTEGRITY: versioned iOS privacy review is missing or stale" if {
	not lib.release_profile
	not input.ios_privacy_review_current
}

deny contains "G-AS-BUILD-INTEGRITY: required-reason API review is incomplete" if {
	lib.release_profile
	not input.required_reason_api_review_completed
}

warn contains "G-AS-BUILD-INTEGRITY: required-reason API review is pending" if {
	not lib.release_profile
	not input.required_reason_api_review_completed
}

deny contains "G-AS-BUILD-INTEGRITY: third-party SDK privacy review is incomplete" if {
	lib.release_profile
	not input.third_party_sdk_privacy_review_completed
}

warn contains "G-AS-BUILD-INTEGRITY: third-party SDK privacy review is pending" if {
	not lib.release_profile
	not input.third_party_sdk_privacy_review_completed
}

deny contains "G-AS-BUILD-INTEGRITY: listed binary SDK publisher-signature validation is incomplete" if {
	lib.release_profile
	not input.listed_binary_sdk_signature_validation_completed
}

warn contains "G-AS-BUILD-INTEGRITY: listed binary SDK publisher-signature validation is pending for the signed release archive" if {
	not lib.release_profile
	not input.listed_binary_sdk_signature_validation_completed
}
