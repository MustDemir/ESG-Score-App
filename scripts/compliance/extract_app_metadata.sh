#!/usr/bin/env bash
# =============================================================================
# extract_app_metadata.sh — Kategorie-A-Extraktion
# =============================================================================
# Liest echte App-Files und erzeugt app_extracted.json (Kategorie A).
# Cross-platform: plutil (macOS) ODER python3 plistlib (Linux/CI) ODER grep-Fallback.
#
# Bezug: docs/project/compliance/evidence-model.md
# Output: evidence-store/app_extracted.json
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP="${REPO_ROOT}/esg_app"
PLIST="${APP}/ios/Runner/Info.plist"
ANDROID_MANIFEST="${APP}/android/app/src/main/AndroidManifest.xml"
PUBSPEC="${APP}/pubspec.yaml"
PRIVACY_MANIFEST="${APP}/ios/Runner/PrivacyInfo.xcprivacy"
PLUGIN_REGISTRANT="${APP}/ios/Runner/GeneratedPluginRegistrant.m"
PUBSPEC_LOCK="${APP}/pubspec.lock"
IOS_PRIVACY_REVIEW="${REPO_ROOT}/docs/project/compliance/ios-privacy-sdk-review.json"
SCORING_MODEL="${REPO_ROOT}/docs/ESG-SCORING-MODELL-v1.md"
LICENSE_DOC="${REPO_ROOT}/docs/licenses.md"
PRIVACY_DOC="${REPO_ROOT}/docs/privacy.md"
OUT="${REPO_ROOT}/evidence-store/app_extracted.json"

# ---------------------------------------------------------------------------
# plist_get KEY — liest einen Top-Level-String-Key aus Info.plist.
# Reihenfolge: plutil (macOS) -> python plistlib (Linux) -> grep-Fallback.
# Gibt leeren String zurueck wenn Key fehlt.
# ---------------------------------------------------------------------------
plist_get() {
  local key="$1"
  local val=""
  if command -v plutil >/dev/null 2>&1; then
    val="$(plutil -extract "$key" raw -o - "$PLIST" 2>/dev/null || true)"
  fi
  if [ -z "$val" ] && command -v python3 >/dev/null 2>&1 && python3 -c "import plistlib" >/dev/null 2>&1; then
    val="$(python3 -c "import plistlib;d=plistlib.load(open('$PLIST','rb'));print(d.get('$key',''))" 2>/dev/null || true)"
  fi
  if [ -z "$val" ]; then
    # grep-Fallback fuer XML-Plist: <key>NAME</key><string>VALUE</string>
    val="$(grep -A1 "<key>${key}</key>" "$PLIST" 2>/dev/null | grep '<string>' | sed -E 's/.*<string>(.*)<\/string>.*/\1/' | head -1 || true)"
  fi
  echo "$val"
}

sha256_file() {
  local file="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$file" | awk '{print $NF}'
  else
    return 1
  fi
}

