#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

cd "$REPO_ROOT"

if ! supabase status >/dev/null 2>&1; then
  # Local development keys are disposable but should not be echoed into CI logs.
  supabase start >/dev/null
fi

supabase db reset --local
supabase test db --local
supabase db lint --local --level warning
