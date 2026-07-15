# LoveKey iOS QA Report

## Summary

| Field | Result |
| --- | --- |
| QA date | 2026-07-15 (Asia/Taipei) |
| Branch | `qa/ios-autonomous-qa` |
| Worktree | `C:\Users\AsusGaming\Documents\New project\.worktrees\lovekey-ios-qa` |
| Source version | `1.0.4+2` from `pubspec.yaml` |
| Latest documented TestFlight build | Build 55, VALID, Internal Testing |
| Host | Windows 11 |
| Flutter / Dart | Flutter 3.41.7 / Dart 3.11.5 |
| macOS / Xcode / CocoaPods | Not available |
| Severity totals found in this cycle | P0: 0, P1: 0, P2: 8, P3: 0 |
| Fix status | 8 fixed with regression coverage |

`未執行 iOS Simulator 測試`

No iOS Simulator, Xcode, CocoaPods, real login, sandbox purchase, or live AI request was executed on this Windows host. The integration smoke source exists, but neither attempted local device could launch it. The result is therefore a code and Flutter-test gate, not a complete iOS release certification.

## Commands Actually Executed

| Command / activity | Actual result |
| --- | --- |
| `flutter pub get` | Passed |
| `flutter analyze --no-pub` | Passed, 0 issues |
| `flutter test --no-pub` | Passed after fixes; 25/25 tests |
| `scripts/dialogue_eval.sh` | Passed; 14/14 dialogue tests, mock/static mode |
| `scripts/ui_audit.sh` | Passed after fixes; 9/9 UI/widget tests |
| `scripts/ios_qa.sh` | Flutter checks passed, then reported `未執行 iOS Simulator 測試` |
| `flutter build web --release --no-pub` | Web artifacts produced under `build/web` |
| Local browser render | Privacy gate loaded; Flutter Web canvas used only as supplemental visual inspection |
| `flutter build ios --simulator` | Not executable on Windows |
| Xcode build / CocoaPods | Not executed; tools unavailable |
| `integration_test/app_smoke_test.dart -d windows` | Attempted; app build failed before launch because Visual Studio ATL header `atlstr.h` is missing |
| `integration_test/app_smoke_test.dart -d chrome` | Attempted; Flutter reported that Web devices are not supported for this integration-test command |

## Bug Records

### QA-AI-001 - Defensive AI response parsing

- **Severity:** P2
- **Location:** AI proxy response parsing
- **Test device:** Windows Dart VM / Flutter test runner
- **iOS version:** N/A
- **App build:** source `1.0.4+2`
- **Precondition:** Proxy returns an empty `choices` array, missing `message`, non-string content, or invalid JSON.
- **Reproduction:** Feed each malformed payload to the response parser tests.
- **Expected:** Deterministic `FormatException` handled by the existing user-facing error path.
- **Actual before fix:** Direct indexing and casting could throw shape-dependent runtime errors.
- **Screenshot:** N/A; non-visual defect.
- **Log:** Reproduced with failing parser unit cases before implementation.
- **Root cause:** `body['choices'][0]['message']['content'] as String` trusted an external response shape.
- **Modified files:** `lib/services/ai_service.dart`, `lib/services/ai_response_parser.dart`.
- **Fix:** Validate every response layer, support structured text blocks, and reject empty or malformed content.
- **Regression test:** `test/dialogue/ai_response_quality_test.dart`.
- **Result after fix:** All malformed response cases pass with deterministic failures.
- **Commit:** Current `qa/ios-autonomous-qa` QA commit.
- **Status:** Fixed.

### QA-AI-002 - Reject model/template artifacts as replies

