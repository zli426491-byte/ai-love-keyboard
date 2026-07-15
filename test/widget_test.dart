import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/account_service.dart';
import 'package:ai_love_keyboard/services/coin_service.dart';
import 'package:ai_love_keyboard/services/locale_service.dart';
import 'package:ai_love_keyboard/services/privacy_manager.dart';
import 'package:ai_love_keyboard/services/revenuecat_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/views/home/home_view.dart';
import 'package:ai_love_keyboard/views/keyboard/keyboard_guide_view.dart';
import 'package:ai_love_keyboard/views/onboarding/onboarding_view.dart';
import 'package:ai_love_keyboard/views/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(430, 932));

  SharedPreferences.setMockInitialValues({
    'coin_balance': 20,
    'coin_last_login_date': DateTime.now().toIso8601String().substring(0, 10),
  });
  final usage = UsageService();
  await usage.init();
  final coins = CoinService();
  await coins.init();
  final locale = LocaleService();
  await locale.init();
  final privacy = PrivacyManager.instance;
  await privacy.init();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AiService()),
        ChangeNotifierProvider.value(value: AccountService.instance),
        ChangeNotifierProvider.value(value: usage),
        ChangeNotifierProvider.value(value: RevenueCatService.instance),
        ChangeNotifierProvider.value(value: coins),
        ChangeNotifierProvider.value(value: locale),
        ChangeNotifierProvider.value(value: privacy),
      ],
      child: MaterialApp(home: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home tabs and blind box flows are reachable', (tester) async {
    await _pumpApp(tester, const HomeView());

    expect(find.text('我的鍵盤'), findsOneWidget);

    await tester.tap(find.text('盲盒交友').last);
    await tester.pumpAndSettle();
    expect(find.text('交友盲盒'), findsWidgets);

    await tester.tap(find.text('放盲盒'));
    await tester.pumpAndSettle();
    expect(find.text('放入盲盒'), findsWidgets);
    await tester.tap(find.text('放入盲盒').last);
    await tester.pumpAndSettle();
    expect(find.text('盲盒已送出'), findsOneWidget);

    await tester.tap(find.text('抽盲盒'));
    await tester.pumpAndSettle();
    expect(find.text('抽到一個盲盒'), findsOneWidget);
  });

  testWidgets('messages and profile actions have visible destinations', (
    tester,
  ) async {
    await _pumpApp(tester, const HomeView());

    await tester.tap(find.text('消息').last);
    await tester.pumpAndSettle();
    expect(find.text('鍵盤已更新'), findsOneWidget);
    expect(find.text('可以放入一則匿名訊息，也可以花 10 金幣抽一個盲盒。'), findsOneWidget);

    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();
    expect(find.text('設定語言'), findsOneWidget);
    expect(find.text('反饋建議'), findsOneWidget);

    await tester.tap(find.text('關於我們'));
    await tester.pumpAndSettle();
    expect(find.text('LoveKey'), findsWidgets);
  });

  testWidgets('onboarding renders key copy', (tester) async {
    await _pumpApp(tester, const OnboardingView());
    expect(find.textContaining('長按對方訊息'), findsOneWidget);
    expect(find.text('下一步'), findsOneWidget);
  });

  testWidgets('keyboard guide renders key copy', (tester) async {
    await _pumpApp(tester, const KeyboardGuideView());
    expect(find.text('鍵盤教學'), findsOneWidget);
    expect(find.textContaining('切到 AI 戀愛鍵盤'), findsWidgets);
    expect(find.text('先登入 LoveKey'), findsOneWidget);
    expect(find.text('前往登入'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('只在生成回覆時送出必要文字'), 420);
    expect(find.text('只在生成回覆時送出必要文字'), findsOneWidget);
  });

  testWidgets('settings renders key copy', (tester) async {
    await _pumpApp(tester, const SettingsView());
    expect(find.text('鍵盤設定'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('為 App 評分'), 500);
    expect(find.text('為 App 評分'), findsOneWidget);
    expect(find.text('分享給朋友'), findsOneWidget);
  });
}
