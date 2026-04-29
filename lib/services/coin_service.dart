import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single coin transaction record.
class CoinTransaction {
  final String id;
  final int amount;
  final String feature;
  final DateTime timestamp;
  final bool isCredit;

  const CoinTransaction({
    required this.id,
    required this.amount,
    required this.feature,
    required this.timestamp,
    required this.isCredit,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'feature': feature,
        'timestamp': timestamp.toIso8601String(),
        'isCredit': isCredit,
      };

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: json['id'] as String,
      amount: json['amount'] as int,
      feature: json['feature'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isCredit: json['isCredit'] as bool,
    );
  }
}

class CoinService extends ChangeNotifier {
  static const String _prefBalanceKey = 'coin_balance';
  static const String _prefHistoryKey = 'coin_history';
  static const String _prefLastLoginKey = 'coin_last_login_date';

  int _balance = 0;
  List<CoinTransaction> _history = [];
  bool _initialized = false;

  bool get initialized => _initialized;
  int get balance => _balance;
  List<CoinTransaction> get history => List.unmodifiable(_history);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _balance = prefs.getInt(_prefBalanceKey) ?? 0;

    final rawHistory = prefs.getString(_prefHistoryKey);
    if (rawHistory != null) {
      final decoded = jsonDecode(rawHistory) as List<dynamic>;
      _history = decoded
          .map((e) => CoinTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Check daily login reward
    await _checkDailyLogin(prefs);

    _initialized = true;
    notifyListeners();
  }

  Future<void> _checkDailyLogin(SharedPreferences prefs) async {
    final lastLogin = prefs.getString(_prefLastLoginKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastLogin != today) {
      await prefs.setString(_prefLastLoginKey, today);
      await _creditCoins(1, '每日登入獎勵');
    }
  }

  /// Add coins (e.g., from purchase or reward).
  Future<void> addCoins(int amount, {String feature = '購買金幣'}) async {
    await _creditCoins(amount, feature);
    notifyListeners();
  }

  /// Spend coins on a feature. Returns true if successful.
  Future<bool> spendCoins(int amount, String feature) async {
    if (_balance < amount) return false;
    _balance -= amount;
    _history.add(CoinTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      feature: feature,
      timestamp: DateTime.now(),
      isCredit: false,
    ));
    await _save();
    notifyListeners();
    return true;
  }

  /// Check if user has enough coins.
  bool hasEnoughCoins(int amount) => _balance >= amount;

  Future<void> _creditCoins(int amount, String feature) async {
    _balance += amount;
    _history.add(CoinTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      feature: feature,
      timestamp: DateTime.now(),
      isCredit: true,
    ));
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefBalanceKey, _balance);
    // Keep only last 100 transactions
    if (_history.length > 100) {
      _history = _history.sublist(_history.length - 100);
    }
    await prefs.setString(
      _prefHistoryKey,
      jsonEncode(_history.map((t) => t.toJson()).toList()),
    );
  }
}
