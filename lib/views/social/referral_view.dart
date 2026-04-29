import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' show Share;

import 'package:ai_love_keyboard/services/referral_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';

class ReferralView extends StatelessWidget {
  const ReferralView({super.key});

  @override
  Widget build(BuildContext context) {
    final referral = context.watch<ReferralService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('邀請好友'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // Referral code card
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              gradient: AppTheme.romanticGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              children: [
                const Text(
                  '你的邀請碼',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  referral.referralCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: referral.referralCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('邀請碼已複製！')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          '複製邀請碼',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: const Duration(milliseconds: 400)),

          const SizedBox(height: AppTheme.spacingLg),

          // Share buttons
          Text(
            '分享到',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              _ShareButton(
                icon: Icons.chat_bubble_rounded,
                label: 'LINE',
                color: const Color(0xFF00B900),
                onTap: () => Share.share(referral.shareTextLine),
              ),
              const SizedBox(width: 12),
              _ShareButton(
                icon: Icons.camera_alt_rounded,
                label: 'IG',
                color: const Color(0xFFE1306C),
                onTap: () {
                  Share.share(referral.shareTextIg);
                  referral.recordIgShare();
                },
              ),
              const SizedBox(width: 12),
              _ShareButton(
                icon: Icons.facebook_rounded,
                label: 'Facebook',
                color: const Color(0xFF1877F2),
                onTap: () => Share.share(referral.shareTextFb),
              ),
              const SizedBox(width: 12),
              _ShareButton(
                icon: Icons.link_rounded,
                label: '複製連結',
                color: AppTheme.primary,
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: referral.shareLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('連結已複製！')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // Progress tracker
          Text(
            '邀請進度',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _ProgressCard(
            current: referral.friendRewardProgress,
            target: 3,
            label: '邀請 3 位好友得免費禮包',
            isComplete: referral.hasFriendReward,
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // IG share reward
          _RewardTile(
            emoji: '\u{1F4F8}',
            title: '分享到 IG 限動',
            subtitle: referral.hasSharedToIg ? '已完成' : '分享即得 1 天 PRO',
            isComplete: referral.hasSharedToIg,
          ),

          // First referral reward
          _RewardTile(
            emoji: '\u{1F91D}',
            title: '邀請 1 位好友',
            subtitle: referral.referralCount >= 1
                ? '已完成'
                : '好友安裝即得 3 次免費回覆',
            isComplete: referral.referralCount >= 1,
          ),

          // Three referrals reward
          _RewardTile(
            emoji: '\u{1F381}',
            title: '邀請 3 位好友',
            subtitle: referral.hasFriendReward
                ? '已完成'
                : '得 1 個免費情境禮包',
            isComplete: referral.hasFriendReward,
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // Reward history
          if (referral.rewards.isNotEmpty) ...[
            Text(
              '獎勵記錄',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ...referral.rewards.reversed.map(
              (r) => Container(
                margin:
                    const EdgeInsets.only(bottom: AppTheme.spacingSm),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard_rounded,
                        color: AppTheme.gold, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            r.description,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int current;
  final int target;
  final String label;
  final bool isComplete;

  const _ProgressCard({
    required this.current,
    required this.target,
    required this.label,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isComplete
              ? AppTheme.success.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ($current/$target)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            child: LinearProgressIndicator(
              value: target > 0 ? (current / target).clamp(0.0, 1.0) : 0,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? AppTheme.success : AppTheme.primary,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isComplete;

  const _RewardTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isComplete
              ? AppTheme.success.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isComplete
                        ? AppTheme.success
                        : AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
          if (isComplete)
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.success, size: 20),
        ],
      ),
    );
  }
}

