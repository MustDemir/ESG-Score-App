#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RESULT_DIR="$REPO_ROOT/.quality/supply-chain"
RAW_REPORT="$RESULT_DIR/osv-results.raw.json"
REPORT="$RESULT_DIR/osv-results.json"
LOCKFILE="$REPO_ROOT/esg_app/pubspec.lock"

mkdir -p "$RESULT_DIR"

ruby "$REPO_ROOT/scripts/quality/test_supply_chain_gate.rb"
OSV_SCANNER="$(bash "$REPO_ROOT/scripts/quality/install_osv_scanner.sh")"
"$OSV_SCANNER" --version

set +e
"$OSV_SCANNER" scan source \
  --lockfile "$LOCKFILE" \
  --all-packages \
  --format json \
  --output-file "$RAW_REPORT"
SCAN_EXIT=$?
set -e

if [ "$SCAN_EXIT" -gt 1 ]; then
  printf 'OSV-Scanner technical failure with exit code %s\n' "$SCAN_EXIT" >&2
  exit "$SCAN_EXIT"
fi

jq --arg lockfile "esg_app/pubspec.lock" '
  (.results[]?.source.path) = $lockfile
' "$RAW_REPORT" >"$REPORT"
rm -f "$RAW_REPORT"

ruby "$REPO_ROOT/scripts/quality/validate_supply_chain.rb" \
  --osv-report "$REPORT" \
  --inventory "$RESULT_DIR/dependency-inventory.json"
