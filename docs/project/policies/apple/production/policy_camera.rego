package scanfair.apple.g_as_camera

import rego.v1
import data.scanfair.apple.lib

has_camera_context if {
	lib.present(input.camera_purpose_string)
	regex.match(`(?i)\b(barcode|barcodes|scan|scannen|scannt|scanner|produkt|produkten)\b`, input.camera_purpose_string)
}

deny contains "G-AS-CAMERA: NSCameraUsageDescription is missing" if {
	not lib.present(input.camera_purpose_string)
}

deny contains "G-AS-CAMERA: camera purpose text does not explain the barcode/product use" if {
	lib.present(input.camera_purpose_string)
	not has_camera_context
}

deny contains "G-AS-CAMERA: runtime consent and recording-indicator review is incomplete" if {
	lib.release_profile
	not input.camera_runtime_review_completed
}

warn contains "G-AS-CAMERA: runtime consent and recording-indicator review is pending" if {
	not lib.release_profile
	not input.camera_runtime_review_completed
}

deny contains "G-AS-CAMERA: manual barcode fallback has not been verified" if {
	lib.release_profile
	not input.camera_manual_fallback_verified
}

warn contains "G-AS-CAMERA: camera purpose localization review is pending" if {
	not lib.release_profile
	not input.camera_localizations_reviewed
}

deny contains "G-AS-CAMERA: camera purpose localizations are incomplete" if {
	lib.release_profile
	not input.camera_localizations_reviewed
}
