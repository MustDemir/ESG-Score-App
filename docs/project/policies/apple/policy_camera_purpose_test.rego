package scanfair.apple.camera_purpose_test

import data.scanfair.apple.camera_purpose

test_specific_camera_purpose_passes if {
	count(camera_purpose.deny) == 0 with input as {"camera_purpose_string": "ScanFair scannt mit der Kamera Barcodes auf Produkten, um den ESG-Score anzuzeigen. Es werden keine Bilder gespeichert oder übertragen."}
}

test_missing_camera_purpose_fails if {
	some msg in camera_purpose.deny with input as {}
	contains(msg, "fehlt")
}

test_short_camera_purpose_fails if {
	some msg in camera_purpose.deny with input as {"camera_purpose_string": "Barcode scannen"}
	contains(msg, "zu kurz")
}

test_missing_domain_context_fails if {
	some msg in camera_purpose.deny with input as {"camera_purpose_string": "ScanFair verwendet die Kamera. Es werden keine Bilder gespeichert oder übertragen."}
	contains(msg, "weder Barcode, Scan noch Produkt")
}

test_missing_data_handling_fails if {
	some msg in camera_purpose.deny with input as {"camera_purpose_string": "ScanFair verwendet die Kamera, um Barcodes auf Produkten zu scannen und den ESG-Score anzuzeigen."}
	contains(msg, "Datenverarbeitung")
}

test_generic_camera_purpose_fails if {
	some msg in camera_purpose.deny with input as {"camera_purpose_string": "ScanFair benötigt Kamerazugriff, um Barcodes auf Produkten zu scannen. Es werden keine Bilder gespeichert."}
	contains(msg, "generische Formulierung")
}
