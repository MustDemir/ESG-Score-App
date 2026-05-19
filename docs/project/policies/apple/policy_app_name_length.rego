# ================================================================
# G-AS-NAME-LENGTH: App-Name-Länge ≤ 30 Zeichen
# ================================================================
# Gate:         G-AS-NAME-LENGTH
# Requirement:  R-AS-12 — Apple App Review 2.3.7, 2.3.10, 5.2.5
# Automation:   AUTO (Conftest validiert App-Metadaten)
# Input:        app_metadata.json (siehe Schema unten)
# Entrypoint:   deny[msg] (Conftest-Konvention)
#
# Schema-Input (JSON):
#   {
#     "app_name_pubspec": "ScanFair",
#     "app_name_ios": "ScanFair",
#     "app_name_android": "ScanFair",
#     "subtitle": "ESG-Score für deinen Einkauf"
#   }
#
# Severity: BLOCK — Apple lehnt App ab wenn Name > 30 Zeichen
# CDV-Pattern: Contract (Name vorhanden) → Validation (Länge) → Severity (BLOCK)
# ================================================================

package scanfair.apple.app_name_length

import rego.v1

# --- Konstanten ---
_max_name_length := 30
_max_subtitle_length := 30

# Plattform-Namen die NICHT in iOS-Metadata vorkommen dürfen (Apple 2.3.10)
_forbidden_platform_names := {
	"android",
	"google play",
	"samsung",
	"windows phone",
	"microsoft store",
	"play store",
	"galaxy store",
}

# Apple-Produkt-Imitations-Verbote (Apple 5.2.5)
_forbidden_apple_imitations := {
	"app store",
	"iphone",
	"ipad",
	"macos",
	"finder",
	"imessage",
}

# --- Rule 1: app_name_pubspec muss existieren ---
deny contains msg if {
	not input.app_name_pubspec
	msg := "G-AS-NAME-LENGTH (R-AS-12): app_name_pubspec fehlt in pubspec.yaml"
}

# --- Rule 2: app_name_pubspec ≤ 30 Zeichen ---
deny contains msg if {
	count(input.app_name_pubspec) > _max_name_length
	msg := sprintf(
		"G-AS-NAME-LENGTH (R-AS-12): app_name_pubspec '%s' ist %d Zeichen — Apple 2.3.7 verbietet > %d",
		[input.app_name_pubspec, count(input.app_name_pubspec), _max_name_length],
	)
}

# --- Rule 3: iOS-Name (Info.plist CFBundleDisplayName) ≤ 30 ---
deny contains msg if {
	input.app_name_ios
	count(input.app_name_ios) > _max_name_length
	msg := sprintf(
		"G-AS-NAME-LENGTH (R-AS-12): iOS CFBundleDisplayName '%s' ist %d Zeichen — Apple 2.3.7 verbietet > %d",
		[input.app_name_ios, count(input.app_name_ios), _max_name_length],
	)
}

# --- Rule 4: Android-Name ≤ 30 (Apple-Regel gilt formal nur iOS,
# aber wir halten konsistent für saubere Cross-Platform-UX) ---
deny contains msg if {
	input.app_name_android
	count(input.app_name_android) > _max_name_length
	msg := sprintf(
		"G-AS-NAME-LENGTH (R-AS-12): Android app-label '%s' ist %d Zeichen — Konsistenz-Bruch zu iOS",
		[input.app_name_android, count(input.app_name_android)],
	)
}

# --- Rule 5: Cross-Platform-Konsistenz ---
deny contains msg if {
	input.app_name_pubspec
	input.app_name_ios
	input.app_name_pubspec != input.app_name_ios
	msg := sprintf(
		"G-AS-NAME-LENGTH (R-AS-12): app_name_pubspec ('%s') ≠ app_name_ios ('%s') — Konsistenz verletzt",
		[input.app_name_pubspec, input.app_name_ios],
	)
}

# --- Rule 6: subtitle (falls vorhanden) ≤ 30 ---
deny contains msg if {
	input.subtitle
	count(input.subtitle) > _max_subtitle_length
	msg := sprintf(
		"G-AS-NAME-LENGTH (R-AS-12): subtitle '%s' ist %d Zeichen — Apple 2.3.7 verbietet > %d",
		[input.subtitle, count(input.subtitle), _max_subtitle_length],
	)
}

# --- Rule 7: iOS-Name darf keine fremden Plattform-Namen enthalten (Apple 2.3.10) ---
deny contains msg if {
	input.app_name_ios
	some forbidden in _forbidden_platform_names
	contains(lower(input.app_name_ios), forbidden)
	msg := sprintf(
		"G-AS-NAME-LENGTH (R-AS-12): iOS-Name '%s' enthält verbotenen Plattform-Namen '%s' — Apple 2.3.10",
		[input.app_name_ios, forbidden],
	)
}

# --- Rule 8: Name darf nicht Apple-Produkt imitieren (Apple 5.2.5) ---
deny contains msg if {
	input.app_name_pubspec
	some forbidden in _forbidden_apple_imitations
	contains(lower(input.app_name_pubspec), forbidden)
	msg := sprintf(
		"G-AS-NAME-LENGTH (R-AS-12): app_name '%s' imitiert Apple-Produkt '%s' — Apple 5.2.5",
		[input.app_name_pubspec, forbidden],
	)
}
