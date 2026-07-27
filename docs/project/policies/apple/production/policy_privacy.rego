package scanfair.apple.g_as_privacy

import rego.v1
import data.scanfair.apple.lib

deny contains "G-AS-PRIVACY: privacy policy URL must use HTTPS" if {
	lib.present(input.privacy_policy_url)
	not lib.https_url(input.privacy_policy_url)
}

deny contains "G-AS-PRIVACY: public privacy policy URL is missing" if {
	lib.release_profile
	not lib.present(input.privacy_policy_url)
}

warn contains "G-AS-PRIVACY: public privacy policy URL is pending" if {
	not lib.release_profile
	not lib.present(input.privacy_policy_url)
}

deny contains "G-AS-PRIVACY: in-app privacy policy link is missing" if {
	lib.release_profile
	not input.in_app_privacy_link_present
}

warn contains "G-AS-PRIVACY: in-app privacy policy link is pending" if {
	not lib.release_profile
	not input.in_app_privacy_link_present
}

deny contains "G-AS-PRIVACY: privacy policy content review is incomplete" if {
	lib.release_profile
	not input.privacy_policy_content_reviewed
}

warn contains "G-AS-PRIVACY: privacy policy content review is pending" if {
	not lib.release_profile
	not input.privacy_policy_content_reviewed
}

deny contains "G-AS-PRIVACY: App Store privacy details are incomplete" if {
	lib.release_profile
	not input.app_privacy_details_completed
}

warn contains "G-AS-PRIVACY: App Store privacy details are pending" if {
	not lib.release_profile
	not input.app_privacy_details_completed
}

deny contains "G-AS-PRIVACY: data inventory is incomplete" if {
	lib.release_profile
	not input.data_inventory_completed
}

warn contains "G-AS-PRIVACY: data inventory is pending" if {
	not lib.release_profile
	not input.data_inventory_completed
}

deny contains "G-AS-PRIVACY: tracking is enabled without ATT implementation" if {
	input.feature_tracking_enabled
	not input.att_prompt_implemented
}

deny contains "G-AS-PRIVACY: accounts are enabled without in-app account deletion" if {
	input.feature_accounts_enabled
	not input.account_deletion_implemented
}

deny contains "G-AS-PRIVACY: location is enabled without a reviewed purpose and denial path" if {
	input.feature_location_enabled
	not input.location_purpose_reviewed
}

deny contains "G-AS-PRIVACY: third-party AI data sharing is enabled without reviewed disclosure and explicit permission" if {
	input.feature_third_party_ai_enabled
	not input.third_party_ai_data_consent_reviewed
}
