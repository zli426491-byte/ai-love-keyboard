#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

QA_DIR="$ROOT/build/qa"
mkdir -p "$QA_DIR"
exec > >(tee "$QA_DIR/codemagic-ios-qa.log") 2>&1

echo "== LoveKey cloud QA environment =="
date -u +"UTC %Y-%m-%dT%H:%M:%SZ"
git status --short --branch
git rev-parse HEAD
flutter --version
xcodebuild -version
pod --version

echo "== Flutter dependency and static checks =="
flutter pub get
flutter analyze --no-pub | tee "$QA_DIR/flutter-analyze.log"

echo "== Flutter unit and widget tests =="
set +e
flutter test --no-pub --machine > "$QA_DIR/flutter-tests.json" 2> "$QA_DIR/flutter-tests.stderr.log"
FLUTTER_TEST_EXIT=$?
set -e
cat "$QA_DIR/flutter-tests.stderr.log"
if [[ "$FLUTTER_TEST_EXIT" -ne 0 ]]; then
  echo "== Flutter test failure details =="
  python3 - "$QA_DIR/flutter-tests.json" <<'PY'
import json
import sys

path = sys.argv[1]
tests = {}


def iter_events(value):
    if isinstance(value, dict):
        yield value
    elif isinstance(value, list):
        for item in value:
            yield from iter_events(item)


with open(path, encoding="utf-8") as stream:
    for raw_line in stream:
        try:
            decoded = json.loads(raw_line)
        except json.JSONDecodeError:
            continue

        for event in iter_events(decoded):
            event_type = event.get("type")
            if event_type == "testStart":
                test = event.get("test") or {}
                tests[test.get("id")] = test.get("name", "Unknown test")
            elif event_type == "error":
                test_id = event.get("testID")
                print(f"Test: {tests.get(test_id, test_id or 'Unknown test')}")
                print(event.get("error", "Unknown Flutter test error"))
                stack = event.get("stackTrace")
                if stack:
                    print(stack)
            elif event_type == "testDone" and event.get("result") in {"error", "failure"}:
                test_id = event.get("testID")
                print(f"Result: {event.get('result')} - {tests.get(test_id, test_id or 'Unknown test')}")
PY
  echo "Flutter tests failed with exit code $FLUTTER_TEST_EXIT."
  exit "$FLUTTER_TEST_EXIT"
fi

echo "== Focused dialogue and UI checks =="
bash scripts/dialogue_eval.sh
bash scripts/ui_audit.sh

echo "== Install iOS pods and build simulator app =="
if [[ -f ios/Podfile ]]; then
  (cd ios && pod install)
fi
flutter build ios --simulator --debug

echo "== Select newest available iOS runtime and an iPhone device type =="
RUNTIME_ID="$(xcrun simctl list runtimes available -j | python3 -c '
import json, re, sys
data = json.load(sys.stdin)
items = []
for runtime in data.get("runtimes", []):
    if runtime.get("isAvailable") and runtime.get("platform") == "iOS":
        version = tuple(int(x) for x in re.findall(r"\d+", runtime.get("version", "0")))
        items.append((version, runtime["identifier"]))
if not items:
    raise SystemExit("No available iOS runtime")
print(sorted(items)[-1][1])
')"

DEVICE_TYPE_ID="$(xcrun simctl list devicetypes -j | python3 -c '
import json, sys
types = json.load(sys.stdin).get("devicetypes", [])
preferred = ["iPhone 16 Pro", "iPhone 15 Pro", "iPhone 14 Pro"]
for name in preferred:
    for item in types:
        if item.get("name") == name:
            print(item["identifier"])
            raise SystemExit(0)
for item in types:
    if item.get("name", "").startswith("iPhone"):
        print(item["identifier"])
        raise SystemExit(0)
raise SystemExit("No iPhone simulator device type")
')"

SIMULATOR_NAME="LoveKey QA ${CM_BUILD_ID:-local}"
SIMULATOR_ID="$(xcrun simctl create "$SIMULATOR_NAME" "$DEVICE_TYPE_ID" "$RUNTIME_ID")"

cleanup() {
  xcrun simctl shutdown "$SIMULATOR_ID" >/dev/null 2>&1 || true
  xcrun simctl delete "$SIMULATOR_ID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

xcrun simctl boot "$SIMULATOR_ID"
xcrun simctl bootstatus "$SIMULATOR_ID" -b
xcrun simctl list devices available | tee "$QA_DIR/simulator-devices.log"
xcrun simctl getenv "$SIMULATOR_ID" SIMULATOR_RUNTIME_VERSION | tee "$QA_DIR/simulator-ios-version.txt" || true

echo "== Core iOS integration test =="
flutter test integration_test/app_smoke_test.dart -d "$SIMULATOR_ID" --reporter expanded \
  | tee "$QA_DIR/ios-integration-test.log"

APP_PATH="$ROOT/build/ios/iphonesimulator/Runner.app"
BUNDLE_ID="com.ailovekeyboard.app"
xcrun simctl terminate "$SIMULATOR_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID" | tee "$QA_DIR/simulator-launch.log"
sleep 5
xcrun simctl io "$SIMULATOR_ID" screenshot "$QA_DIR/home-light.png"

echo "== Dark mode launch evidence =="
xcrun simctl ui "$SIMULATOR_ID" appearance dark
xcrun simctl terminate "$SIMULATOR_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID" | tee "$QA_DIR/simulator-dark-launch.log"
sleep 3
xcrun simctl io "$SIMULATOR_ID" screenshot "$QA_DIR/home-dark.png"
xcrun simctl ui "$SIMULATOR_ID" appearance light

echo "LoveKey iOS Simulator QA completed successfully."
