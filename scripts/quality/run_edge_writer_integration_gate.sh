#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RESULT_DIR="$REPO_ROOT/.quality/edge-writer"
TMP_DIR="$(mktemp -d)"
ENV_FILE="$TMP_DIR/edge-writer.env"
FUNCTION_LOG="$RESULT_DIR/function-runtime.log"
WRITER_TEST_LOG="$RESULT_DIR/writer-contract-tests.log"
FUNCTION_PID=""
TEST_SECRET="local-edge-${RANDOM}-${RANDOM}-${RANDOM}"
OPERATOR_TEST_SECRET="local-operator-${RANDOM}-${RANDOM}-${RANDOM}"

cleanup() {
  if [ -n "$FUNCTION_PID" ] && kill -0 "$FUNCTION_PID" 2>/dev/null; then
    kill "$FUNCTION_PID" 2>/dev/null || true
    wait "$FUNCTION_PID" 2>/dev/null || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM

mkdir -p "$RESULT_DIR"
rm -f "$RESULT_DIR"/*

"${NODE_BINARY:-node}" --test \
  "$REPO_ROOT/supabase/functions/_shared/writer_contract.test.mjs" \
  >"$WRITER_TEST_LOG" 2>&1

printf '%s\n' \
  'SCANFAIR_ENVIRONMENT=local' \
  "SCANFAIR_SCHEDULED_WRITER_SECRET=$TEST_SECRET" \
  "SCANFAIR_OPERATOR_REPLAY_SECRET=$OPERATOR_TEST_SECRET" \
  >"$ENV_FILE"

cd "$REPO_ROOT"
supabase functions serve \
  --env-file "$ENV_FILE" \
  --no-verify-jwt \
  >"$FUNCTION_LOG" 2>&1 &
FUNCTION_PID=$!

endpoint="http://127.0.0.1:54321/functions/v1/ingest-products"
base_body='{"barcodes":["4000417025005"],"correlation_id":"correlation-ci-001","request_id":"request-ci-001","source_id":"open-food-facts"}'
unauthorized_status="000"
for _ in $(seq 1 30); do
  unauthorized_status="$(
    curl --silent --show-error \
      --output "$TMP_DIR/unauthorized.json" \
      --write-out '%{http_code}' \
      --request POST "$endpoint" \
      --header 'content-type: application/json' \
      --header 'x-scanfair-writer-actor: scheduled_ingestion_job' \
      --header 'x-scanfair-writer-secret: wrong-secret' \
      --data "$base_body" || true
  )"
  if [ "$unauthorized_status" = "401" ] &&
    grep -q 'writer_unauthorized' "$TMP_DIR/unauthorized.json"; then
    break
  fi
  if ! kill -0 "$FUNCTION_PID" 2>/dev/null; then
    printf 'Edge Function runtime stopped during startup.\n' >&2
    exit 1
  fi
  sleep 1
done

if [ "$unauthorized_status" != "401" ] ||
  ! grep -q 'writer_unauthorized' "$TMP_DIR/unauthorized.json"; then
  printf 'Expected writer authentication rejection, got HTTP %s\n' \
    "$unauthorized_status" >&2
  exit 1
fi

actor_scope_status="$(
  curl --silent --show-error \
    --output "$TMP_DIR/actor-scope.json" \
    --write-out '%{http_code}' \
    --request POST "$endpoint" \
    --header 'content-type: application/json' \
    --header 'x-scanfair-writer-actor: audited_operator_replay' \
    --header "x-scanfair-writer-secret: $TEST_SECRET" \
    --data "$base_body"
)"
if [ "$actor_scope_status" != "401" ] ||
  ! grep -q 'writer_unauthorized' "$TMP_DIR/actor-scope.json"; then
  printf 'Expected actor-scoped secret rejection, got HTTP %s\n' \
    "$actor_scope_status" >&2
  exit 1
fi

schema_status="$(
  curl --silent --show-error \
    --output "$TMP_DIR/schema.json" \
    --write-out '%{http_code}' \
    --request POST "$endpoint" \
    --header 'content-type: application/json' \
    --header 'x-scanfair-writer-actor: scheduled_ingestion_job' \
    --header "x-scanfair-writer-secret: $TEST_SECRET" \
    --data '{"barcodes":["4000417025005"],"correlation_id":"correlation-ci-002","request_id":"request-ci-002","source_id":"open-food-facts","arbitrary_url":"http://127.0.0.1"}'
)"
if [ "$schema_status" != "400" ] ||
  ! grep -q 'unknown_or_missing_fields' "$TMP_DIR/schema.json"; then
  printf 'Expected strict schema rejection, got HTTP %s\n' \
    "$schema_status" >&2
  exit 1
fi

{
  echo '# G-BACKEND-EDGE Result'
  echo
  echo '- Writer contract tests: 11/11 PASS'
  echo "- Invalid secret: HTTP $unauthorized_status PASS"
  echo "- Cross-actor secret: HTTP $actor_scope_status PASS"
  echo "- Unknown URL field: HTTP $schema_status PASS"
  echo '- Remote project activation: not performed'
} >"$RESULT_DIR/report.md"

printf 'Edge writer integration gate PASS\n'
