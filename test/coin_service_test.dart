import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/services/coin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    SharedPreferences.setMockInitialValues({'coin_last_login_date': today});
  });

  test('free coin package can only be claimed once', () async {
    final service = CoinService();
    await service.init();

    final results = await Future.wait([
      service.claimFreePackage(
        packageId: 'coins_10',
        amount: 10,
        feature: 'test free package',
      ),
      service.claimFreePackage(
        packageId: 'coins_10',
        amount: 10,
        feature: 'test free package',
      ),
    ]);

    expect(results.where((claimed) => claimed).length, 1);
    expect(service.balance, 10);
    expect(service.hasClaimedFreePackage('coins_10'), isTrue);

    final reloaded = CoinService();
    await reloaded.init();
    expect(reloaded.balance, 10);
    expect(reloaded.hasClaimedFreePackage('coins_10'), isTrue);
  });
}
