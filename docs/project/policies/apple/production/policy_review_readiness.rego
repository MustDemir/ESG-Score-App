package scanfair.apple.g_as_review_readiness

import rego.v1
import data.scanfair.apple.lib

release_checks := [
	{"ok": object.get(input, "app_complete", false), "message": "app completeness is not attested"},
	{"ok": object.get(input, "backend_ready_for_review", false), "message": "review backend is not ready"},
	{"ok": object.get(input, "review_notes_completed", false), "message": "App Review notes are incomplete"},
	{"ok": object.get(input, "review_sample_barcode", "") != "", "message": "review sample barcode is missing"},
	{"ok": object.get(input, "physical_device_smoke_test_completed", false), "message": "physical-device smoke test is incomplete"},
	{"ok": object.get(input, "ipv6_network_test_completed", false), "message": "IPv6-only network test is incomplete"},
]

deny contains msg if {
	lib.release_profile
	some check in release_checks
	not check.ok
	msg := sprintf("G-AS-REVIEW-READINESS: %s", [check.message])
}

warn contains msg if {
	not lib.release_profile
	some check in release_checks
	not check.ok
	msg := sprintf("G-AS-REVIEW-READINESS: %s", [check.message])
}

warn contains "G-AS-REVIEW-READINESS: Apple HIG and accessibility review is pending (SHOULD)" if {
	not input.accessibility_review_completed
}

deny contains "G-AS-REVIEW-READINESS: reviewer account is required when account features are enabled" if {
	input.feature_accounts_enabled
	lib.release_profile
	not input.review_account_available
}

deny contains "G-AS-REVIEW-READINESS: review prompt does not have verified standard Apple API evidence" if {
	input.feature_review_prompt_enabled
	not input.standard_review_api_verified
}

deny contains "G-AS-REVIEW-READINESS: in-app purchases are enabled without a current payment and subscription review" if {
	input.feature_in_app_purchases_enabled
	not input.iap_compliance_review_completed
}

deny contains "G-AS-REVIEW-READINESS: social login is enabled without an equivalent-login review" if {
	input.feature_social_login_enabled
	not input.social_login_compliance_review_completed
}

deny contains "G-AS-REVIEW-READINESS: chatbot is enabled without a current section 4.7 applicability review" if {
	input.feature_chatbot_enabled
	not input.chatbot_compliance_review_completed
}

deny contains "G-AS-REVIEW-READINESS: user-generated content is enabled without reviewed safety controls" if {
	input.feature_user_generated_content_enabled
	not input.ugc_safety_review_completed
}

deny contains "G-AS-REVIEW-READINESS: push notifications are enabled without a consent and content review" if {
	input.feature_push_notifications_enabled
	not input.push_compliance_review_completed
}

deny contains "G-AS-REVIEW-READINESS: final submission attestation is incomplete" if {
	lib.submission_profile
	not lib.present(input.manual_review.reviewed_by)
}

deny contains "G-AS-REVIEW-READINESS: final submission evidence URI is missing" if {
	lib.submission_profile
	not lib.present(input.manual_review.evidence_uri)
}
