package scanfair.apple.gate_groups_test

import rego.v1
import data.scanfair.apple.g_as_build_integrity
import data.scanfair.apple.g_as_camera
import data.scanfair.apple.g_as_claims_transparency
import data.scanfair.apple.g_as_metadata
import data.scanfair.apple.g_as_privacy
import data.scanfair.apple.g_as_review_readiness
import data.scanfair.apple.g_as_support_identity
import data.scanfair.apple.g_as_third_party_rights

valid_release_input := {
	"compliance_profile": "release_candidate",
	"apple_guidelines_version": "2026-06-08",
	"privacy_manifest_present": true,
	"privacy_manifest_valid": true,
	"ios_privacy_review_current": true,
	"required_reason_api_review_completed": true,
	"third_party_sdk_privacy_review_completed": true,
	"listed_binary_sdk_signature_validation_completed": true,
	"privacy_policy_url": "https://example.com/privacy",
	"in_app_privacy_link_present": true,
	"privacy_policy_content_reviewed": true,
	"app_privacy_details_completed": true,
	"data_inventory_completed": true,
	"feature_tracking_enabled": false,
	"att_prompt_implemented": false,
	"feature_accounts_enabled": false,
	"account_deletion_implemented": false,
	"feature_third_party_ai_enabled": false,
	"third_party_ai_data_consent_reviewed": false,
	"feature_in_app_purchases_enabled": false,
	"iap_compliance_review_completed": false,
	"feature_social_login_enabled": false,
	"social_login_compliance_review_completed": false,
	"feature_chatbot_enabled": false,
	"chatbot_compliance_review_completed": false,
	"feature_user_generated_content_enabled": false,
	"ugc_safety_review_completed": false,
	"feature_push_notifications_enabled": false,
	"push_compliance_review_completed": false,
	"camera_purpose_string": "ScanFair uses the camera to scan product barcodes and show the ESG score.",
	"camera_runtime_review_completed": true,
	"camera_manual_fallback_verified": true,
	"camera_localizations_reviewed": true,
	"app_name_pubspec": "ScanFair",
	"app_name_ios": "ScanFair",
	"app_store_name": "ScanFair",
	"subtitle": "ESG score while shopping",
	"metadata_review_completed": true,
	"screenshots_reviewed": true,
	"age_rating_completed": true,
	"brand_rights_reviewed": true,
	"app_complete": true,
	"backend_ready_for_review": true,
	"review_notes_completed": true,
	"review_sample_barcode": "3017620422003",
	"physical_device_smoke_test_completed": true,
	"ipv6_network_test_completed": true,
	"review_account_available": false,
	"accessibility_review_completed": true,
	"scoring_methodology_document_present": true,
	"esg_sources_disclosed_in_app": true,
	"esg_limitations_disclosed_in_app": true,
	"esg_claims_manual_review_completed": true,
	"license_document_present": true,
	"off_license_identified": true,
	"off_attribution_in_app_present": true,
	"off_share_alike_obligations_reviewed": true,
	"third_party_rights_review_completed": true,
	"support_url": "https://example.com/support",
	"support_email": "support@example.com",
	"in_app_contact_present": true,
	"legal_notice_reviewed": true,
	"manual_review": {
		"reviewed_by": "release owner",
		"evidence_uri": "evidence://release/1",
	},
}

test_all_eight_release_gates_pass if {
	count(g_as_build_integrity.deny) == 0 with input as valid_release_input
	count(g_as_privacy.deny) == 0 with input as valid_release_input
	count(g_as_camera.deny) == 0 with input as valid_release_input
	count(g_as_metadata.deny) == 0 with input as valid_release_input
	count(g_as_review_readiness.deny) == 0 with input as valid_release_input
	count(g_as_claims_transparency.deny) == 0 with input as valid_release_input
	count(g_as_third_party_rights.deny) == 0 with input as valid_release_input
	count(g_as_support_identity.deny) == 0 with input as valid_release_input
}

