import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/models/user_locale.dart';

class LocaleService extends ChangeNotifier {
  static const String _prefLocaleKey = 'user_locale';

  UserLocale _currentLocale = UserLocale.taiwan;
  UserLocale _detectedLocale = UserLocale.taiwan;

  UserLocale get currentLocale => _currentLocale;
  UserLocale get detectedLocale => _detectedLocale;

  Future<void> init() async {
    // Detect system locale
    try {
      final systemLocale = Platform.localeName;
      _detectedLocale = UserLocale.fromSystemLocale(systemLocale);
    } catch (_) {
      _detectedLocale = UserLocale.taiwan;
    }

    // Load saved preference
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_prefLocaleKey);

    if (savedId != null) {
      _currentLocale = UserLocale.fromId(savedId);
    } else {
      _currentLocale = _detectedLocale;
    }

    notifyListeners();
  }

  Future<void> setLocale(UserLocale locale) async {
    _currentLocale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLocaleKey, locale.id);
  }
}
