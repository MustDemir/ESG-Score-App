#!/usr/bin/env bash
# =============================================================================
# run_gates.sh — fuehrt Conftest-Gates aus + schreibt Evidence-Log
# =============================================================================
# 1. Baut compliance_input.json (falls noetig)
# 2. Fuehrt conftest ausschliesslich gegen produktive Apple-Policies aus
# 3. Schreibt ein Evidence-Log mit Einzelentscheidungen und SHA-256-Hash-Chain
#
# Exit-Code: 0 wenn alle Gates pass, 1 wenn ein Gate Findings hat.
# =============================================================================

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
INPUT="${REPO_ROOT}/evidence-store/compliance_input.json"
POLICY_DIR="${REPO_ROOT}/docs/project/policies/apple/production"
GATE_DIR="${REPO_ROOT}/docs/project/gate-definitions/apple"
EVIDENCE_LOG="${REPO_ROOT}/evidence-store/evidence-log.jsonl"
LATEST_RESULT="${REPO_ROOT}/evidence-store/latest-gate-results.json"
SUMMARY="${REPO_ROOT}/.quality/compliance-gate-summary.md"
ERROR_LOG="${REPO_ROOT}/.quality/logs/conftest.stderr.log"
PROFILE="${COMPLIANCE_PROFILE:-development}"

case "$PROFILE" in
  development|release_candidate|submission) ;;
  *)
    echo "Invalid COMPLIANCE_PROFILE '$PROFILE'. Expected development, release_candidate or submission."
    exit 2
    ;;
esac

mkdir -p "$(dirname "$EVIDENCE_LOG")" "$(dirname "$SUMMARY")" "$(dirname "$ERROR_LOG")"

# 1. Input bauen
COMPLIANCE_PROFILE="$PROFILE" bash "${REPO_ROOT}/scripts/compliance/build_compliance_input.sh" >/dev/null

if ! command -v conftest >/dev/null 2>&1; then
  echo "conftest is not installed. Install with: brew install conftest"
  exit 2
fi

# 2. Conftest genau einmal ausfuehren. Policy-Findings liefern Exit 1; technische
# Fehler oder ungueltiges JSON duerfen niemals als PASS interpretiert werden.
echo "=== Conftest Apple gates (profile: $PROFILE) ==="
set +e
RESULT_JSON="$(conftest test "$INPUT" --policy "$POLICY_DIR" --all-namespaces -o json 2>"$ERROR_LOG")"
CONFTEST_EXIT=$?
set -e

if ! printf '%s' "$RESULT_JSON" | jq -e 'type == "array"' >/dev/null 2>&1; then
  echo "Conftest returned invalid JSON (exit $CONFTEST_EXIT)."
  cat "$ERROR_LOG"
  exit 2
fi

# 3. Ergebnis aggregieren
FAILURES="$(printf '%s' "$RESULT_JSON" | jq '[.[].failures[]?] | length')"
WARNINGS="$(printf '%s' "$RESULT_JSON" | jq '[.[].warnings[]?] | length')"

if [ "$CONFTEST_EXIT" -ne 0 ] && [ "$FAILURES" -eq 0 ]; then
  echo "Conftest failed technically without policy findings (exit $CONFTEST_EXIT)."
  cat "$ERROR_LOG"
  exit 2
fi

GATE_RESULT="PASS"
[ "$FAILURES" -gt 0 ] && GATE_RESULT="FAIL"

EXPECTED_GATES="$(find "$GATE_DIR" -type f -name 'G-AS-*.yaml' -exec basename {} .yaml \; | sort | jq -Rsc 'split("\n") | map(select(length > 0))')"
if [ "$(printf '%s' "$EXPECTED_GATES" | jq 'length')" -ne 8 ]; then
  echo "Expected exactly eight Apple gate definitions."
  exit 2
fi

