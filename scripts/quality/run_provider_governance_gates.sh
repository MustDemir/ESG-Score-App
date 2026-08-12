#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RESULT_DIR="$REPO_ROOT/.quality/provider-governance"
REPORT="$RESULT_DIR/report.md"
PROFILE="${PROVIDER_GOVERNANCE_PROFILE:-development}"
ONLINE_FLAG=""

if [ "${PROVIDER_ONLINE_SOURCE_CHECK:-false}" = "true" ]; then
  ONLINE_FLAG="--online-sources"
fi

mkdir -p "$RESULT_DIR"
rm -f "$RESULT_DIR"/*.json "$RESULT_DIR"/*.log "$REPORT"

PASS_COUNT=0
FAIL_COUNT=0

run_check() {
  local gate_id="$1"
  local gate_key="$2"
  local log="$RESULT_DIR/${gate_id}.log"

  set +e
  if [ -n "$ONLINE_FLAG" ]; then
    ruby "$REPO_ROOT/scripts/quality/validate_provider_governance.rb" \
      --repo-root "$REPO_ROOT" \
      --gate "$gate_key" \
      --profile "$PROFILE" \
      "$ONLINE_FLAG" >"$log" 2>&1
  else
    ruby "$REPO_ROOT/scripts/quality/validate_provider_governance.rb" \
      --repo-root "$REPO_ROOT" \
      --gate "$gate_key" \
      --profile "$PROFILE" >"$log" 2>&1
  fi
  local exit_code=$?
  set -e

  if [ "$exit_code" -eq 0 ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '%s PASS\n' "$gate_id"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '%s FAIL; see %s\n' "$gate_id" "$log"
  fi
}

ruby "$REPO_ROOT/scripts/quality/test_provider_governance_gate.rb"
run_check "G-PROVIDER-DPA" "dpa"
run_check "G-PROVIDER-SUBPROCESSORS" "subprocessors"
run_check "G-COST-CONTROL" "cost"

{
  echo "# ScanFair Provider Governance Gates"
  echo
  echo "- Profile: ${PROFILE}"
  echo "- Passed: ${PASS_COUNT}/3"
  echo "- Failed: ${FAIL_COUNT}/3"
  echo "- Online source check: ${PROVIDER_ONLINE_SOURCE_CHECK:-false}"
  echo
  echo "| Gate | Result | Governance decision | Source version | Next review |"
  echo "|---|---:|---|---|---|"
  for result in "$RESULT_DIR"/G-*.json; do
    gate_id="$(jq -r '.gate_id' "$result")"
    decision="$(jq -r '.decision' "$result")"
    governance="$(jq -r '.governance_decision' "$result")"
    version="$(jq -r '.expected_version' "$result")"
    next_review="$(jq -r '.next_periodic_review_at' "$result")"
    echo "| ${gate_id} | ${decision} | ${governance} | ${version} | ${next_review} |"
  done
} >"$REPORT"

cat "$REPORT"
[ "$FAIL_COUNT" -eq 0 ]
