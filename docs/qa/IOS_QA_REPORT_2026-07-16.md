# LoveKey iOS QA Report - 2026-07-16

## Executive Summary

| Field | Result |
| --- | --- |
| QA date | 2026-07-16 (Asia/Taipei) |
| Branch | `qa/ios-autonomous-qa` |
| Tested commit | `68804aad1d0555ffbda98532aa74b5b5a320e14c` |
| Codemagic build | Build 7, `6a58309b809056750f5a2de1`, finished |
| iOS Simulator | iOS 26.4.1 |
| Flutter analyze | Passed, 0 issues |
| Flutter tests | 27/27 passed, 0 failed, 0 skipped |
| Dialogue tests | 14/14 passed in deterministic mock/static mode |
| UI/widget audit | 11/11 passed |
| iOS integration test | 1/1 passed |
| BrowserStack real device | iPhone 15 Pro Max, iOS 17.3, basic launch flow passed |
| Open findings | P0: 0, P1: 0, P2: 1, P3: 3 |
| Production mutations | None |
| Real purchases | None |

Codemagic is the primary repeatable iOS QA environment. BrowserStack is useful as a supplemental real-device spot check, but the free two-minute device session is not sufficient for the complete keyboard-extension, Full Access, and purchase flow.

## Tests Actually Executed

### Codemagic

- `flutter analyze`: passed with no issues.
- Complete Flutter unit/widget suite: 27 visible tests passed.
- Dialogue quality and fixture suite: 14 tests passed.
- Responsive and widget UI audit: 11 tests passed.
- `flutter build ios --simulator`: passed.
- Simulator boot, app install, and app launch: passed.
- Core navigation and local input integration smoke test: 1 test passed.
- Normal application was reinstalled after the integration-test Runner build.
- Light and dark system-appearance screenshots were captured.

Build details: <https://codemagic.io/app/6a57a734c841cfc41acd24de/build/6a58309b809056750f5a2de1>

Local downloaded evidence:

- `C:\Users\AsusGaming\Downloads\ai-love-keyboard_7_artifacts\build\qa\codemagic-ios-qa.log`
- `C:\Users\AsusGaming\Downloads\ai-love-keyboard_7_artifacts\build\qa\home-light.png`
- `C:\Users\AsusGaming\Downloads\ai-love-keyboard_7_artifacts\build\qa\home-dark.png`
- `C:\Users\AsusGaming\Downloads\ai-love-keyboard_7_artifacts\build\qa\ios-integration-test.log`

### BrowserStack

- Uploaded and installed the signed LoveKey IPA.
- Device: iPhone 15 Pro Max, iOS 17.3.
- Cold launch reached the privacy consent screen.
- The `I agree` action advanced to the onboarding identity screen.
- The free device session then expired.

Not verified in BrowserStack: full onboarding, third-party keyboard enablement, Full Access, copy/generate/fill, RevenueCat sandbox products, restore purchases, dark mode, and large text.

## Fixed Defects Verified In This Run

### Keyboard extension simulator installation

- **Severity before fix:** P1.
- **Symptom:** Simulator installation failed with invalid app-extension placeholder attributes.
- **Root cause:** `LoveKeyboard.appex` did not contain resolved `CFBundleShortVersionString` or `CFBundleVersion` values.
- **Fix:** The extension now inherits `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` through the Flutter build configurations.
- **Evidence:** Codemagic Build 7 installed and launched the app containing the keyboard extension, then passed the integration smoke test.
- **Status:** Fixed and covered by the Codemagic simulator workflow.

### Settings interaction assertion

- **Severity before fix:** P2.
- **Symptom:** Widget tests exposed interactive cards without a valid Material ancestor.
- **Fix:** Settings actions now render inside Material, and the test scrolls each action into view before tapping.
- **Evidence:** UI/widget audit 11/11 passed.
- **Status:** Fixed.

### QA event parsing and screenshot fixture

- **Severity before fix:** P2 test-infrastructure defect.
- **Symptom:** Flutter machine-event arrays were not parsed correctly, and the screenshot step relaunched the integration-test fixture instead of the normal app.
- **Fix:** Event arrays are parsed, the normal simulator app is preserved outside collected artifacts, and it is reinstalled before screenshots.
- **Evidence:** Build 7 produced a rendered LoveKey privacy screen rather than a blank test Runner.
- **Status:** Fixed.

## Open Findings

### P2 - System dark appearance does not produce a dark theme

- **Reproduction:** Launch the normal app in light appearance, capture `home-light.png`, switch Simulator to dark appearance, relaunch, and capture `home-dark.png`.
- **Expected:** If system theme support is declared, the visual palette should adapt while preserving readability.
- **Actual:** Both screenshots are byte-for-byte identical.
- **Root cause:** `MaterialApp` uses `ThemeMode.system`, but `AppTheme.lightTheme` redirects to `darkTheme`, and `darkTheme` itself declares `Brightness.light`.
- **Risk:** Dark-mode regression coverage currently proves only that the light interface remains launchable under a dark system setting; it does not validate an adaptive dark design.
- **Action:** Product/design must decide whether LoveKey is intentionally light-only or requires a designed dark palette. This was not auto-fixed because it is a broad visual-design change.

### P3 - iOS build maintenance warnings

1. Flutter reports that UIScene lifecycle support will be required on a future iOS/Flutter toolchain.
2. `app_tracking_transparency` does not currently support Flutter's iOS Swift Package Manager integration and is expected to become an error in a future Flutter version.
3. CocoaPods reports that the Runner project uses custom base configurations and emits an unused master-specs-repository warning.

These warnings did not fail Build 7, but they should be scheduled before the next major Flutter/Xcode upgrade.

## Release Decision

The current source passes repeatable static, unit, widget, dialogue, simulator build, simulator launch, and core integration gates. It is **not yet a complete commercial release certification** because the following still require TestFlight on a physical iPhone using sandbox accounts:

- Enable the LoveKey third-party keyboard and Full Access.
- Copy a real chat message, generate one reply, and insert it into the host app.
- Verify weekly, yearly, and lifetime product display from App Store Connect/RevenueCat.
- Complete sandbox purchase and restore-purchase checks without a real charge.
- Verify network failure and recovery while the keyboard is active.
- Verify large text and the final light-only versus adaptive-dark product decision.

No production RevenueCat setting, Supabase data, real user data, or paid transaction was changed during this run.