# --- Extraktion ---
PUBSPEC_PACKAGE="$(grep -m1 '^name:' "$PUBSPEC" 2>/dev/null | sed -E 's/name:[[:space:]]*//' | tr -d '\r' || echo "")"
IOS_NAME="$(plist_get CFBundleDisplayName)"
[ -z "$IOS_NAME" ] && IOS_NAME="$(plist_get CFBundleName)"
ANDROID_NAME="$(grep -m1 'android:label=' "$ANDROID_MANIFEST" 2>/dev/null | sed -E 's/.*android:label="([^"]*)".*/\1/' || echo "")"
CAMERA="$(plist_get NSCameraUsageDescription)"
PRIVACY_PRESENT=false
[ -f "$PRIVACY_MANIFEST" ] && PRIVACY_PRESENT=true
PRIVACY_VALID=false
if [ "$PRIVACY_PRESENT" = true ]; then
  if command -v plutil >/dev/null 2>&1 && plutil -lint "$PRIVACY_MANIFEST" >/dev/null 2>&1; then
    PRIVACY_VALID=true
  elif command -v python3 >/dev/null 2>&1 && python3 -c "import plistlib; plistlib.load(open('$PRIVACY_MANIFEST', 'rb'))" >/dev/null 2>&1; then
    PRIVACY_VALID=true
  fi
fi

IOS_PRIVACY_REVIEW_PRESENT=false
[ -f "$IOS_PRIVACY_REVIEW" ] && IOS_PRIVACY_REVIEW_PRESENT=true
IOS_PRIVACY_REVIEW_CURRENT=false
REQUIRED_REASON_REVIEW=false
THIRD_PARTY_SDK_REVIEW=false
LISTED_BINARY_SDK_SIGNATURE_REVIEW=false
IOS_PRIVACY_REVIEW_ID=""
if [ "$IOS_PRIVACY_REVIEW_PRESENT" = true ] \
  && [ -f "$PUBSPEC_LOCK" ] \
  && [ -f "$PRIVACY_MANIFEST" ] \
  && [ -f "$PLUGIN_REGISTRANT" ]; then
  CURRENT_LOCK_HASH="$(sha256_file "$PUBSPEC_LOCK" || true)"
  CURRENT_PRIVACY_HASH="$(sha256_file "$PRIVACY_MANIFEST" || true)"
  CURRENT_REGISTRANT_HASH="$(sha256_file "$PLUGIN_REGISTRANT" || true)"
  IOS_PRIVACY_REVIEW_ID="$(jq -r '.review_id // ""' "$IOS_PRIVACY_REVIEW")"
  if jq -e \
    --arg lock_hash "$CURRENT_LOCK_HASH" \
    --arg privacy_hash "$CURRENT_PRIVACY_HASH" \
    --arg registrant_hash "$CURRENT_REGISTRANT_HASH" \
    '
      .decision.status == "approved_for_current_dependency_set"
      and .reviewed_inputs.pubspec_lock.sha256 == $lock_hash
      and .reviewed_inputs.app_privacy_manifest.sha256 == $privacy_hash
      and .reviewed_inputs.generated_plugin_registrant.sha256 == $registrant_hash
    ' "$IOS_PRIVACY_REVIEW" >/dev/null; then
    IOS_PRIVACY_REVIEW_CURRENT=true
    REQUIRED_REASON_REVIEW="$(jq -r '.review_outcome.required_reason_api_review_completed == true' "$IOS_PRIVACY_REVIEW")"
    THIRD_PARTY_SDK_REVIEW="$(jq -r '.review_outcome.third_party_sdk_privacy_review_completed == true' "$IOS_PRIVACY_REVIEW")"
    LISTED_BINARY_SDK_SIGNATURE_REVIEW="$(jq -r '.review_outcome.listed_binary_sdk_signature_validation_completed == true' "$IOS_PRIVACY_REVIEW")"
  fi
fi

SCORING_MODEL_PRESENT=false
[ -f "$SCORING_MODEL" ] && SCORING_MODEL_PRESENT=true
LICENSE_DOC_PRESENT=false
[ -f "$LICENSE_DOC" ] && LICENSE_DOC_PRESENT=true
PRIVACY_DOC_PRESENT=false
[ -f "$PRIVACY_DOC" ] && PRIVACY_DOC_PRESENT=true
OFF_ATTRIBUTION_PRESENT=false
if grep -RiqE 'Powered by Open Food Facts|Product data.*Open Food Facts|Produktdaten.*Open Food Facts' "${APP}/lib" 2>/dev/null; then
  OFF_ATTRIBUTION_PRESENT=true
fi

# Android cleartext (default true wenn nicht gesetzt; modern target = false)
ANDROID_CLEARTEXT="$(grep -o 'android:usesCleartextTraffic="[^"]*"' "$ANDROID_MANIFEST" 2>/dev/null | sed -E 's/.*"([^"]*)".*/\1/' | head -1 || echo "")"

mkdir -p "$(dirname "$OUT")"

jq -n \
  --arg pkg "$PUBSPEC_PACKAGE" \
  --arg ios "$IOS_NAME" \
  --arg android "$ANDROID_NAME" \
  --arg cam "$CAMERA" \
  --arg cleartext "$ANDROID_CLEARTEXT" \
  --arg privacy_review_id "$IOS_PRIVACY_REVIEW_ID" \
  --argjson privacy "$PRIVACY_PRESENT" \
  --argjson privacy_valid "$PRIVACY_VALID" \
  --argjson privacy_review_present "$IOS_PRIVACY_REVIEW_PRESENT" \
  --argjson privacy_review_current "$IOS_PRIVACY_REVIEW_CURRENT" \
  --argjson required_reason_review "$REQUIRED_REASON_REVIEW" \
  --argjson third_party_sdk_review "$THIRD_PARTY_SDK_REVIEW" \
  --argjson listed_binary_sdk_signature_review "$LISTED_BINARY_SDK_SIGNATURE_REVIEW" \
  --argjson scoring_model "$SCORING_MODEL_PRESENT" \
  --argjson license_doc "$LICENSE_DOC_PRESENT" \
  --argjson privacy_doc "$PRIVACY_DOC_PRESENT" \
  --argjson off_attribution "$OFF_ATTRIBUTION_PRESENT" \
  '{
    "_source": "extract_app_metadata.sh (Kategorie A)",
    "app_name_pubspec_package": $pkg,
    "app_name_ios": $ios,
    "app_name_android": $android,
    "camera_purpose_string": (if $cam == "" then null else $cam end),
    "android_uses_cleartext_traffic": (if $cleartext == "" then null else ($cleartext == "true") end),
    "privacy_manifest_present": $privacy,
    "privacy_manifest_valid": $privacy_valid,
    "ios_privacy_review_record_present": $privacy_review_present,
    "ios_privacy_review_current": $privacy_review_current,
    "ios_privacy_review_id": (if $privacy_review_id == "" then null else $privacy_review_id end),
    "required_reason_api_review_completed": $required_reason_review,
    "third_party_sdk_privacy_review_completed": $third_party_sdk_review,
    "listed_binary_sdk_signature_validation_completed": $listed_binary_sdk_signature_review,
    "scoring_methodology_document_present": $scoring_model,
    "license_document_present": $license_doc,
    "privacy_document_present": $privacy_doc,
    "off_attribution_in_app_present": $off_attribution
  }' > "$OUT"

echo "✅ Kategorie A extrahiert → $OUT"
echo "   ios_name='$IOS_NAME'  android_name='$ANDROID_NAME'  camera=$([ -z "$CAMERA" ] && echo MISSING || echo SET)  privacy_manifest=$PRIVACY_PRESENT/$PRIVACY_VALID  privacy_review_current=$IOS_PRIVACY_REVIEW_CURRENT"
