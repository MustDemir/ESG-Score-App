package scanfair.apple.g_as_support_identity

import rego.v1
import data.scanfair.apple.lib

deny contains "G-AS-SUPPORT-IDENTITY: support URL must use HTTPS" if {
	lib.present(input.support_url)
	not lib.https_url(input.support_url)
}

deny contains "G-AS-SUPPORT-IDENTITY: public support URL is missing" if {
	lib.release_profile
	not lib.present(input.support_url)
}

warn contains "G-AS-SUPPORT-IDENTITY: public support URL is pending" if {
	not lib.release_profile
	not lib.present(input.support_url)
}

deny contains "G-AS-SUPPORT-IDENTITY: support email is missing" if {
	lib.release_profile
	not lib.present(input.support_email)
}

warn contains "G-AS-SUPPORT-IDENTITY: support email is pending" if {
	not lib.release_profile
	not lib.present(input.support_email)
}

deny contains "G-AS-SUPPORT-IDENTITY: in-app contact path is missing" if {
	lib.release_profile
	not input.in_app_contact_present
}

warn contains "G-AS-SUPPORT-IDENTITY: in-app contact path is pending" if {
	not lib.release_profile
	not input.in_app_contact_present
}

deny contains "G-AS-SUPPORT-IDENTITY: legal notice review is incomplete" if {
	lib.release_profile
	not input.legal_notice_reviewed
}

warn contains "G-AS-SUPPORT-IDENTITY: legal notice review is pending" if {
	not lib.release_profile
	not input.legal_notice_reviewed
}
