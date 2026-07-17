import 'package:ai_love_keyboard/services/account_service.dart';
import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/coin_service.dart';
import 'package:ai_love_keyboard/services/revenuecat_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/views/home/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('core navigation and local input smoke test', (tester) async {
    SharedPreferences.setMockInitialValues({
      'coin_balance': 20,
      'coin_last_login_date': DateTime.now().toIso8601String().substring(0, 10),
    });

    final usage = UsageService();
    await usage.init();
    final coins = CoinService();
    await coins.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AiService()),
          ChangeNotifierProvider.value(value: AccountService.instance),
          ChangeNotifierProvider.value(value: usage),
          ChangeNotifierProvider.value(value: RevenueCatService.instance),
          ChangeNotifierProvider.value(value: coins),
        ],
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await pumpUi(tester);

    expect(find.text('我的鍵盤'), findsOneWidget);
    final composer = find.byType(TextField).first;
    await tester.enterText(composer, '哈哈');
    expect(find.text('哈哈'), findsOneWidget);

    await tester.tap(find.text('盲盒交友').last);
    await pumpUi(tester);
    expect(find.text('交友盲盒'), findsWidgets);

    await tester.tap(find.text('我的').last);
    await pumpUi(tester);
    expect(find.text('鍵盤設定與教學'), findsOneWidget);

    await tester.tap(find.text('首頁').last);
    await pumpUi(tester);
    expect(find.text('我的鍵盤'), findsOneWidget);
  });
}
