import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyService extends ChangeNotifier {
  static const String _prefUsesKey = 'emergency_uses_remaining';

  int _usesRemaining = 0;
  bool _initialized = false;

  bool get initialized => _initialized;
  int get usesRemaining => _usesRemaining;
  bool get hasUses => _usesRemaining > 0;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _usesRemaining = prefs.getInt(_prefUsesKey) ?? 0;
    _initialized = true;
    notifyListeners();
  }

  /// Simulate purchasing one emergency use ($0.99).
  Future<void> purchaseUse() async {
    _usesRemaining++;
    await _save();
    notifyListeners();
  }

  /// Consume one emergency use. Returns false if none remaining.
  Future<bool> consumeUse() async {
    if (_usesRemaining <= 0) return false;
    _usesRemaining--;
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefUsesKey, _usesRemaining);
  }
}
