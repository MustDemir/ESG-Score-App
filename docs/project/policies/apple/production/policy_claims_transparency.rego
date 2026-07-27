package scanfair.apple.g_as_claims_transparency

import rego.v1
import data.scanfair.apple.lib

deny contains "G-AS-CLAIMS-TRANSPARENCY: scoring methodology document is missing" if {
	not input.scoring_methodology_document_present
}

deny contains "G-AS-CLAIMS-TRANSPARENCY: ESG data sources are not disclosed in the app" if {
	lib.release_profile
	not input.esg_sources_disclosed_in_app
}

warn contains "G-AS-CLAIMS-TRANSPARENCY: ESG data-source disclosure must be verified before release" if {
	not lib.release_profile
	not input.esg_sources_disclosed_in_app
}

deny contains "G-AS-CLAIMS-TRANSPARENCY: ESG score limitations are not disclosed in the app" if {
	lib.release_profile
	not input.esg_limitations_disclosed_in_app
}

warn contains "G-AS-CLAIMS-TRANSPARENCY: ESG score limitations disclosure is pending" if {
	not lib.release_profile
	not input.esg_limitations_disclosed_in_app
}

deny contains "G-AS-CLAIMS-TRANSPARENCY: manual truthfulness and substantiation review is incomplete" if {
	lib.release_profile
	not input.esg_claims_manual_review_completed
}

warn contains "G-AS-CLAIMS-TRANSPARENCY: manual truthfulness and substantiation review is pending" if {
	not lib.release_profile
	not input.esg_claims_manual_review_completed
}
