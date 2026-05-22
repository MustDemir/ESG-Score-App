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

# --- Extraktion ---
PUBSPEC_PACKAGE="$(grep -m1 '^name:' "$PUBSPEC" 2>/dev/null | sed -E 's/name:[[:space:]]*//' | tr -d '\r' || echo "")"
IOS_NAME="$(plist_get CFBundleDisplayName)"
[ -z "$IOS_NAME" ] && IOS_NAME="$(plist_get CFBundleName)"
ANDROID_NAME="$(grep -m1 'android:label=' "$ANDROID_MANIFEST" 2>/dev/null | sed -E 's/.*android:label="([^"]*)".*/\1/' || echo "")"
CAMERA="$(plist_get NSCameraUsageDescription)"
ATS_RAW="$(plist_get NSAppTransportSecurity || true)"  # nested, meist leer
PRIVACY_PRESENT=false
[ -f "$PRIVACY_MANIFEST" ] && PRIVACY_PRESENT=true

# Android cleartext (default true wenn nicht gesetzt; modern target = false)
ANDROID_CLEARTEXT="$(grep -o 'android:usesCleartextTraffic="[^"]*"' "$ANDROID_MANIFEST" 2>/dev/null | sed -E 's/.*"([^"]*)".*/\1/' | head -1 || echo "")"

mkdir -p "$(dirname "$OUT")"

jq -n \
  --arg pkg "$PUBSPEC_PACKAGE" \
  --arg ios "$IOS_NAME" \
  --arg android "$ANDROID_NAME" \
  --arg cam "$CAMERA" \
  --arg cleartext "$ANDROID_CLEARTEXT" \
  --argjson privacy "$PRIVACY_PRESENT" \
  '{
    "_source": "extract_app_metadata.sh (Kategorie A)",
    "app_name_pubspec_package": $pkg,
    "app_name_ios": $ios,
    "app_name_android": $android,
    "camera_purpose_string": (if $cam == "" then null else $cam end),
    "android_uses_cleartext_traffic": (if $cleartext == "" then null else ($cleartext == "true") end),
    "privacy_manifest_present": $privacy
  }' > "$OUT"

echo "✅ Kategorie A extrahiert → $OUT"
echo "   ios_name='$IOS_NAME'  android_name='$ANDROID_NAME'  camera=$([ -z "$CAMERA" ] && echo MISSING || echo SET)  privacy_manifest=$PRIVACY_PRESENT"
