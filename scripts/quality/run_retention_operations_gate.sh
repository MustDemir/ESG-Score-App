#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PROFILE="${RETENTION_OPERATIONS_PROFILE:-}"

if [ -z "$PROFILE" ]; then
  case "${COMPLIANCE_PROFILE:-development}" in
    release_candidate|submission) PROFILE="release_candidate" ;;
    remote_backend) PROFILE="remote_backend" ;;
    *) PROFILE="development" ;;
  esac
fi

cd "$REPO_ROOT"
ruby scripts/quality/test_retention_operations_gate.rb
ruby scripts/quality/validate_retention_operations.rb --profile "$PROFILE"
