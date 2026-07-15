# LoveKey TestFlight Readiness

## Decision

**GO for a new internal TestFlight QA build.**

**NO-GO for App Store submission or paid acquisition until the native checklist below passes.**

## Evidence Supporting Internal TestFlight

- Flutter dependencies resolve.
- Analyzer reports 0 issues.
- Full local Flutter suite passes: 25/25.
- Dialogue suite passes: 14/14 in clearly labeled mock/static mode.
- 50 fixed Traditional Chinese dialogue cases cover all required categories.
- Eight P2 defects were reproduced, minimally fixed, and covered by regression tests.
- Compact layout tests now cover Home/Profile, onboarding, keyboard guide, paywall, account, and privacy gate.
- macOS iOS QA workflow and local scripts are present.

## Native Exit Checklist

All boxes must be completed with Build 55 or the next QA build before App Store submission:

- [ ] Install fresh from TestFlight on a physical iPhone.
- [ ] Accept privacy notice; complete and repeat onboarding.
- [ ] Add LoveKey keyboard and enable Full Access.
- [ ] Copy a message in LINE, Instagram, and iMessage.
- [ ] Generate exactly one reply, retry, and fill it into each host app.
- [ ] Verify empty, short, long, multiline, emoji, and special-symbol inputs.
- [ ] Verify rapid repeated taps do not duplicate requests or flash the full keyboard UI.
- [ ] Verify network loss, slow network, timeout, and model refusal states.
- [ ] Verify weekly, yearly, and lifetime products and localized prices.
- [ ] Complete sandbox purchase success/cancel/failure/pending cases.
- [ ] Restore purchase with and without a prior transaction.
- [ ] Verify entitlement after relaunch, logout/login, and reinstall.
- [ ] Verify Email, Google, and Apple login/cancel flows.
- [ ] Verify small iPhone, standard iPhone, and Pro Max layouts.
- [ ] Verify light/dark mode, large text, VoiceOver, Safe Area, and keyboard occlusion.
- [ ] Run the GitHub `LoveKey iOS QA` workflow successfully and retain artifacts.

## Current Store State

Tracked project status documents report TestFlight Build 55 as VALID/Internal Testing. App Store version 1.0.4 is still in PREPARE_FOR_SUBMISSION and the public version remains 1.0.2. These server-side facts were not mutated in this QA cycle.

## Monetization Readiness

Do not start paid traffic based only on this Windows QA pass. The paywall layout is stable in Flutter tests, but real localized pricing, purchase, cancellation, restore, and entitlement persistence still require Apple Sandbox evidence.