PER_GATE="$(printf '%s' "$RESULT_JSON" | jq --argjson expected "$EXPECTED_GATES" '
  [ $expected[] as $gate_id
    | ("scanfair.apple." + ($gate_id | ascii_downcase | gsub("-"; "_"))) as $namespace
    | ([.[] | select(.namespace == $namespace)][0]
       // {namespace: $namespace, failures: [], warnings: []}) as $result
    | {
        gate_id: $gate_id,
        namespace: $namespace,
        status: (if (($result.failures // []) | length) > 0 then "FAIL"
                 elif (($result.warnings // []) | length) > 0 then "WARN"
                 else "PASS" end),
        failures: [($result.failures // [])[] | (.msg // .)],
        warnings: [($result.warnings // [])[] | (.msg // .)]
      }
  ] | sort_by(.gate_id)
')"

printf '%s\n' "$PER_GATE" | jq .

# 4. Evidence-Log-Eintrag mit SHA-256-Chain
if [ -s "$EVIDENCE_LOG" ]; then
  bash "${REPO_ROOT}/scripts/compliance/verify_evidence_chain.sh" "$EVIDENCE_LOG" >/dev/null || {
    echo "Existing evidence chain is invalid; refusing to append."
    exit 2
  }
fi

PREV_HASH="$(tail -1 "$EVIDENCE_LOG" 2>/dev/null | jq -er '.entry_hash' 2>/dev/null || echo "GENESIS")"
INPUT_HASH="$(shasum -a 256 "$INPUT" 2>/dev/null | awk '{print $1}' || echo "")"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
COMMIT_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
GIT_REF="${GITHUB_REF_NAME:-$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)}"
RUN_ID="${GITHUB_RUN_ID:-local}"
ACTOR="${GITHUB_ACTOR:-${USER:-local}}"
DIRTY=false
git -C "$REPO_ROOT" diff --quiet --ignore-submodules HEAD 2>/dev/null || DIRTY=true

ENTRY="$(jq -nc \
  --arg ts "$TS" \
  --arg profile "$PROFILE" \
  --arg result "$GATE_RESULT" \
  --argjson failures "$FAILURES" \
  --argjson warnings "$WARNINGS" \
  --arg input_hash "$INPUT_HASH" \
  --arg prev "$PREV_HASH" \
  --arg commit "$COMMIT_SHA" \
  --arg ref "$GIT_REF" \
  --arg run_id "$RUN_ID" \
  --arg actor "$ACTOR" \
  --argjson dirty "$DIRTY" \
  --argjson gates "$PER_GATE" \
  '{schema_version:"2.0",timestamp:$ts,profile:$profile,gate_result:$result,
    failures:$failures,warnings:$warnings,input_sha256:$input_hash,
    commit_sha:$commit,git_ref:$ref,workflow_run_id:$run_id,actor:$actor,
    working_tree_dirty:$dirty,prev_entry_hash:$prev,gates:$gates}')"

# entry_hash = sha256 des Eintrags ohne entry_hash-Feld
ENTRY_HASH="$(echo -n "$ENTRY" | shasum -a 256 | awk '{print $1}')"
FINAL_ENTRY="$(printf '%s' "$ENTRY" | jq -c --arg h "$ENTRY_HASH" '. + {entry_hash:$h}')"
printf '%s\n' "$FINAL_ENTRY" >> "$EVIDENCE_LOG"
printf '%s\n' "$FINAL_ENTRY" | jq . > "$LATEST_RESULT"

{
  echo "## Apple compliance gates"
  echo
  echo "- Profile: \`$PROFILE\`"
  echo "- Decision: **$GATE_RESULT**"
  echo "- Findings: $FAILURES"
  echo "- Warnings: $WARNINGS"
  echo
  echo "| Gate | Decision |"
  echo "|---|---:|"
  printf '%s' "$PER_GATE" | jq -r '.[] | "| \(.gate_id) | \(.status) |"'
} > "$SUMMARY"

echo ""
echo "=== Result: $GATE_RESULT ($FAILURES findings, $WARNINGS warnings) ==="
echo "Evidence-Log-Eintrag geschrieben (hash ${ENTRY_HASH:0:12}...)"

[ "$GATE_RESULT" = "PASS" ] && exit 0 || exit 1
