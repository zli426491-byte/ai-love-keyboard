import 'package:ai_love_keyboard/services/account_service.dart';
import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/coin_service.dart';
import 'package:ai_love_keyboard/services/locale_service.dart';
import 'package:ai_love_keyboard/services/privacy_manager.dart';
import 'package:ai_love_keyboard/services/revenuecat_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpLoveKeyTestApp(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(430, 932),
  double textScaleFactor = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

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
      child: MaterialApp(
        builder: (context, appChild) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: appChild!,
          );
        },
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
