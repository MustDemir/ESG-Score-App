package scanfair.apple.g_as_metadata

import rego.v1
import data.scanfair.apple.lib

_max_length := 30
_foreign_platform_terms := {"android", "google play", "play store", "windows phone", "microsoft store", "galaxy store"}

metadata_text := sprintf("%s %s", [object.get(input, "app_store_name", ""), object.get(input, "subtitle", "")])

deny contains "G-AS-METADATA: canonical app name is missing" if {
	not lib.present(input.app_name_pubspec)
}

deny contains "G-AS-METADATA: iOS display name is missing" if {
	not lib.present(input.app_name_ios)
}

deny contains msg if {
	lib.present(input.app_store_name)
	count(input.app_store_name) > _max_length
	msg := sprintf("G-AS-METADATA: App Store name exceeds %d characters", [_max_length])
}

deny contains msg if {
	lib.present(input.subtitle)
	count(input.subtitle) > _max_length
	msg := sprintf("G-AS-METADATA: subtitle exceeds %d characters", [_max_length])
}

deny contains "G-AS-METADATA: iOS display name differs from the canonical app name" if {
	lib.present(input.app_name_pubspec)
	lib.present(input.app_name_ios)
	input.app_name_pubspec != input.app_name_ios
}

deny contains msg if {
	some term in _foreign_platform_terms
	contains(lower(metadata_text), term)
	msg := sprintf("G-AS-METADATA: metadata contains foreign platform term '%s'", [term])
}

deny contains "G-AS-METADATA: App Store name is missing" if {
	lib.release_profile
	not lib.present(input.app_store_name)
}

deny contains "G-AS-METADATA: metadata review is incomplete" if {
	lib.release_profile
	not input.metadata_review_completed
}

warn contains "G-AS-METADATA: metadata review is pending" if {
	not lib.release_profile
	not input.metadata_review_completed
}

deny contains "G-AS-METADATA: screenshots have not been reviewed" if {
	lib.release_profile
	not input.screenshots_reviewed
}

warn contains "G-AS-METADATA: screenshots review is pending" if {
	not lib.release_profile
	not input.screenshots_reviewed
}

deny contains "G-AS-METADATA: age rating is incomplete" if {
	lib.release_profile
	not input.age_rating_completed
}

warn contains "G-AS-METADATA: age rating is pending" if {
	not lib.release_profile
	not input.age_rating_completed
}

deny contains "G-AS-METADATA: brand and naming rights review is incomplete" if {
	lib.release_profile
	not input.brand_rights_reviewed
}

warn contains "G-AS-METADATA: brand and naming rights review is pending" if {
	not lib.release_profile
	not input.brand_rights_reviewed
}
