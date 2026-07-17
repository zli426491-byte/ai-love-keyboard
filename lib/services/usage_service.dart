import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/utils/constants.dart';

class UsageService extends ChangeNotifier with WidgetsBindingObserver {
  static const MethodChannel _subscriptionChannel = MethodChannel(
    'com.ailovekeyboard.app/subscription',
  );

  int _usedToday = 0;
  bool _isSubscribed = false;
  bool _initialized = false;
  bool _refreshInFlight = false;

  int get usedToday => _usedToday;
  int get remainingFree => AppConstants.allowFreeTier
      ? (AppConstants.freeDailyLimit - _usedToday).clamp(
          0,
          AppConstants.freeDailyLimit,
        )
      : 0;
  bool get canUseForFree =>
      AppConstants.allowFreeTier &&
      (AppConstants.reviewFreeMode || _usedToday < AppConstants.freeDailyLimit);
  bool get isSubscribed => _isSubscribed;
  bool get canUse =>
      AppConstants.reviewFreeMode || _isSubscribed || canUseForFree;

  Future<void> init() async {
    if (_initialized) return;
    WidgetsBinding.instance.addObserver(this);
    final prefs = await SharedPreferences.getInstance();
    _isSubscribed = prefs.getBool(AppConstants.prefIsSubscribed) ?? false;
    await checkAndReset();
    await _syncSubscriptionToKeyboard(_isSubscribed);
    _initialized = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _initialized) {
      // A backgrounded app can cross midnight while its in-memory counter is
      // still from the previous day. Refresh before the next action/UI paint.
      checkAndReset();
    }
  }

  Future<void> checkAndReset() async {
    if (_refreshInFlight) return;
    _refreshInFlight = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDate = prefs.getString(AppConstants.prefLastUsageDate) ?? '';
      final today = DateTime.now().toIso8601String().substring(0, 10);

      if (lastDate != today) {
        // New day — reset counter
        _usedToday = 0;
        await prefs.setInt(AppConstants.prefDailyUsageCount, 0);
        await prefs.setString(AppConstants.prefLastUsageDate, today);
      } else {
        _usedToday = prefs.getInt(AppConstants.prefDailyUsageCount) ?? 0;
      }
      notifyListeners();
    } finally {
      _refreshInFlight = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<bool> recordUsage() async {
    if (!canUse) return false;
    if (AppConstants.reviewFreeMode) return true;

    if (AppConstants.allowFreeTier && !_isSubscribed) {
      _usedToday++;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.prefDailyUsageCount, _usedToday);
    }
    notifyListeners();
    return true;
  }

  Future<void> setSubscribed(bool value) async {
    _isSubscribed = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefIsSubscribed, value);
    await _syncSubscriptionToKeyboard(value);
    notifyListeners();
  }

  Future<void> _syncSubscriptionToKeyboard(bool value) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

    try {
      await _subscriptionChannel.invokeMethod<void>(
        'setSubscriptionStatus',
        <String, bool>{'isSubscribed': value},
      );
    } on PlatformException catch (error) {
      debugPrint('Unable to sync subscription to keyboard: ${error.code}');
    } on MissingPluginException {
      debugPrint('Subscription bridge is unavailable on this build.');
    }
  }
}
