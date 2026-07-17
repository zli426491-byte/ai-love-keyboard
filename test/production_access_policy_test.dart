import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('production blocks AI usage until Pro is active', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final usage = UsageService();
    await usage.init();

    expect(AppConstants.allowFreeTier, isFalse);
    expect(usage.remainingFree, 0);
    expect(usage.canUseForFree, isFalse);
    expect(usage.canUse, isFalse);
    expect(await usage.recordUsage(), isFalse);

    await usage.setSubscribed(true);
    expect(usage.canUse, isTrue);
    expect(await usage.recordUsage(), isTrue);
    expect(usage.usedToday, 0);

    await usage.setSubscribed(false);
    expect(usage.canUse, isFalse);
    usage.dispose();
  });

  test('production Worker and iOS keyboard enforce the same Pro policy', () {
    final workerConfig = File(
      'cloudflare-worker/wrangler.toml',
    ).readAsStringSync();
    final keyboardSource = File(
      'ios/LoveKeyboard/KeyboardViewController.swift',
    ).readAsStringSync();

    expect(workerConfig, contains('REQUIRE_ACTIVE_PRO = "true"'));
    expect(keyboardSource, contains('guard SharedConfig.isPro else'));
    expect(keyboardSource, contains('"identity_mismatch"'));
    expect(keyboardSource, contains('"auth_invalid"'));
  });
}
