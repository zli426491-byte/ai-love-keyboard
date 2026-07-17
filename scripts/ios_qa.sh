#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mkdir -p build/qa
exec > >(tee build/qa/ios-qa.log) 2>&1

FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
REQUIRE_IOS="${REQUIRE_IOS:-0}"
RUN_INTEGRATION="${RUN_INTEGRATION:-0}"

echo "== LoveKey QA environment =="
git status --short --branch
"$FLUTTER_BIN" --version
"$FLUTTER_BIN" pub get
"$FLUTTER_BIN" analyze --no-pub
"$FLUTTER_BIN" test --no-pub --reporter expanded

if [[ "$(uname -s)" != "Darwin" ]] || ! command -v xcodebuild >/dev/null 2>&1; then
  echo "未執行 iOS Simulator 測試"
  echo "Reason: macOS, Xcode, and iOS Simulator are required."
  if [[ "$REQUIRE_IOS" == "1" ]]; then
    exit 2
  fi
  exit 0
fi

echo "== Native iOS environment =="
xcodebuild -version
xcrun simctl list devices available

if [[ -f ios/Podfile ]]; then
  command -v pod >/dev/null 2>&1 || {
    echo "CocoaPods is required because ios/Podfile exists."
    exit 3
  }
  (cd ios && pod install --repo-update)
else
  echo "No ios/Podfile found; using the project's current Flutter/Xcode package setup."
fi

"$FLUTTER_BIN" build ios --simulator --debug

if [[ "$RUN_INTEGRATION" != "1" ]]; then
  echo "Integration launch skipped; set RUN_INTEGRATION=1 to boot an available iPhone Simulator."
  exit 0
fi

SIMULATOR_ID="$(xcrun simctl list devices available -j | python3 -c '
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get("devices", {}).items():
    if "iOS" not in runtime:
        continue
    for device in devices:
        if device.get("isAvailable") and device.get("name", "").startswith("iPhone"):
            print(device["udid"])
            raise SystemExit(0)
raise SystemExit(1)
')"

if [[ -z "$SIMULATOR_ID" ]]; then
  echo "No available iPhone Simulator was found."
  exit 4
fi

xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
xcrun simctl bootstatus "$SIMULATOR_ID" -b
"$FLUTTER_BIN" test integration_test/app_smoke_test.dart -d "$SIMULATOR_ID" \
  --reporter expanded
