enum AchievementRewardType {
  freePro,
  freePackage,
  unlockFeature,
  purchasable,
}

class Achievement {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String requirement;
  final AchievementRewardType rewardType;
  final String? rewardProductId;
  final double? rewardPrice;
  final int maxProgress;
  int progress;
  bool isUnlocked;

  Achievement({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.requirement,
    required this.rewardType,
    this.rewardProductId,
    this.rewardPrice,
    required this.maxProgress,
    this.progress = 0,
    this.isUnlocked = false,
  });

  double get progressPercent =>
      maxProgress > 0 ? (progress / maxProgress).clamp(0.0, 1.0) : 0.0;

  bool get isComplete => progress >= maxProgress;

  String get progressText => '$progress/$maxProgress';

  String get rewardDescription {
    switch (rewardType) {
      case AchievementRewardType.freePro:
        return '免費 PRO 體驗';
      case AchievementRewardType.freePackage:
        return '免費禮包';
      case AchievementRewardType.unlockFeature:
        return '解鎖隱藏功能';
      case AchievementRewardType.purchasable:
        return rewardPrice != null ? '可購買 \$${rewardPrice!.toStringAsFixed(2)}' : '可購買';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'progress': progress,
        'isUnlocked': isUnlocked,
      };

  void loadFromJson(Map<String, dynamic> json) {
    progress = json['progress'] as int? ?? 0;
    isUnlocked = json['isUnlocked'] as bool? ?? false;
  }

  // ── Pre-defined achievements ──────────────────────────────────────────

  static List<Achievement> allAchievements() => [
        Achievement(
          id: 'chat_beginner',
          name: '聊天新手',
          emoji: '\u{1F4AC}',
          description: '累計生成 10 次回覆',
          requirement: '生成 10 次回覆即可解鎖',
          rewardType: AchievementRewardType.freePackage,
          maxProgress: 10,
        ),
        Achievement(
          id: 'streak_7',
          name: '連續 7 天',
          emoji: '\u{1F525}',
          description: '連續使用 7 天',
          requirement: '每天至少使用一次，連續 7 天',
          rewardType: AchievementRewardType.freePro,
          maxProgress: 7,
        ),
        Achievement(
          id: 'reply_master',
          name: '百次達人',
          emoji: '\u{1F4AF}',
          description: '累計生成 100 次回覆',
          requirement: '累計使用 100 次後可購買獎勵',
          rewardType: AchievementRewardType.purchasable,
          rewardProductId: 'com.ailovekeyboard.achievement.charm_analysis',
          rewardPrice: 2.99,
          maxProgress: 100,
        ),
        Achievement(
          id: 'analysis_expert',
          name: '溫度計大師',
          emoji: '\u{1F321}\uFE0F',
          description: '使用聊天分析 10 次',
          requirement: '使用聊天溫度計 10 次後可購買獎勵',
          rewardType: AchievementRewardType.purchasable,
          rewardProductId: 'com.ailovekeyboard.achievement.relationship_report',
          rewardPrice: 1.99,
          maxProgress: 10,
        ),
        Achievement(
          id: 'date_success',
          name: '約會成功',
          emoji: '\u{1F495}',
          description: '使用約會邀請 5 次',
          requirement: '使用約會邀請功能 5 次後可購買獎勵',
          rewardType: AchievementRewardType.purchasable,
          rewardProductId: 'com.ailovekeyboard.achievement.date_coach',
          rewardPrice: 3.99,
          maxProgress: 5,
        ),
        Achievement(
          id: 'international',
          name: '國際戀人',
          emoji: '\u{1F30D}',
          description: '使用翻譯回覆 10 次',
          requirement: '使用翻譯回覆功能 10 次後可購買獎勵',
          rewardType: AchievementRewardType.purchasable,
          rewardProductId: 'com.ailovekeyboard.achievement.cross_culture',
          rewardPrice: 2.99,
          maxProgress: 10,
        ),
        Achievement(
          id: 'style_master',
          name: '風格達人',
          emoji: '\u{1F4DD}',
          description: '使用過所有 10 種風格',
          requirement: '使用過所有回覆風格即可解鎖隱藏風格',
          rewardType: AchievementRewardType.unlockFeature,
          maxProgress: 10,
        ),
        Achievement(
          id: 'love_master',
          name: '戀愛大師',
          emoji: '\u{1F451}',
          description: '完成所有成就',
          requirement: '完成所有其他成就即可獲得永久 PRO 徽章',
          rewardType: AchievementRewardType.freePro,
          maxProgress: 7,
        ),
      ];
}
