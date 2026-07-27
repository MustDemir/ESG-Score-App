package scanfair.apple.g_as_third_party_rights

import rego.v1
import data.scanfair.apple.lib

deny contains "G-AS-THIRD-PARTY-RIGHTS: third-party license document is missing" if {
	not input.license_document_present
}

deny contains "G-AS-THIRD-PARTY-RIGHTS: Open Food Facts license is not identified" if {
	not input.off_license_identified
}

deny contains "G-AS-THIRD-PARTY-RIGHTS: Open Food Facts attribution is missing in the app" if {
	lib.release_profile
	not input.off_attribution_in_app_present
}

warn contains "G-AS-THIRD-PARTY-RIGHTS: Open Food Facts attribution is pending in the app" if {
	not lib.release_profile
	not input.off_attribution_in_app_present
}

deny contains "G-AS-THIRD-PARTY-RIGHTS: share-alike obligations have not been reviewed" if {
	lib.release_profile
	not input.off_share_alike_obligations_reviewed
}

warn contains "G-AS-THIRD-PARTY-RIGHTS: share-alike obligations review is pending" if {
	not lib.release_profile
	not input.off_share_alike_obligations_reviewed
}

deny contains "G-AS-THIRD-PARTY-RIGHTS: third-party rights review is incomplete" if {
	lib.release_profile
	not input.third_party_rights_review_completed
}

warn contains "G-AS-THIRD-PARTY-RIGHTS: third-party rights review is pending" if {
	not lib.release_profile
	not input.third_party_rights_review_completed
}
