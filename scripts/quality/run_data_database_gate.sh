#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

cd "$REPO_ROOT"

if ! supabase status >/dev/null 2>&1; then
  supabase db start
fi

supabase db reset --local
supabase test db --local
supabase db lint --local --level warning