- **Severity:** P2
- **Location:** Generated reply selection
- **Test device:** Windows Dart VM / Flutter test runner
- **iOS version:** N/A
- **App build:** source `1.0.4+2`
- **Precondition:** Model returns labels, placeholders, JSON wrappers, code fences, or text such as `以下是高情商的回覆`.
- **Reproduction:** Pass artifact samples through the old reply usability rule.
- **Expected:** Artifact is rejected and never shown as a sendable reply.
- **Actual before fix:** Any non-empty text shorter than 240 characters was accepted except two exact placeholders.
- **Screenshot:** N/A; rule defect reproduced in unit tests.
- **Log:** Artifact rejection cases initially failed before the validator existed.
- **Root cause:** Reply validation checked only length and two exact values.
- **Modified files:** `lib/services/ai_service.dart`, `lib/services/reply_quality_validator.dart`.
- **Fix:** Central validator rejects wrappers, placeholders, code/JSON artifacts, and common meta-answer prefixes.
- **Regression test:** `test/dialogue/ai_response_quality_test.dart`.
- **Result after fix:** Artifact and wrapper cases are rejected; natural replies remain accepted.
- **Commit:** Current `qa/ios-autonomous-qa` QA commit.
- **Status:** Fixed.

### QA-UI-001 - Bottom navigation overflow on 320px width

- **Severity:** P2
- **Location:** Home bottom navigation
- **Test device:** Flutter widget viewport 320x568
- **iOS version:** N/A
- **App build:** source `1.0.4+2`
- **Precondition:** Open Home on compact width.
- **Reproduction:** Pump `HomeView` at 320x568.
- **Expected:** Four navigation targets fit and remain tappable.
- **Actual before fix:** `RenderFlex overflowed by 16 pixels on the right`.
- **Screenshot:** Not captured; deterministic RenderFlex log is the retained evidence.
- **Log:** 16px right overflow in the first UI test run.
- **Root cause:** Four fixed 74px items plus container spacing exceeded the available width.
- **Modified files:** `lib/views/home/home_view.dart`.
- **Fix:** Allocate each navigation item with `Expanded`.
- **Regression test:** `home remains usable on an iPhone SE-sized viewport`.
- **Result after fix:** Test passes with no Flutter exception.
- **Commit:** Current `qa/ios-autonomous-qa` QA commit.
- **Status:** Fixed.

### QA-UI-002 - Onboarding keyboard choice overflow with large text

- **Severity:** P2
- **Location:** Onboarding keyboard selector
- **Test device:** Flutter widget viewport 320x568, text scale 1.3
- **iOS version:** N/A
- **App build:** source `1.0.4+2`
- **Precondition:** Compact phone and larger system text.
- **Reproduction:** Advance the onboarding widget under the stated viewport and scale.
- **Expected:** Choice labels remain inside their row.
- **Actual before fix:** RenderFlex right overflows of 111px and 75px.
- **Screenshot:** Not captured; deterministic RenderFlex log is the retained evidence.
- **Log:** 111px / 75px right overflow in the first UI test run.
- **Root cause:** Choice label had unconstrained intrinsic width.
- **Modified files:** `lib/views/onboarding/onboarding_view.dart`.
- **Fix:** Wrap label in `Expanded`, limit to one line, and ellipsize.
- **Regression test:** `onboarding remains readable with larger text`.
- **Result after fix:** Test passes with no Flutter exception.
- **Commit:** Current `qa/ios-autonomous-qa` QA commit.
- **Status:** Fixed.

### QA-UI-003 - Paywall content inaccessible on compact height

- **Severity:** P2
- **Location:** Paywall sheet
- **Test device:** Flutter widget viewport 320x568
- **iOS version:** N/A
- **App build:** source `1.0.4+2`
- **Precondition:** Open paywall on compact height.
- **Reproduction:** Pump `PaywallView` aligned to the bottom.
- **Expected:** Plans, purchase state, restore action, and legal copy are reachable.
- **Actual before fix:** `RenderFlex overflowed by 269 pixels on the bottom`.
- **Screenshot:** Not captured; deterministic RenderFlex log is the retained evidence.
- **Log:** 269px bottom overflow in the first UI test run.
- **Root cause:** Non-scrollable content exceeded the sheet height.
- **Modified files:** `lib/views/paywall/paywall_view.dart`.
- **Fix:** Add a bounded, scrollable paywall body without changing purchase logic.
- **Regression test:** `paywall shows a stable non-store preview state`.
- **Result after fix:** Compact paywall test passes; Web preview clearly avoids fake RevenueCat state.
- **Commit:** Current `qa/ios-autonomous-qa` QA commit.
- **Status:** Fixed.

