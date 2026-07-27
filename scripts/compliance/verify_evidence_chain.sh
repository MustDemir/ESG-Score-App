#!/usr/bin/env bash
# Verify every link and entry hash in the local JSONL evidence chain.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EVIDENCE_LOG="${1:-${REPO_ROOT}/evidence-store/evidence-log.jsonl}"

if [ ! -f "$EVIDENCE_LOG" ] || [ ! -s "$EVIDENCE_LOG" ]; then
  echo "Evidence chain is empty: $EVIDENCE_LOG"
  exit 0
fi

line_number=0
expected_previous="GENESIS"

while IFS= read -r entry || [ -n "$entry" ]; do
  line_number=$((line_number + 1))

  if ! printf '%s' "$entry" | jq -e 'type == "object" and (.entry_hash | type == "string")' >/dev/null; then
    echo "Invalid evidence JSON at line $line_number"
    exit 1
  fi

  previous="$(printf '%s' "$entry" | jq -r '.prev_entry_hash // ""')"
  actual_hash="$(printf '%s' "$entry" | jq -r '.entry_hash')"
  canonical="$(printf '%s' "$entry" | jq -c 'del(.entry_hash)')"
  calculated_hash="$(printf '%s' "$canonical" | shasum -a 256 | awk '{print $1}')"

  if [ "$previous" != "$expected_previous" ]; then
    echo "Broken previous-hash link at line $line_number"
    exit 1
  fi

  if [ "$actual_hash" != "$calculated_hash" ]; then
    echo "Invalid entry hash at line $line_number"
    exit 1
  fi

  expected_previous="$actual_hash"
done < "$EVIDENCE_LOG"

echo "Evidence chain valid: $line_number entries"
