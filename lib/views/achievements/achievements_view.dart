import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/models/achievement.dart';
import 'package:ai_love_keyboard/services/achievement_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';

class AchievementsView extends StatelessWidget {
  const AchievementsView({super.key});

  @override
  Widget build(BuildContext context) {
    final achievementService = context.watch<AchievementService>();
    final achievements = achievementService.achievements;

    return Scaffold(
      appBar: AppBar(
        title: const Text('成就系統'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${achievementService.unlockedCount}/${achievements.length}',
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          return _AchievementCard(
            achievement: achievement,
            onTap: () => _showDetail(context, achievement),
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, Achievement achievement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AchievementDetailSheet(achievement: achievement),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onTap;

  const _AchievementCard({
    required this.achievement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;
    final isComplete = achievement.isComplete;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isUnlocked
                ? AppTheme.gold.withValues(alpha: 0.6)
                : isComplete
                    ? AppTheme.accent.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.06),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: AppTheme.gold.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Emoji container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppTheme.gold.withValues(alpha: 0.15)
                    : AppTheme.bgCardLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Center(
                child: Text(
                  achievement.emoji,
                  style: TextStyle(
                    fontSize: 26,
                    color: isUnlocked ? null : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        achievement.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked
                              ? AppTheme.gold
                              : AppTheme.textPrimary,
                        ),
                      ),
                      if (isUnlocked) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded,
                            color: AppTheme.gold, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          child: LinearProgressIndicator(
                            value: achievement.progressPercent,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isUnlocked
                                  ? AppTheme.gold
                                  : isComplete
                                      ? AppTheme.accent
                                      : AppTheme.primary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        achievement.progressText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isComplete
                              ? AppTheme.accent
                              : AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade600,
              size: 22,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400));
  }
}

class _AchievementDetailSheet extends StatelessWidget {
  final Achievement achievement;

  const _AchievementDetailSheet({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isComplete = achievement.isComplete;
    final isUnlocked = achievement.isUnlocked;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Emoji
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? AppTheme.gold.withValues(alpha: 0.15)
                  : AppTheme.bgCardLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: isUnlocked
                  ? Border.all(color: AppTheme.gold.withValues(alpha: 0.4), width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                achievement.emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Name
          Text(
            achievement.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color:
                  isUnlocked ? AppTheme.gold : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            achievement.requirement,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Progress
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.bgCardLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '進度',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  achievement.progressText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isComplete
                        ? AppTheme.accent
                        : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // Reward info
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.bgCardLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '獎勵',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  achievement.rewardDescription,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isComplete
                        ? AppTheme.accent
                        : AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Action button
          if (isComplete && !isUnlocked)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context
                      .read<AchievementService>()
                      .unlockAchievement(achievement.id);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  achievement.rewardType ==
                          AchievementRewardType.purchasable
                      ? '購買獎勵 ${achievement.rewardDescription}'
                      : '領取獎勵',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            )
          else if (isUnlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.3)),
              ),
              child: const Center(
                child: Text(
                  '已解鎖',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppTheme.spacingMd),
        ],
      ),
    );
  }
}
