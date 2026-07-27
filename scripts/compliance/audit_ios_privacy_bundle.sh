#!/usr/bin/env bash
# Audit the privacy manifests embedded in the built iOS app bundle.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_DIR="$REPO_ROOT/esg_app"
APP_BUNDLE="${1:-$APP_DIR/build/ios/iphonesimulator/Runner.app}"
SOURCE_MANIFEST="$APP_DIR/ios/Runner/PrivacyInfo.xcprivacy"
MANIFEST_DECLARATIONS="$REPO_ROOT/docs/project/compliance/compliance-manifest.json"
OUT="$REPO_ROOT/evidence-store/ios_privacy_audit.json"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "iOS privacy bundle audit requires macOS."
  exit 2
fi

for command in plutil jq shasum codesign; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Required command is missing: $command"
    exit 2
  fi
done

if [ ! -d "$APP_BUNDLE" ]; then
  echo "Built app bundle is missing: $APP_BUNDLE"
  exit 1
fi

if [ ! -f "$SOURCE_MANIFEST" ]; then
  echo "Source PrivacyInfo.xcprivacy is missing."
  exit 1
fi

if ! plutil -lint "$SOURCE_MANIFEST" >/dev/null; then
  echo "Source PrivacyInfo.xcprivacy is invalid."
  exit 1
fi

ROOT_MANIFEST="$APP_BUNDLE/PrivacyInfo.xcprivacy"
FLUTTER_MANIFEST="$APP_BUNDLE/Frameworks/Flutter.framework/PrivacyInfo.xcprivacy"

if [ ! -f "$ROOT_MANIFEST" ]; then
  echo "App PrivacyInfo.xcprivacy is not embedded at bundle root."
  exit 1
fi

if [ ! -f "$FLUTTER_MANIFEST" ]; then
  echo "Flutter.framework privacy manifest is missing."
  exit 1
fi

if grep -q "mobile_scanner" "$APP_DIR/ios/Runner/GeneratedPluginRegistrant.m"; then
  if ! find "$APP_BUNDLE" -path '*mobile_scanner*.bundle/PrivacyInfo.xcprivacy' -print -quit | grep -q .; then
    echo "mobile_scanner is registered but its privacy manifest is not embedded."
    exit 1
  fi
fi

MANIFEST_LIST="$(find "$APP_BUNDLE" -name PrivacyInfo.xcprivacy -type f -print | sort)"
if [ -z "$MANIFEST_LIST" ]; then
  echo "No privacy manifests found in app bundle."
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
MANIFEST_RECORDS="$TMP_DIR/manifests.jsonl"
SIGNATURE_RECORDS="$TMP_DIR/framework-signatures.jsonl"
VIOLATIONS="$TMP_DIR/violations.txt"
: >"$MANIFEST_RECORDS"
: >"$SIGNATURE_RECORDS"
: >"$VIOLATIONS"

while IFS= read -r manifest; do
  if ! plutil -lint "$manifest" >/dev/null; then
    printf 'Invalid plist: %s\n' "$manifest" >>"$VIOLATIONS"
    continue
  fi

  manifest_json="$(plutil -convert json -o - "$manifest")"
  relative_path="${manifest#"$APP_BUNDLE"/}"

  if ! printf '%s' "$manifest_json" | jq -e '
    (.NSPrivacyTracking | type) == "boolean"
    and (.NSPrivacyTrackingDomains | type) == "array"
    and (.NSPrivacyCollectedDataTypes | type) == "array"
    and (.NSPrivacyAccessedAPITypes | type) == "array"
  ' >/dev/null; then
    printf 'Incomplete privacy manifest schema: %s\n' "$relative_path" >>"$VIOLATIONS"
  fi

  if ! printf '%s' "$manifest_json" | jq -e '
    all(.NSPrivacyAccessedAPITypes[]?;
      (.NSPrivacyAccessedAPIType | type) == "string"
      and (.NSPrivacyAccessedAPITypeReasons | type) == "array"
      and (.NSPrivacyAccessedAPITypeReasons | length) > 0)
  ' >/dev/null; then
    printf 'Required-reason API without reason: %s\n' "$relative_path" >>"$VIOLATIONS"
  fi

  jq -nc \
    --arg path "$relative_path" \
    --arg sha "$(shasum -a 256 "$manifest" | awk '{print $1}')" \
    --argjson manifest "$manifest_json" \
    '{
      path: $path,
      sha256: $sha,
      tracking: $manifest.NSPrivacyTracking,
      tracking_domains: $manifest.NSPrivacyTrackingDomains,
      collected_data_types: $manifest.NSPrivacyCollectedDataTypes,
      accessed_api_types: $manifest.NSPrivacyAccessedAPITypes
    }' >>"$MANIFEST_RECORDS"
