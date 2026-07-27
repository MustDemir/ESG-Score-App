#!/usr/bin/env bash
# =============================================================================
# build_compliance_input.sh — merged Kategorie A + B zu compliance_input.json
# =============================================================================
# Merged app_extracted.json (Kategorie A, aus extract_app_metadata.sh) mit
# compliance-manifest.json (Kategorie B, hand-gepflegt) zu einer Input-Datei
# die Conftest prueft.
#
# jq-Merge: Manifest-Felder + extrahierte Felder. Bei Konflikt gewinnt das
# extrahierte (echte) Feld — denn der reale App-Zustand ist Wahrheit, nicht
# die Deklaration. Ausnahme: app_name_pubspec (kanonischer Soll-Name) kommt
# nur aus dem Manifest.
#
# Output: evidence-store/compliance_input.json
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EXTRACTED="${REPO_ROOT}/evidence-store/app_extracted.json"
MANIFEST="${REPO_ROOT}/docs/project/compliance/compliance-manifest.json"
OUT="${REPO_ROOT}/evidence-store/compliance_input.json"
PROFILE="${COMPLIANCE_PROFILE:-development}"

case "$PROFILE" in
  development|release_candidate|submission) ;;
  *)
    echo "Invalid COMPLIANCE_PROFILE '$PROFILE'" >&2
    exit 2
    ;;
esac

# IMMER frisch extrahieren — der reale App-Zustand ist die Wahrheit.
# (Sonst Gefahr von stale Daten, z.B. nach Info.plist-Aenderung.)
bash "${REPO_ROOT}/scripts/compliance/extract_app_metadata.sh" >/dev/null

if [ ! -f "$MANIFEST" ]; then
  echo "❌ compliance-manifest.json fehlt: $MANIFEST"
  exit 1
fi

# Merge: Manifest als Basis, extrahierte Felder ueberschreiben (echte Wahrheit).
# _-praefixierte Doku-Felder aus dem Manifest entfernen.
jq -s --arg profile "$PROFILE" '
  (.[0] | with_entries(select(.key | startswith("_") | not))) as $manifest
  | (.[1] | with_entries(select(.key | startswith("_") | not))) as $extracted
  | $manifest * $extracted
  | . + {
      "compliance_profile": $profile,
      "_built": (now | todate),
      "_source": "build_compliance_input.sh"
    }
' "$MANIFEST" "$EXTRACTED" > "$OUT"

echo "✅ compliance_input.json gebaut → $OUT"
echo "   Felder: $(jq -r 'keys | map(select(startswith("_")|not)) | join(", ")' "$OUT")"
