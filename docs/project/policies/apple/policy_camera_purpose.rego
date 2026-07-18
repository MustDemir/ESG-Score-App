package scanfair.apple.camera_purpose

import rego.v1

_minimum_length := 50
_data_handling_keywords := {"bild", "gespeichert", "uebertragen", "übertragen"}
_generic_phrases := {"kamerazugriff", "camera access"}

has_domain_keyword if {
	regex.match(
		`\b(barcode|barcodes|scan|scannen|scannt|scanner|produkt|produkten)\b`,
		lower(input.camera_purpose_string),
	)
}

has_data_handling_keyword if {
	some keyword in _data_handling_keywords
	contains(lower(input.camera_purpose_string), keyword)
}

deny contains msg if {
	not input.camera_purpose_string
	msg := "G-AS-CAMERA-PURPOSE (R-AS-03): NSCameraUsageDescription fehlt"
}

deny contains msg if {
	input.camera_purpose_string
	count(input.camera_purpose_string) < _minimum_length
	msg := sprintf(
		"G-AS-CAMERA-PURPOSE (R-AS-03): Kamera-Zwecktext ist mit %d Zeichen zu kurz; mindestens %d erforderlich",
		[count(input.camera_purpose_string), _minimum_length],
	)
}

deny contains msg if {
	input.camera_purpose_string
	not has_domain_keyword
	msg := "G-AS-CAMERA-PURPOSE (R-AS-03): Kamera-Zwecktext nennt weder Barcode, Scan noch Produkt"
}

deny contains msg if {
	input.camera_purpose_string
	not has_data_handling_keyword
	msg := "G-AS-CAMERA-PURPOSE (R-AS-03): Kamera-Zwecktext erklaert die Bild-/Datenverarbeitung nicht"
}

deny contains msg if {
	input.camera_purpose_string
	some phrase in _generic_phrases
	contains(lower(input.camera_purpose_string), phrase)
	msg := sprintf(
		"G-AS-CAMERA-PURPOSE (R-AS-03): generische Formulierung '%s' ist nicht erlaubt",
		[phrase],
	)
}
