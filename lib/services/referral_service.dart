import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReferralReward {
  final String id;
  final String name;
  final String description;
  final DateTime claimedAt;

  const ReferralReward({
    required this.id,
    required this.name,
    required this.description,
    required this.claimedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'claimedAt': claimedAt.toIso8601String(),
      };

  factory ReferralReward.fromJson(Map<String, dynamic> json) {
    return ReferralReward(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      claimedAt: DateTime.parse(json['claimedAt'] as String),
    );
  }
}

class ReferralService extends ChangeNotifier {
  static const String _prefCodeKey = 'referral_code';
  static const String _prefCountKey = 'referral_count';
  static const String _prefRewardsKey = 'referral_rewards';
  static const String _prefSharedIgKey = 'referral_shared_ig';

  String _referralCode = '';
  int _referralCount = 0;
  List<ReferralReward> _rewards = [];
  bool _hasSharedToIg = false;
  bool _initialized = false;

  bool get initialized => _initialized;
  String get referralCode => _referralCode;
  int get referralCount => _referralCount;
  List<ReferralReward> get rewards => List.unmodifiable(_rewards);
  bool get hasSharedToIg => _hasSharedToIg;

  /// Progress toward 3-friend reward.
  int get friendRewardProgress => _referralCount.clamp(0, 3);
  bool get hasFriendReward => _referralCount >= 3;

  /// Shareable referral link with UTM parameters.
  String get shareLink =>
      'https://ailovekeyboard.app/invite?ref=$_referralCode'
      '&utm_source=referral&utm_medium=app&utm_campaign=invite';

  /// Pre-written share text for different platforms.
  String get shareTextLine =>
      'AI 戀愛鍵盤超好用！用我的邀請碼 $_referralCode 一起來用\n$shareLink';

  String get shareTextIg =>
      'AI 幫我成功搭訕！這個 App 太神了\n立即下載：$shareLink';

  String get shareTextFb =>
      '推薦一個超強戀愛助手 App！\n邀請碼：$_referralCode\n$shareLink';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _referralCode = prefs.getString(_prefCodeKey) ?? _generateCode();
    _referralCount = prefs.getInt(_prefCountKey) ?? 0;
    _hasSharedToIg = prefs.getBool(_prefSharedIgKey) ?? false;

    final rawRewards = prefs.getString(_prefRewardsKey);
    if (rawRewards != null) {
      final decoded = jsonDecode(rawRewards) as List<dynamic>;
      _rewards = decoded
          .map((r) => ReferralReward.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    // Save generated code if new
    if (!prefs.containsKey(_prefCodeKey)) {
      await prefs.setString(_prefCodeKey, _referralCode);
    }

    _initialized = true;
    notifyListeners();
  }

  /// Generate a unique 6-character referral code.
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  /// Record a successful referral (friend installed).
  Future<void> recordReferral() async {
    _referralCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefCountKey, _referralCount);

    // Auto-grant rewards at milestones
    if (_referralCount == 1) {
      await _addReward(ReferralReward(
        id: 'first_referral',
        name: '首次邀請獎勵',
        description: '獲得 3 次免費回覆',
        claimedAt: DateTime.now(),
      ));
    }
    if (_referralCount == 3) {
      await _addReward(ReferralReward(
        id: 'three_referrals',
        name: '三人成行獎勵',
        description: '獲得 1 個免費情境禮包',
        claimedAt: DateTime.now(),
      ));
    }

    notifyListeners();
  }

  /// Record sharing to Instagram.
  Future<void> recordIgShare() async {
    if (_hasSharedToIg) return;
    _hasSharedToIg = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSharedIgKey, true);

    await _addReward(ReferralReward(
      id: 'ig_share',
      name: 'IG 分享獎勵',
      description: '獲得 1 天 PRO 體驗',
      claimedAt: DateTime.now(),
    ));

    notifyListeners();
  }

  Future<void> _addReward(ReferralReward reward) async {
    _rewards.add(reward);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefRewardsKey,
      jsonEncode(_rewards.map((r) => r.toJson()).toList()),
    );
  }
}
