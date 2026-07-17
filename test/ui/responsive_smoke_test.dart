import 'package:ai_love_keyboard/views/auth/account_view.dart';
import 'package:ai_love_keyboard/views/home/home_view.dart';
import 'package:ai_love_keyboard/views/keyboard/keyboard_guide_view.dart';
import 'package:ai_love_keyboard/views/onboarding/onboarding_view.dart';
import 'package:ai_love_keyboard/views/paywall/paywall_view.dart';
import 'package:ai_love_keyboard/views/components/privacy_notice_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home remains usable on an iPhone SE-sized viewport', (
    tester,
  ) async {
    await pumpLoveKeyTestApp(
      tester,
      const HomeView(),
      size: const Size(320, 568),
    );

    expect(find.text('我的鍵盤'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();
    expect(find.text('語言與系統設定'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding remains readable with larger text', (tester) async {
    await pumpLoveKeyTestApp(
      tester,
      const OnboardingView(),
      size: const Size(320, 568),
      textScaleFactor: 1.3,
    );

    expect(find.textContaining('長按對方訊息'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.textContaining('切到 LoveKey'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard guide exposes current one-reply workflow', (
    tester,
  ) async {
    await pumpLoveKeyTestApp(
      tester,
      const KeyboardGuideView(),
      size: const Size(320, 568),
      textScaleFactor: 1.3,
    );

    expect(find.text('鍵盤教學'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -760));
    await tester.pumpAndSettle();
    expect(find.text('實際使用只要三步'), findsOneWidget);
    expect(find.textContaining('只生成一則可貼上的回覆'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('為什麼要「完整取用」'), 420);
    expect(find.text('為什麼要「完整取用」'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paywall shows a stable non-store preview state', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await pumpLoveKeyTestApp(
        tester,
        const Scaffold(
          body: Align(alignment: Alignment.bottomCenter, child: PaywallView()),
        ),
        size: const Size(320, 568),
      );

      expect(find.text('LoveKey Pro'), findsOneWidget);
      expect(find.textContaining('Web 預覽'), findsOneWidget);
      expect(find.textContaining('RevenueCat'), findsNothing);
      expect(find.text('請在 iOS／Android 實機完成購買'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'account screen exposes a clear configured or unavailable state',
    (tester) async {
      await pumpLoveKeyTestApp(
        tester,
        const AccountView(),
        size: const Size(320, 568),
        textScaleFactor: 1.3,
      );

      expect(find.text('LoveKey 帳號'), findsOneWidget);
      final fields = find.byType(TextField);
      if (fields.evaluate().isNotEmpty) {
        expect(fields, findsNWidgets(2));
        await tester.enterText(fields.first, 'qa@example.com');
        await tester.enterText(fields.last, 'test-password');
        expect(find.text('qa@example.com'), findsOneWidget);
      } else {
        expect(find.textContaining('帳號服務尚未設定'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('privacy notice fits a compact phone viewport', (tester) async {
    await pumpLoveKeyTestApp(
      tester,
      PrivacyNoticeDialog(onAccept: () {}),
      size: const Size(320, 568),
      textScaleFactor: 1.3,
    );

    final dialog = tester.getRect(find.byType(Dialog));
    expect(dialog.left, greaterThanOrEqualTo(0));
    expect(dialog.right, lessThanOrEqualTo(320));
    expect(dialog.top, greaterThanOrEqualTo(0));
    expect(dialog.bottom, lessThanOrEqualTo(568));
    expect(tester.takeException(), isNull);
  });
}
