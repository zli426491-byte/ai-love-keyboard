import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/models/situation_package.dart';

class PackageManager extends ChangeNotifier {
  static const String _prefKey = 'situation_packages';

  /// Map of SituationType name -> remaining uses
  Map<String, int> _purchases = {};

  /// Tracks which situation types have been dismissed this session.
  final Set<SituationType> _dismissedThisSession = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _purchases = decoded.map((k, v) => MapEntry(k, v as int));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(_purchases));
  }

  /// Simulate purchasing a package (adds total uses).
  Future<void> purchasePackage(SituationType type) async {
    final pkg = SituationPackage.getPackage(type);
    final key = type.name;
    _purchases[key] = (_purchases[key] ?? 0) + pkg.totalUses;
    await _save();
    notifyListeners();
  }

  /// Whether the user owns the given package (has remaining uses).
  bool hasPackage(SituationType type) {
    return (_purchases[type.name] ?? 0) > 0;
  }

  /// How many uses remain for a given package.
  int remainingUses(SituationType type) {
    return _purchases[type.name] ?? 0;
  }

  /// Consume one use of a package. Returns false if no uses left.
  Future<bool> usePackage(SituationType type) async {
    final key = type.name;
    final remaining = _purchases[key] ?? 0;
    if (remaining <= 0) return false;

    _purchases[key] = remaining - 1;
    await _save();
    notifyListeners();
    return true;
  }

  /// Whether the dialog for this type has been dismissed this session.
  bool isDismissedThisSession(SituationType type) {
    return _dismissedThisSession.contains(type);
  }

  /// Mark a situation type as dismissed for this session.
  void dismissForSession(SituationType type) {
    _dismissedThisSession.add(type);
  }

  /// Whether we should show the package dialog for a detected situation.
  bool shouldShowDialog(SituationType type) {
    return !hasPackage(type) && !isDismissedThisSession(type);
  }
}
