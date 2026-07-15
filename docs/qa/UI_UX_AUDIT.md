# LoveKey UI / UX Audit

## Executed Coverage

| Area | Viewport / condition | Result |
| --- | --- | --- |
| Home and bottom navigation | 320x568 | Passed after fix |
| Profile membership/menu | 320x568, text scale 1.3 | Passed after fixes |
| Onboarding | 320x568, text scale 1.3 | Passed after fix |
| Current one-reply keyboard guide | 320x568, text scale 1.3 | Passed |
| Paywall preview | 320x568 | Passed after fix |
| Account state | 320x568, text scale 1.3 | Passed |
| First-run privacy notice | 320x568, text scale 1.3 | Passed after fix |
| Standard test harness | 430x932 | Passed |
| Flutter Web render | Local browser smoke | Loaded; supplemental only |

## Defects Reproduced

- Bottom nav: 16px right overflow.
- Onboarding choices: 111px and 75px right overflow.
- Paywall: 269px bottom overflow.
- Membership card: 18px bottom overflow.
- Profile menu: 13px right overflow.
- Privacy notice: 303px bottom overflow.

All six UI defects were fixed with constrained/flexible/scroll behavior and now have regression coverage in `test/ui/responsive_smoke_test.dart`.

## Design Boundary

No broad visual redesign, brand change, color replacement, navigation rewrite, or paywall logic change was made. Fixes reuse existing tokens and widgets and are limited to layout resilience.

## State Review

- **Loading:** Paywall retains its loading indicator; real RevenueCat timing was not exercised.
- **Error:** Web paywall explicitly identifies itself as a preview and does not display a fake RevenueCat failure.
- **Disabled:** Purchase and restore actions remain disabled where the native store is unavailable.
- **Empty/unavailable:** Account screen test accepts either configured fields or a clear unavailable state.
- **Large text:** Onboarding, profile, and privacy gate have targeted 1.3x coverage.

## Not Verified On This Host

- Native iOS Safe Area, notch, Dynamic Island, and keyboard occlusion.
- Dark mode rendering on iOS.
- VoiceOver traversal and native accessibility labels.
- Actual keyboard extension height and layout in LINE, Instagram, or iMessage.
- Minimum supported iOS and latest iOS on Simulator/physical devices.
- Before/after screenshots from an iOS device.

Flutter Web screenshots are not used as native iOS pass evidence because the canvas renderer and browser viewport are not equivalent to UIKit/keyboard-extension rendering.
