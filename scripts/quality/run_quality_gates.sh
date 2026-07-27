#!/usr/bin/env bash
# shellcheck disable=SC2329
# =============================================================================
# ScanFair local quality gates
# =============================================================================
# Local equivalent of the GitHub Actions quality-gates workflow.
# It keeps running after individual gate failures and writes a compact report.
# =============================================================================

set -uo pipefail

# Functions are intentionally dispatched by name through run_gate.

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_DIR="$REPO_ROOT/esg_app"
RESULT_DIR="$REPO_ROOT/.quality/results"
LOG_DIR="$REPO_ROOT/.quality/logs"
REPORT="$REPO_ROOT/.quality/quality-gate-report.md"

mkdir -p "$RESULT_DIR" "$LOG_DIR"
rm -f "$RESULT_DIR"/*.json "$LOG_DIR"/*.log "$REPORT"

PASS_COUNT=0
FAIL_COUNT=0

gate_flutter_pub_get() {
  cd "$APP_DIR" && flutter pub get
}

gate_flutter_format() {
  cd "$APP_DIR" && dart format --set-exit-if-changed lib test
}

gate_flutter_analyze() {
  cd "$APP_DIR" && flutter analyze --fatal-infos
}

gate_flutter_test() {
  cd "$APP_DIR" && flutter test --coverage
}

gate_flutter_coverage() {
  local coverage_file="$APP_DIR/coverage/lcov.info"
  local minimum_coverage=60

  [ -f "$coverage_file" ] || return 1
  awk -F: -v minimum="$minimum_coverage" '
    /^LF:/ { total += $2 }
    /^LH:/ { hit += $2 }
    END {
      coverage = total > 0 ? (hit * 100 / total) : 0
      printf "Line coverage: %d/%d (%.2f%%), required: %.2f%%\n", hit, total, coverage, minimum
      exit coverage >= minimum ? 0 : 1
    }
  ' "$coverage_file"
}

gate_rego_unit_tests() {
  cd "$REPO_ROOT" && opa test docs/project/policies
}

gate_compliance_catalog() {
  cd "$REPO_ROOT" && COMPLIANCE_PROFILE="${COMPLIANCE_PROFILE:-development}" ruby scripts/compliance/validate_compliance_catalog.rb
}

gate_app_compliance() {
  cd "$REPO_ROOT" && COMPLIANCE_PROFILE="${COMPLIANCE_PROFILE:-development}" bash scripts/compliance/run_gates.sh
}

gate_evidence_chain() {
  cd "$REPO_ROOT" && bash scripts/compliance/verify_evidence_chain.sh
}

gate_docs_traceability() {
  local missing=0
  local check
  local file
  local marker
  local checks=(
    "README.md|Quality Gates"
    "README.md|scripts/quality/run_quality_gates.sh"
    "README.md|G-FLT-COVERAGE"
    "README.md|G-IOS-COMPILE"
    "README.md|G-CMP-SCHEMA"
    "README.md|G-AS-CLAIMS-TRANSPARENCY"
    "docs/project/compliance/apple-compliance-control-model.md|release_candidate"
    "docs/project/compliance/source-register.yaml|APPLE-ARG"
    "esg_app/README.md|flutter run"
    "esg_app/README.md|Open Food Facts API v3"
    "esg_app/README.md|mobile_scanner"
  )

  for check in "${checks[@]}"; do
    file="${check%%|*}"
    marker="${check#*|}"
    if ! grep -Fq -- "$marker" "$REPO_ROOT/$file"; then
      printf 'Missing documentation traceability: %s: %s\n' "$file" "$marker"
      missing=1
    fi
  done

  [ "$missing" -eq 0 ] || return 1
  printf 'Documentation traceability OK: %s working-tree markers\n' "${#checks[@]}"
}

gate_yaml_syntax() {
  cd "$REPO_ROOT" || return 1
  find docs/project -name '*.yaml' -print0 | xargs -0 ruby -e '
    require "yaml"
    ARGV.each { |path| YAML.parse_file(path) }
    puts "YAML syntax OK: #{ARGV.length} files"
  '
}

run_gate() {
  local gate_id="$1"
  local gate_name="$2"
  local command_name="$3"
  local log_file="$LOG_DIR/${gate_id}.log"
  local result_file="$RESULT_DIR/${gate_id}.json"

  printf '\n[%s] %s\n' "$gate_id" "$gate_name"

  set +e
  "$command_name" >"$log_file" 2>&1
  local exit_code=$?
  set -u

  local status="PASS"
  if [ "$exit_code" -ne 0 ]; then
    status="FAIL"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL (exit %s). Log: %s\n' "$exit_code" "$log_file"
  else
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  PASS\n'
  fi

  printf '{"gate_id":"%s","name":"%s","status":"%s","exit_code":%s,"log":"%s"}\n' \
    "$gate_id" "$gate_name" "$status" "$exit_code" "$log_file" >"$result_file"
}

run_gate "G-FLT-DEPS" "Flutter dependency resolution" gate_flutter_pub_get
run_gate "G-FLT-FORMAT" "Dart format check" gate_flutter_format
run_gate "G-FLT-ANALYZE" "Flutter static analysis" gate_flutter_analyze
run_gate "G-FLT-TEST" "Flutter unit and widget tests" gate_flutter_test
run_gate "G-FLT-COVERAGE" "Flutter line coverage baseline (60%)" gate_flutter_coverage
run_gate "G-CMP-SCHEMA" "Compliance catalog schema and cross-link validation" gate_compliance_catalog
run_gate "G-REG-UNIT" "Rego policy unit tests" gate_rego_unit_tests
run_gate "G-CMP-APPLE" "Conftest compliance gates with evidence log" gate_app_compliance
run_gate "G-CMP-EVIDENCE" "Compliance evidence hash-chain verification" gate_evidence_chain
run_gate "G-DOC-TRACE" "Documentation traceability check" gate_docs_traceability
run_gate "G-DOC-YAML" "Project YAML syntax check" gate_yaml_syntax

TOTAL=$((PASS_COUNT + FAIL_COUNT))

{
  echo "# ScanFair Quality Gate Report"
  echo
  echo "- Gates passed: ${PASS_COUNT}/${TOTAL}"
  echo "- Gates failed: ${FAIL_COUNT}/${TOTAL}"
  echo "- Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  echo "| Gate | Result | Log |"
  echo "|---|---:|---|"
  for result in "$RESULT_DIR"/*.json; do
    gate_id="$(jq -r '.gate_id' "$result" 2>/dev/null || basename "$result" .json)"
    status="$(jq -r '.status' "$result" 2>/dev/null || echo UNKNOWN)"
    log_path="$(jq -r '.log' "$result" 2>/dev/null || echo "")"
    echo "| ${gate_id} | ${status} | ${log_path} |"
  done
  if [ -f "$REPO_ROOT/.quality/compliance-gate-summary.md" ]; then
    echo
    cat "$REPO_ROOT/.quality/compliance-gate-summary.md"
  fi
} >"$REPORT"

printf '\nQuality gate report: %s\n' "$REPORT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  printf 'Decision: PASS\n'
  exit 0
fi

printf 'Decision: FAIL\n'
exit 1
