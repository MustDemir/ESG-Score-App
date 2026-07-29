#!/usr/bin/env bash

set -euo pipefail

: "${FLUTTER_VERSION:?FLUTTER_VERSION is required}"
: "${FLUTTER_RELEASE_BASE_URL:?FLUTTER_RELEASE_BASE_URL is required}"
: "${RUNNER_ARCH:?RUNNER_ARCH is required}"
: "${RUNNER_OS:?RUNNER_OS is required}"
: "${RUNNER_TEMP:?RUNNER_TEMP is required}"
: "${GITHUB_PATH:?GITHUB_PATH is required}"

flutter_root="$RUNNER_TEMP/flutter"
flutter_bin="$flutter_root/bin/flutter"
archive_dir="$RUNNER_TEMP/flutter-archive"
mkdir -p "$archive_dir"

case "$RUNNER_OS:$RUNNER_ARCH" in
  Linux:X64)
    : "${FLUTTER_LINUX_X64_SHA256:?FLUTTER_LINUX_X64_SHA256 is required}"
    archive_path="stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
    expected_sha256="$FLUTTER_LINUX_X64_SHA256"
    archive="$archive_dir/flutter-sdk.tar.xz"
    ;;
  macOS:X64)
    : "${FLUTTER_MACOS_X64_SHA256:?FLUTTER_MACOS_X64_SHA256 is required}"
    archive_path="stable/macos/flutter_macos_${FLUTTER_VERSION}-stable.zip"
    expected_sha256="$FLUTTER_MACOS_X64_SHA256"
    archive="$archive_dir/flutter-sdk.zip"
    ;;
  macOS:ARM64)
    : "${FLUTTER_MACOS_ARM64_SHA256:?FLUTTER_MACOS_ARM64_SHA256 is required}"
    archive_path="stable/macos/flutter_macos_arm64_${FLUTTER_VERSION}-stable.zip"
    expected_sha256="$FLUTTER_MACOS_ARM64_SHA256"
    archive="$archive_dir/flutter-sdk.zip"
    ;;
  *)
    echo "Unsupported GitHub runner: $RUNNER_OS/$RUNNER_ARCH" >&2
    exit 1
    ;;
esac

if [[ ! -f "$archive" ]]; then
  curl \
    --proto '=https' \
    --tlsv1.2 \
    --fail \
    --location \
    --retry 3 \
    --silent \
    --show-error \
    "$FLUTTER_RELEASE_BASE_URL/$archive_path" \
    --output "$archive"
fi

case "$RUNNER_OS" in
  Linux)
    printf '%s  %s\n' "$expected_sha256" "$archive" | sha256sum --check -
    if [[ ! -x "$flutter_bin" ]]; then
      tar -xJf "$archive" -C "$RUNNER_TEMP"
    fi
    ;;
  macOS)
    printf '%s  %s\n' "$expected_sha256" "$archive" | shasum -a 256 --check
    if [[ ! -x "$flutter_bin" ]]; then
      unzip -q "$archive" -d "$RUNNER_TEMP"
    fi
    ;;
esac

version_output="$("$flutter_bin" --version)"
version_line="${version_output%%$'\n'*}"
expected_prefix="Flutter $FLUTTER_VERSION "
if [[ "$version_line" != "$expected_prefix"* ]]; then
  echo "Expected Flutter $FLUTTER_VERSION, found: $version_line" >&2
  exit 1
fi

printf '%s\n' "$flutter_root/bin" >> "$GITHUB_PATH"
printf 'Verified %s from %s\n' "$version_line" "$archive_path"