done <<<"$MANIFEST_LIST"

FRAMEWORK_LIST="$(find "$APP_BUNDLE/Frameworks" -maxdepth 1 -name '*.framework' -type d -print | sort)"
while IFS= read -r framework; do
  [ -n "$framework" ] || continue
  relative_path="${framework#"$APP_BUNDLE"/}"
  signature_valid=false
  if codesign --verify --verbose=2 "$framework" >/dev/null 2>&1; then
    signature_valid=true
  else
    printf 'Invalid bundled framework signature: %s\n' "$relative_path" >>"$VIOLATIONS"
  fi

  signature_details="$(codesign -d --verbose=4 "$framework" 2>&1 || true)"
  identifier="$(printf '%s\n' "$signature_details" | sed -n 's/^Identifier=//p' | head -1)"
  signature_kind="$(printf '%s\n' "$signature_details" | sed -n 's/^Signature=//p' | head -1)"
  team_identifier="$(printf '%s\n' "$signature_details" | sed -n 's/^TeamIdentifier=//p' | head -1)"

  jq -nc \
    --arg path "$relative_path" \
    --arg identifier "$identifier" \
    --arg signature_kind "$signature_kind" \
    --arg team_identifier "$team_identifier" \
    --argjson valid "$signature_valid" \
    '{
      path: $path,
      identifier: (if $identifier == "" then null else $identifier end),
      signature_kind: (if $signature_kind == "" then null else $signature_kind end),
      team_identifier: (if $team_identifier == "" then null else $team_identifier end),
      valid_on_disk: $valid
    }' >>"$SIGNATURE_RECORDS"
done <<<"$FRAMEWORK_LIST"

DECLARED_TRACKING="$(jq -r '.feature_tracking_enabled' "$MANIFEST_DECLARATIONS")"
TRACKING_MANIFESTS="$(jq -s '[.[] | select(.tracking == true)] | length' "$MANIFEST_RECORDS")"
if [ "$DECLARED_TRACKING" = "false" ] && [ "$TRACKING_MANIFESTS" -gt 0 ]; then
  echo "A bundled manifest declares tracking while ScanFair declares tracking disabled." >>"$VIOLATIONS"
fi

MANIFESTS_JSON="$(jq -s '.' "$MANIFEST_RECORDS")"
SIGNATURES_JSON="$(jq -s '.' "$SIGNATURE_RECORDS")"
ACCESSED_APIS="$(printf '%s' "$MANIFESTS_JSON" | jq '[.[].accessed_api_types[]?]')"
VIOLATION_COUNT="$(grep -c . "$VIOLATIONS" || true)"

jq -n \
  --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg app_bundle "$APP_BUNDLE" \
  --arg source_manifest_sha "$(shasum -a 256 "$SOURCE_MANIFEST" | awk '{print $1}')" \
  --arg declared_tracking "$DECLARED_TRACKING" \
  --argjson manifests "$MANIFESTS_JSON" \
  --argjson framework_signatures "$SIGNATURES_JSON" \
  --argjson accessed_apis "$ACCESSED_APIS" \
  --argjson violation_count "$VIOLATION_COUNT" \
  --rawfile violation_text "$VIOLATIONS" \
  '{
    schema_version: "1.0",
    generated_at: $generated_at,
    app_bundle: $app_bundle,
    source_manifest_sha256: $source_manifest_sha,
    declared_tracking_enabled: ($declared_tracking == "true"),
    manifest_count: ($manifests | length),
    manifests: $manifests,
    framework_signature_checks: $framework_signatures,
    aggregate_accessed_api_types: $accessed_apis,
    violation_count: $violation_count,
    violations: ($violation_text | split("\n") | map(select(length > 0))),
    decision: (if $violation_count == 0 then "PASS" else "FAIL" end)
  }' >"$OUT"

jq . "$OUT"

if [ "$VIOLATION_COUNT" -gt 0 ]; then
  echo "G-IOS-PRIVACY-MANIFEST FAIL: $VIOLATION_COUNT violation(s)."
  exit 1
fi

echo "G-IOS-PRIVACY-MANIFEST PASS: all bundled privacy manifests are valid."