### QA-UI-004 - Membership card vertical overflow

- **Severity:** P2
- **Location:** Profile membership card
- **Test device:** Flutter widget viewport 320x568, text scale 1.3
- **iOS version:** N/A
- **App build:** source `1.0.4+2`
- **Precondition:** Navigate to profile on compact width with larger text.
- **Reproduction:** Tap the profile tab in the responsive home test.
- **Expected:** Membership label, allowance, and upgrade button fit.
- **Actual before fix:** `RenderFlex overflowed by 18 pixels on the bottom`.
- **Screenshot:** Not captured; deterministic RenderFlex log is the retained evidence.
- **Log:** 18px bottom overflow in the second UI test run.
- **Root cause:** Fixed height combined with large text, spacing, and button padding.
- **Modified files:** `lib/views/home/home_view.dart`.
- **Fix:** Tighten existing spacing and type sizes and allow the allowance label two lines.
- **Regression test:** Compact Home/Profile path in `responsive_smoke_test.dart`.
- **Result after fix:** Test passes with no Flutter exception.
- **Commit:** Current `qa/ios-autonomous-qa` QA commit.
- **Status:** Fixed.

### QA-UI-005 - Profile menu row horizontal overflow

- **Severity:** P2
- **Location:** Profile menu rows
- **Test device:** Flutter widget viewport 320x568, text scale 1.3
- **iOS version:** N/A
- **App build:** source `1.0.4+2`
- **Precondition:** Profile page with long title/trailing value.
- **Reproduction:** Render the compact profile path.
- **Expected:** Title, trailing value, and chevron coexist.
- **Actual before fix:** `RenderFlex overflowed by 13 pixels on the right`.
- **Screenshot:** Not captured; deterministic RenderFlex log is the retained evidence.
- **Log:** 13px right overflow in the second UI test run.
- **Root cause:** Unconstrained title plus spacer consumed width needed by trailing content.
- **Modified files:** `lib/views/home/home_view.dart`.
- **Fix:** Make title flexible with a two-line ellipsis.
- **Regression test:** Compact Home/Profile path in `responsive_smoke_test.dart`.
- **Result after fix:** Test passes with no Flutter exception.
- **Commit:** Current `qa/ios-autonomous-qa` QA commit.
- **Status:** Fixed.

### QA-UI-006 - First-run privacy notice overflow

- **Severity:** P2
- **Location:** First-run privacy gate
- **Test device:** Flutter widget viewport 320x568, text scale 1.3
- **iOS version:** N/A
- **App build:** source `1.0.4+2`
- **Precondition:** Privacy policy has not been accepted.
- **Reproduction:** Pump `PrivacyNoticeDialog` on a compact viewport.
- **Expected:** Notice remains inside the screen and all content is reachable.
- **Actual before fix:** `RenderFlex overflowed by 303 pixels on the bottom`.
- **Screenshot:** Supplemental Flutter Web inspection showed clipped content; widget log is authoritative.
- **Log:** 303px bottom overflow in the failing regression test.
- **Root cause:** Long fixed dialog column had no scroll container.
- **Modified files:** `lib/views/components/privacy_notice_dialog.dart`.
- **Fix:** Add safe dialog insets and a scrollable body; consent behavior is unchanged.
- **Regression test:** `privacy notice fits a compact phone viewport`.
- **Result after fix:** Test passes at 320x568 and text scale 1.3.
- **Commit:** Current `qa/ios-autonomous-qa` QA commit.
- **Status:** Fixed.

## Release Interpretation

The local code gate is green. This does not prove the native keyboard extension, social login providers, RevenueCat sandbox purchases, or restore flows work on iOS. Those are explicitly blocked until a Mac and physical TestFlight device are used.
