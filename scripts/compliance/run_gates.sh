#!/usr/bin/env bash
# =============================================================================
# run_gates.sh — fuehrt Conftest-Gates aus + schreibt Evidence-Log
# =============================================================================
# 1. Baut compliance_input.json (falls noetig)
# 2. Fuehrt conftest gegen alle Apple-Policies aus
# 3. Schreibt Ergebnis als Eintrag in evidence-store/evidence-log.jsonl
#    mit SHA-256-Hash (Kategorie GCG-3, Solo-Variante der Master-Thesis)
#
# Exit-Code: 0 wenn alle Gates pass, 1 wenn ein Gate Findings hat.
# =============================================================================

set -uo pipefail  # nicht -e: wir wollen conftest-Fehler selbst behandeln

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
INPUT="${REPO_ROOT}/evidence-store/compliance_input.json"
POLICY_DIR="${REPO_ROOT}/docs/project/policies/apple"
EVIDENCE_LOG="${REPO_ROOT}/evidence-store/evidence-log.jsonl"

# 1. Input bauen
bash "${REPO_ROOT}/scripts/compliance/build_compliance_input.sh" >/dev/null

if ! command -v conftest >/dev/null 2>&1; then
  echo "❌ conftest nicht installiert. Install: brew install conftest"
  exit 2
fi

# 2. Conftest ausfuehren (alle Namespaces, JSON-Output)
echo "=== Conftest Gates ==="
RESULT_JSON="$(conftest test "$INPUT" --policy "$POLICY_DIR" --all-namespaces -o json 2>/dev/null || true)"

# Menschen-lesbare Ausgabe
conftest test "$INPUT" --policy "$POLICY_DIR" --all-namespaces 2>/dev/null || true

# 3. Ergebnis aggregieren
FAILURES="$(echo "$RESULT_JSON" | jq '[.[].failures[]?] | length' 2>/dev/null || echo 0)"
WARNINGS="$(echo "$RESULT_JSON" | jq '[.[].warnings[]?] | length' 2>/dev/null || echo 0)"
GATE_RESULT="PASS"
[ "${FAILURES:-0}" -gt 0 ] && GATE_RESULT="FAIL"

# 4. Evidence-Log-Eintrag mit SHA-256-Chain
PREV_HASH="$(tail -1 "$EVIDENCE_LOG" 2>/dev/null | jq -r '.entry_hash // "GENESIS"' 2>/dev/null || echo "GENESIS")"
INPUT_HASH="$(shasum -a 256 "$INPUT" 2>/dev/null | awk '{print $1}' || echo "")"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

ENTRY="$(jq -nc \
  --arg ts "$TS" \
  --arg result "$GATE_RESULT" \
  --argjson failures "${FAILURES:-0}" \
  --argjson warnings "${WARNINGS:-0}" \
  --arg input_hash "$INPUT_HASH" \
  --arg prev "$PREV_HASH" \
  --argjson detail "$(echo "$RESULT_JSON" | jq '[.[] | {namespace, failures: [.failures[]?.msg], warnings: [.warnings[]?.msg]}]' 2>/dev/null || echo '[]')" \
  '{timestamp:$ts, gate_result:$result, failures:$failures, warnings:$warnings, input_sha256:$input_hash, prev_entry_hash:$prev, detail:$detail}')"

# entry_hash = sha256 des Eintrags ohne entry_hash-Feld
ENTRY_HASH="$(echo -n "$ENTRY" | shasum -a 256 | awk '{print $1}')"
echo "$ENTRY" | jq -c --arg h "$ENTRY_HASH" '. + {entry_hash:$h}' >> "$EVIDENCE_LOG"

echo ""
echo "=== Ergebnis: $GATE_RESULT ($FAILURES Findings, $WARNINGS Warnungen) ==="
echo "Evidence-Log-Eintrag geschrieben (hash ${ENTRY_HASH:0:12}...)"

[ "$GATE_RESULT" = "PASS" ] && exit 0 || exit 1
