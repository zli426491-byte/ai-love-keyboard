# LoveKey Daily iOS QA - 2026-07-22

## Baseline
- Repo: `C:\Users\AsusGaming\ai_love_keyboard`
- Branch: `qa/daily-ios-qa-20260722-020134`
- HEAD: `a28428d680708aed9897a51e7c4c436d7e35087c`
- `origin/HEAD`: `origin/master`

## Environment
- Flutter: `3.41.7`
- Dart: `3.11.5`
- Xcode / Simulator: unavailable on this Windows host
- Available desktop devices: Windows, Chrome, Edge

## Commands Run
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter test build/qa/dialogue_logic_qa_test.dart`
- `flutter test build/qa/ui_core_regression_qa_test.dart`
- `flutter build ios` attempt
- `flutter test integration_test` attempt

## Results
- `flutter pub get`: passed
- `flutter analyze`: passed
- `flutter test`: passed
- Dialogue QA:
  - `mock_static` prompt/template and content filter cases: passed
  - `live_model` path without `AI_PROXY_URL`: passed as fail-closed
- UI regression QA:
  - cold start route: passed
  - paywall plans + restore affordance: passed
  - settings dark mode + large font: passed
  - reply card copy path: passed
- iOS simulator:
  - not executed
  - `xcodebuild` / `xcrun` unavailable on host
  - `flutter build ios` not available in this Flutter/Windows setup
- Integration tests:
  - `integration_test/` absent on tracked baseline
- Tracked QA scripts:
  - `scripts/dialogue_eval.sh`, `scripts/ui_audit.sh`, `scripts/ios_qa.sh` not present on `origin/master`

## Fix Applied
- `lib/views/paywall/paywall_view.dart`
  - Wrapped the paywall content in `SingleChildScrollView` so large text scales do not overflow the bottom sheet layout.

## Evidence
- Logs: `build/qa/logs/flutter_test.log`
- Logs: `build/qa/logs/dialogue_logic_qa_test.log`
- Logs: `build/qa/logs/ui_core_regression_qa_test.log`
- Logs: `build/qa/logs/ui_settings.log`
- Logs: `build/qa/logs/ui_replycard.log`
- Logs: `build/qa/logs/ui_paywall.log`
- Logs: `build/qa/logs/ui_cold_start.log`

## Notes
- `本次未執行 iOS Simulator 測試`
- No PR created.
- No secret material was accessed or written.
