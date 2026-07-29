#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
POLICY="$REPO_ROOT/docs/project/compliance/supply-chain-policy.yaml"
TOOL_DIR="$REPO_ROOT/.quality/tools"

case "$(uname -s)-$(uname -m)" in
  Darwin-arm64)
    PLATFORM="darwin-arm64"
    ;;
  Darwin-x86_64)
    PLATFORM="darwin-amd64"
    ;;
  Linux-x86_64)
    PLATFORM="linux-amd64"
    ;;
  Linux-aarch64 | Linux-arm64)
    PLATFORM="linux-arm64"
    ;;
  *)
    printf 'Unsupported OSV-Scanner platform: %s-%s\n' "$(uname -s)" "$(uname -m)" >&2
    exit 1
    ;;
esac

read -r VERSION DOWNLOAD_URL EXPECTED_SHA256 <<<"$(
  ruby -ryaml -e '
    policy = YAML.safe_load(File.read(ARGV[0]))
    version = policy.dig("vulnerability_policy", "version")
    binary = policy.dig("vulnerability_policy", "binaries", ARGV[1])
    abort "Missing OSV binary policy for #{ARGV[1]}" unless version && binary
    puts [version, binary.fetch("url"), binary.fetch("sha256")].join(" ")
  ' "$POLICY" "$PLATFORM"
)"

mkdir -p "$TOOL_DIR"
TARGET="$TOOL_DIR/osv-scanner-${VERSION}-${PLATFORM}"

calculate_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

if [ -f "$TARGET" ]; then
  ACTUAL_SHA256="$(calculate_sha256 "$TARGET")"
  if [ "$ACTUAL_SHA256" = "$EXPECTED_SHA256" ]; then
    printf '%s\n' "$TARGET"
    exit 0
  fi
  rm -f "$TARGET"
fi

TEMP_FILE="${TARGET}.download"
rm -f "$TEMP_FILE"
curl \
  --proto '=https' \
  --tlsv1.2 \
  --fail \
  --location \
  --retry 3 \
  --silent \
  --show-error \
  "$DOWNLOAD_URL" \
  --output "$TEMP_FILE"

ACTUAL_SHA256="$(calculate_sha256 "$TEMP_FILE")"
if [ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]; then
  rm -f "$TEMP_FILE"
  printf 'OSV-Scanner checksum mismatch for %s\n' "$PLATFORM" >&2
  exit 1
fi

chmod 0755 "$TEMP_FILE"
mv "$TEMP_FILE" "$TARGET"
printf '%s\n' "$TARGET"
