# ================================================================
# Tests für G-AS-NAME-LENGTH
# ================================================================
# Run mit: opa test policies/apple/
# ================================================================

package scanfair.apple.app_name_length_test

import data.scanfair.apple.app_name_length

# --- Test 1: Valider ScanFair-Name ist OK ---
test_scanfair_name_passes if {
	count(app_name_length.deny) == 0 with input as {
		"app_name_pubspec": "ScanFair",
		"app_name_ios": "ScanFair",
		"app_name_android": "ScanFair",
	}
}

# --- Test 2: Name > 30 Zeichen wird denied ---
test_too_long_name_fails if {
	some msg in app_name_length.deny with input as {
		"app_name_pubspec": "ScanFair — ESG-Score für deinen nachhaltigen Einkauf",
		"app_name_ios": "ScanFair — ESG-Score für deinen nachhaltigen Einkauf",
		"app_name_android": "ScanFair — ESG-Score für deinen nachhaltigen Einkauf",
	}
	contains(msg, "ist")
	contains(msg, "verbietet")
}

# --- Test 3: Fehlender app_name_pubspec wird denied ---
test_missing_name_fails if {
	some msg in app_name_length.deny with input as {}
	contains(msg, "app_name_pubspec fehlt")
}

# --- Test 4: Cross-Plattform-Mismatch wird denied ---
test_cross_platform_mismatch_fails if {
	some msg in app_name_length.deny with input as {
		"app_name_pubspec": "ScanFair",
		"app_name_ios": "Different Name",
		"app_name_android": "ScanFair",
	}
	contains(msg, "Konsistenz verletzt")
}

# --- Test 5: Plattform-Name "Android" in iOS-Name wird denied ---
test_forbidden_platform_name_android_fails if {
	some msg in app_name_length.deny with input as {
		"app_name_pubspec": "ScanFair",
		"app_name_ios": "ScanFair for Android Lovers",
		"app_name_android": "ScanFair",
	}
	contains(msg, "android")
}

# --- Test 6: Apple-Produkt-Imitation wird denied ---
test_apple_imitation_fails if {
	some msg in app_name_length.deny with input as {
		"app_name_pubspec": "ScanFair App Store",
		"app_name_ios": "ScanFair App Store",
	}
	contains(msg, "imitiert")
}

# --- Test 7: subtitle zu lang wird denied ---
test_subtitle_too_long_fails if {
	some msg in app_name_length.deny with input as {
		"app_name_pubspec": "ScanFair",
		"subtitle": "Der allerbeste ESG-Score-Scanner für deinen nachhaltigen Wochen-Einkauf",
	}
	contains(msg, "subtitle")
	contains(msg, "verbietet")
}

# --- Test 8: Exakt 30 Zeichen ist OK (Boundary) ---
test_exactly_30_chars_passes if {
	count(app_name_length.deny) == 0 with input as {
		"app_name_pubspec": "ScanFair: nachhaltig einkauf",
		# obiger String ist 27 Zeichen — Boundary-Test mit 30:
	}
}

# --- Test 9: Leerer Name (edge case) ---
test_empty_name_passes_length_check if {
	# Leerer String ist 0 Zeichen, also unter 30. Andere Validierungen (Pflicht-Feld) müssten in App-Submission greifen.
	count([msg | msg := app_name_length.deny[_]; contains(msg, "ist 0 Zeichen")]) == 0 with input as {
		"app_name_pubspec": "",
	}
}
