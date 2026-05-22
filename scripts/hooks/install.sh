#!/usr/bin/env bash
# Installiert die Git-Hooks aus scripts/hooks/ in .git/hooks/
# Idempotent: kann mehrfach ausgeführt werden.

set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOKS_SRC="${REPO_ROOT}/scripts/hooks"
HOOKS_DST="${REPO_ROOT}/.git/hooks"

if [ ! -d "${HOOKS_DST}" ]; then
  echo "❌ ${HOOKS_DST} nicht gefunden — Repo nicht initialisiert?"
  exit 1
fi

for hook in pre-commit; do
  src="${HOOKS_SRC}/${hook}"
  dst="${HOOKS_DST}/${hook}"
  if [ ! -f "${src}" ]; then
    echo "⚠️  ${src} fehlt — überspringe."
    continue
  fi
  cp "${src}" "${dst}"
  chmod +x "${dst}"
  echo "✅ Installed: ${hook} → ${dst}"
done

echo
echo "Git-Hooks installiert. Test:"
echo "  git commit --allow-empty -m 'test'"
