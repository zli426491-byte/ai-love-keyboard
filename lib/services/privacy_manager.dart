import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user privacy: PII stripping, data history, consent tracking.
class PrivacyManager extends ChangeNotifier {
  PrivacyManager._();
  static final PrivacyManager instance = PrivacyManager._();

  static const String _prefPrivacyAccepted = 'privacy_policy_accepted';
  static const String _prefAutoStripPii = 'privacy_auto_strip_pii';
  static const String _prefAutoDeleteHistory = 'privacy_auto_delete_24h';
  static const String _prefDataSentHistory = 'privacy_data_sent_history';
  static const String _prefFilterLevel = 'privacy_filter_level';

  late SharedPreferences _prefs;

  bool _privacyAccepted = false;
  bool _autoStripPii = true;
  bool _autoDeleteHistory = false;
  List<DataSentRecord> _dataSentHistory = [];
  String _filterLevel = 'standard'; // 'standard' | 'strict'

  // ── Getters ──────────────────────────────────────────────────────────

  bool get privacyAccepted => _privacyAccepted;
  bool get autoStripPii => _autoStripPii;
  bool get autoDeleteHistory => _autoDeleteHistory;
  List<DataSentRecord> get dataSentHistory =>
      List.unmodifiable(_dataSentHistory);
  String get filterLevel => _filterLevel;

  // ── Init ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _privacyAccepted = _prefs.getBool(_prefPrivacyAccepted) ?? false;
    _autoStripPii = _prefs.getBool(_prefAutoStripPii) ?? true;
    _autoDeleteHistory = _prefs.getBool(_prefAutoDeleteHistory) ?? false;
    _filterLevel = _prefs.getString(_prefFilterLevel) ?? 'standard';
    _loadDataSentHistory();

    // Auto-delete old history if enabled
    if (_autoDeleteHistory) {
      _purgeOldRecords();
    }
  }

  // ── Privacy consent ──────────────────────────────────────────────────

  Future<void> acceptPrivacyPolicy() async {
    _privacyAccepted = true;
    await _prefs.setBool(_prefPrivacyAccepted, true);
    notifyListeners();
  }

  // ── PII Stripping ───────────────────────────────────────────────────

  /// Regex patterns for stripping PII.
  static final List<_PiiPattern> _piiPatterns = [
    // Phone numbers: TW, HK, JP, KR, US, UK, CN
    _PiiPattern(
      'phone',
      RegExp(
          r'(?:\+?(?:886|852|81|82|1|44|86)[\s-]?)?\(?\d{2,4}\)?[\s.-]?\d{3,4}[\s.-]?\d{3,4}'),
    ),
    // Email addresses
    _PiiPattern(
      'email',
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
    ),
    // Taiwan National ID
    _PiiPattern(
      'id_number',
      RegExp(r'[A-Z][12]\d{8}'),
    ),
    // Passport numbers (generic)
    _PiiPattern(
      'passport',
      RegExp(r'\b[A-Z]{1,2}\d{7,9}\b'),
    ),
    // Credit card numbers
    _PiiPattern(
      'credit_card',
      RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'),
    ),
    // URLs with possible personal info
    _PiiPattern(
      'url',
      RegExp(
          r'https?://[^\s]+(?:profile|user|account|id)[^\s]*',
          caseSensitive: false),
    ),
    // Physical addresses (basic: contains 路/街/巷/弄/號 for TW)
    _PiiPattern(
      'address',
      RegExp(r'[\u4e00-\u9fff]+(?:市|縣)[\u4e00-\u9fff]+(?:區|鄉|鎮)[\u4e00-\u9fff]*(?:路|街|巷|弄|號)[\u4e00-\u9fff0-9]*'),
    ),
  ];

  /// Strips PII from text. Returns the cleaned text.
  String stripPii(String text) {
    if (!_autoStripPii) return text;

    var result = text;
    for (final pattern in _piiPatterns) {
      result = result.replaceAll(pattern.regex, '[***]');
    }
    return result;
  }

  /// Check if text contains PII.
  bool containsPii(String text) {
    for (final pattern in _piiPatterns) {
      if (pattern.regex.hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  // ── Settings ─────────────────────────────────────────────────────────

  Future<void> setAutoStripPii(bool value) async {
    _autoStripPii = value;
    await _prefs.setBool(_prefAutoStripPii, value);
    notifyListeners();
  }

  Future<void> setAutoDeleteHistory(bool value) async {
    _autoDeleteHistory = value;
    await _prefs.setBool(_prefAutoDeleteHistory, value);
    if (value) _purgeOldRecords();
    notifyListeners();
  }

  Future<void> setFilterLevel(String level) async {
    _filterLevel = level;
    await _prefs.setString(_prefFilterLevel, level);
    notifyListeners();
  }

  // ── Data sent history ────────────────────────────────────────────────

  /// Record that data was sent to the AI API.
  Future<void> recordDataSent({
    required String feature,
    required int characterCount,
  }) async {
    final record = DataSentRecord(
      timestamp: DateTime.now(),
      feature: feature,
      characterCount: characterCount,
    );
    _dataSentHistory.add(record);

    // Keep max 200 records
    if (_dataSentHistory.length > 200) {
      _dataSentHistory = _dataSentHistory.sublist(_dataSentHistory.length - 200);
    }

    await _saveDataSentHistory();
  }

  // ── Delete all data ──────────────────────────────────────────────────

  Future<void> deleteAllLocalData() async {
    _dataSentHistory.clear();
    await _prefs.remove(_prefDataSentHistory);
    notifyListeners();
  }

  // ── Private helpers ──────────────────────────────────────────────────

  void _loadDataSentHistory() {
    final json = _prefs.getString(_prefDataSentHistory);
    if (json != null) {
      try {
        final list = jsonDecode(json) as List<dynamic>;
        _dataSentHistory =
            list.map((e) => DataSentRecord.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _dataSentHistory = [];
      }
    }
  }

  Future<void> _saveDataSentHistory() async {
    final json = jsonEncode(_dataSentHistory.map((r) => r.toJson()).toList());
    await _prefs.setString(_prefDataSentHistory, json);
  }

  void _purgeOldRecords() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    _dataSentHistory.removeWhere((r) => r.timestamp.isBefore(cutoff));
    _saveDataSentHistory();
  }
}

class _PiiPattern {
  final String type;
  final RegExp regex;
  const _PiiPattern(this.type, this.regex);
}

/// A record of data sent to the AI service.
class DataSentRecord {
  final DateTime timestamp;
  final String feature;
  final int characterCount;

  const DataSentRecord({
    required this.timestamp,
    required this.feature,
    required this.characterCount,
  });

  factory DataSentRecord.fromJson(Map<String, dynamic> json) {
    return DataSentRecord(
      timestamp: DateTime.parse(json['timestamp'] as String),
      feature: json['feature'] as String,
      characterCount: json['characterCount'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'feature': feature,
        'characterCount': characterCount,
      };
}