test_build_integrity_fails_closed if {
	some msg in g_as_build_integrity.deny with input as object.union(valid_release_input, {"privacy_manifest_present": false})
	contains(msg, "PrivacyInfo.xcprivacy")
}

test_build_integrity_rejects_invalid_manifest if {
	some msg in g_as_build_integrity.deny with input as object.union(valid_release_input, {"privacy_manifest_valid": false})
	contains(msg, "invalid")
}

test_build_integrity_rejects_stale_review if {
	some msg in g_as_build_integrity.deny with input as object.union(valid_release_input, {"ios_privacy_review_current": false})
	contains(msg, "does not match")
}

test_build_integrity_rejects_missing_listed_sdk_signature_validation if {
	some msg in g_as_build_integrity.deny with input as object.union(valid_release_input, {"listed_binary_sdk_signature_validation_completed": false})
	contains(msg, "publisher-signature")
}

test_privacy_tracking_condition_fails_in_development if {
	some msg in g_as_privacy.deny with input as object.union(valid_release_input, {
		"compliance_profile": "development",
		"feature_tracking_enabled": true,
		"att_prompt_implemented": false,
	})
	contains(msg, "ATT")
}

test_third_party_ai_condition_fails_without_explicit_permission_review if {
	some msg in g_as_privacy.deny with input as object.union(valid_release_input, {
		"feature_third_party_ai_enabled": true,
		"third_party_ai_data_consent_reviewed": false,
	})
	contains(msg, "third-party AI")
}

test_camera_missing_purpose_fails if {
	some msg in g_as_camera.deny with input as object.union(valid_release_input, {"camera_purpose_string": ""})
	contains(msg, "missing")
}

test_metadata_empty_name_fails if {
	some msg in g_as_metadata.deny with input as object.union(valid_release_input, {"app_name_pubspec": ""})
	contains(msg, "canonical app name")
}

test_review_readiness_fails_without_ipv6_test if {
	some msg in g_as_review_readiness.deny with input as object.union(valid_release_input, {"ipv6_network_test_completed": false})
	contains(msg, "IPv6")
}

test_ugc_condition_fails_without_safety_review if {
	some msg in g_as_review_readiness.deny with input as object.union(valid_release_input, {
		"feature_user_generated_content_enabled": true,
		"ugc_safety_review_completed": false,
	})
	contains(msg, "user-generated content")
}

test_accessibility_should_remains_warning if {
	warning_input := object.union(valid_release_input, {"accessibility_review_completed": false})
	count(g_as_review_readiness.deny) == 0 with input as warning_input
	some msg in g_as_review_readiness.warn with input as warning_input
	contains(msg, "SHOULD")
}

test_claims_gate_fails_without_limitations if {
	some msg in g_as_claims_transparency.deny with input as object.union(valid_release_input, {"esg_limitations_disclosed_in_app": false})
	contains(msg, "limitations")
}

test_third_party_gate_fails_without_attribution if {
	some msg in g_as_third_party_rights.deny with input as object.union(valid_release_input, {"off_attribution_in_app_present": false})
	contains(msg, "attribution")
}

test_support_gate_fails_without_url if {
	some msg in g_as_support_identity.deny with input as object.union(valid_release_input, {"support_url": null})
	contains(msg, "support URL")
}

test_development_profile_warns_for_release_evidence if {
	development_input := object.union(valid_release_input, {
		"compliance_profile": "development",
		"privacy_policy_url": null,
	})
	count(g_as_privacy.deny) == 0 with input as development_input
	some msg in g_as_privacy.warn with input as development_input
	contains(msg, "pending")
}

test_submission_requires_final_attestation if {
	submission_input := object.union(valid_release_input, {
		"compliance_profile": "submission",
		"manual_review": {"reviewed_by": null, "evidence_uri": null},
	})
	some msg in g_as_review_readiness.deny with input as submission_input
	contains(msg, "attestation")
}
