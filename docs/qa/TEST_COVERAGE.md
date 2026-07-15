# LoveKey Test Coverage Matrix

Legend: **PASS** actually executed, **MOCK** deterministic non-production simulation, **BLOCKED** not executed, **CI** prepared for macOS CI.

| Feature | Test type | Status | Evidence |
| --- | --- | --- | --- |
| Dependency resolution | Flutter command | PASS | `flutter pub get` |
| Static analysis | Analyzer | PASS | 0 issues |
| Existing unit/widget tests | Flutter test | PASS | Full suite 25/25 |
| Focused UI audit | Widget | PASS | 9/9 via `scripts/ui_audit.sh` |
| AI response parsing | Unit | PASS | 9 parser/quality tests |
| 50 dialogue cases | Fixture/rule | MOCK | 50/50 rule pass |
| Semantic dialogue rubric | Stored human review | MOCK | 50/50 threshold pass |
| Live deployed AI model | End-to-end | BLOCKED | No paid/test API endpoint used |
| Compact Home/Profile | Widget | PASS | 320x568 regression |
| Onboarding large text | Widget | PASS | 320x568, 1.3x |
| Keyboard guide copy | Widget | PASS | Current one-reply flow asserted |
| Paywall compact layout | Widget | PASS | Scroll and preview state asserted |
| Privacy notice compact layout | Widget | PASS | 320x568, 1.3x |
| Account UI state | Widget | PASS | Configured/unavailable branches |
| Local core navigation | Integration test source | BLOCKED locally / CI | Windows build lacks `atlstr.h`; Web device unsupported by command |
| iOS Simulator build | Native build | CI / BLOCKED locally | `.github/workflows/ios-qa.yml` |
| iOS Simulator launch | Integration | CI / BLOCKED locally | macOS/Xcode required |
| Email registration/login | Live backend | BLOCKED | Test Supabase account/environment required |
| Google login/cancel | Native provider | BLOCKED | iOS device/provider session required |
| Apple login/cancel | Native provider | BLOCKED | iOS device/provider session required |
| Session expiry/restart | Live backend | BLOCKED | Test backend and native app required |
| Keyboard paste/generate/fill | Native extension | BLOCKED | Physical TestFlight device required |
| LINE/IG/iMessage compatibility | Native extension | BLOCKED | Physical TestFlight device required |
| Weekly/yearly/lifetime display | RevenueCat source/config docs | PARTIAL | Real device still required |
| Purchase/cancel/fail/pending | Sandbox store | BLOCKED | Apple Sandbox/StoreKit required |
| Restore/reinstall/entitlement | Sandbox store | BLOCKED | Apple Sandbox/StoreKit required |
| Dark mode/VoiceOver/Safe Area | Native UI | BLOCKED | iOS Simulator/device required |

## Permanent Automation Added

- `scripts/ios_qa.sh`
- `scripts/dialogue_eval.sh`
- `scripts/ui_audit.sh`
- `.github/workflows/ios-qa.yml`
- `.agents/skills/lovekey-ios-qa/SKILL.md`
- `AGENTS.md`

The workflow fails on analyzer, test, build, or integration failures and uploads `build/qa/` plus `docs/qa/`. It does not use `continue-on-error` for core gates.
