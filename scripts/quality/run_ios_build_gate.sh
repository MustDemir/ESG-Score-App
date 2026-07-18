#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_DIR="$REPO_ROOT/esg_app"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "G-IOS-COMPILE requires macOS with Xcode."
  exit 2
fi

if [ -d /Applications/Xcode.app/Contents/Developer ]; then
  export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
fi

if ! xcrun xcodebuild -version; then
  echo "Full Xcode is not installed or not active."
  exit 2
fi

cd "$APP_DIR"
flutter pub get
flutter build ios --simulator --no-codesign

echo "G-IOS-COMPILE PASS: unsigned iOS simulator build completed."
