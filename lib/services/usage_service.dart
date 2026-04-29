import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/utils/constants.dart';

class UsageService extends ChangeNotifier {
  int _usedToday = 0;
  bool _isSubscribed = false;

  int get usedToday => _usedToday;
  int get remainingFree =>
      (AppConstants.freeDailyLimit - _usedToday).clamp(0, AppConstants.freeDailyLimit);
  bool get canUseForFree => _usedToday < AppConstants.freeDailyLimit;
  bool get isSubscribed => _isSubscribed;
  bool get canUse => _isSubscribed || canUseForFree;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isSubscribed = prefs.getBool(AppConstants.prefIsSubscribed) ?? false;
    await checkAndReset();
  }

  Future<void> checkAndReset() async {
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
  }

  Future<bool> recordUsage() async {
    if (!canUse) return false;

    if (!_isSubscribed) {
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
    notifyListeners();
  }
}
