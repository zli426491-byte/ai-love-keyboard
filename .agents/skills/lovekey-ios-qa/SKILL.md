---
name: lovekey-ios-qa
description: Run LoveKey Flutter, dialogue, UI, and iOS readiness checks without real purchases or production mutations.
---

# LoveKey iOS QA

Use this skill from the LoveKey repository root.

1. Record `git status --short --branch`, Flutter/Dart versions, source version, Xcode version, and available simulators.
2. Use an isolated branch or worktree. Do not modify unrelated files or expose secrets.
3. Run `flutter pub get`, `flutter analyze`, and `flutter test`.
4. Run `scripts/dialogue_eval.sh` and `scripts/ui_audit.sh`.
5. On macOS, run `REQUIRE_IOS=1 RUN_INTEGRATION=1 scripts/ios_qa.sh`. Else write `未執行 iOS Simulator 測試` in the result and block native-only conclusions.
6. Reproduce each issue before changing code. Add a failing regression test, make the smallest safe fix, rerun the focused test, then rerun the full suite.
7. Use only StoreKit configuration, Apple Sandbox, RevenueCat test data, or mocks for purchase paths. Never trigger a real charge.
8. Keep live API/model checks separate from `mock_static` dialogue checks. Never present mock output as a live-model pass.
9. Update `docs/qa/` with commands, evidence, severities, fixes, blocked items, and TestFlight readiness.
10. Commit the reviewed QA changes to the current QA branch; do not merge automatically.
