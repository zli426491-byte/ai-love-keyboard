# LoveKey Blocked Items

## B-001 - Native iOS build and Simulator

- **Reason:** Current host is Windows 11; macOS, Xcode, CocoaPods, and iOS Simulator are unavailable.
- **Attempted:** Flutter environment inspection and Windows-side iOS build command validation.
- **Result:** `未執行 iOS Simulator 測試`.
- **Needed:** A macOS runner or Mac with Xcode, an installed iPhone Simulator runtime, Flutter, and CocoaPods if the project requires it.
- **Automation prepared:** `.github/workflows/ios-qa.yml` and `scripts/ios_qa.sh`.

## B-002 - Native keyboard extension workflow

- **Blocked tests:** Add keyboard, Full Access, copy/paste, generate, retry, fill into host app, keyboard height, host-app switching, background/foreground behavior.
- **Needed:** Physical iPhone with the current TestFlight build; test in LINE, Instagram, and iMessage.
- **Account/permission:** TestFlight access and explicit Full Access granted by the tester.

## B-003 - Authentication providers

- **Blocked tests:** Email registration/login failures, Google login/cancel, Apple login/cancel, logout, session restore, session expiry.
- **Needed:** Non-production Supabase test project/users and configured Google/Apple sign-in on iOS.
- **Safety:** Do not use production customer data or write test records into the production project.

## B-004 - RevenueCat and Apple purchase lifecycle

- **Blocked tests:** Weekly/yearly/lifetime display on device, purchase success, cancel, failure, pending, timeout, restore with/without purchase, reinstall, entitlement persistence, duplicate taps.
- **Needed:** Apple Sandbox tester or StoreKit Configuration, RevenueCat sandbox data, physical device or Simulator on macOS.
- **Safety:** No real purchase was attempted and no production product, entitlement, or offering was modified.

## B-005 - Live AI endpoint quality and failure injection

- **Blocked tests:** Real deployed model quality rate, proxy timeout, network disconnect during generation, refusal behavior, production model/version capture.
- **Needed:** A non-production proxy endpoint and test key with a strict budget, plus approval before any billable call.
- **Current substitute:** 50 deterministic fixtures, parser tests, prompt contract checks, and stored semantic review.

## B-006 - Native accessibility and device matrix

- **Blocked tests:** VoiceOver order, native focus labels, dark mode, notch/Dynamic Island, keyboard occlusion, minimum supported iOS, current iOS, Pro Max layout.
- **Needed:** Xcode Simulator matrix and at least one physical iPhone.

## B-007 - CI execution evidence

- **Reason:** Workflow file was created locally but has not yet run on GitHub.
- **Needed:** Push the QA branch and trigger `LoveKey iOS QA`; inspect logs/artifacts and fix any macOS-only failure before a PR is merged.

## B-008 - Local integration-test launch

- **Windows attempt:** `flutter test integration_test/app_smoke_test.dart -d windows` reached the native build, then failed because `flutter_secure_storage_windows` requires Visual Studio ATL/MFC header `atlstr.h`, which is not installed.
- **Chrome attempt:** Flutter rejected the target with `Web devices are not supported for integration tests yet.`
- **Result:** Integration smoke test was not launched locally and is not marked as passed.
- **Needed:** Run the prepared test on the macOS iOS QA workflow, or install the required Visual Studio ATL/MFC component for a separate Windows-only smoke run.
