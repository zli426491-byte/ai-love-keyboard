import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' show Share;

import 'package:ai_love_keyboard/services/referral_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';

class ShareSuccessView extends StatelessWidget {
  final String featureUsed;

  const ShareSuccessView({
    super.key,
    required this.featureUsed,
  });

  String get _shareText {
    switch (featureUsed) {
      case 'reply':
        return 'AI 幫我想出超棒的回覆！這個戀愛鍵盤 App 太神了';
      case 'date':
        return 'AI 幫我規劃了完美的約會！對方秒答應';
      case 'opener':
        return 'AI 破冰開場白超有效！馬上就聊起來了';
      case 'analysis':
        return 'AI 分析聊天紀錄好準！終於看懂對方在想什麼';
      default:
        return 'AI 戀愛鍵盤太好用了！強烈推薦';
    }
  }

  @override
  Widget build(BuildContext context) {
    final referral = context.read<ReferralService>();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

          // Celebration
          const Text(
            '\u{1F389}',
            style: TextStyle(fontSize: 48),
          )
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 12),

          const Text(
            '分享你的成功故事',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '讓朋友也知道這個神器！',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // Shareable card preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              gradient: AppTheme.romanticGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              children: [
                const Text(
                  'AI \u{1F49C} \u{2328}\uFE0F',
                  style: TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  _shareText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '邀請碼：${referral.referralCode}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Share buttons row
          Row(
            children: [
              Expanded(
                child: _ShareBtn(
                  icon: Icons.camera_alt_rounded,
                  label: 'IG 限動',
                  color: const Color(0xFFE1306C),
                  onTap: () {
                    Share.share(
                      '$_shareText\n\n立即下載：${referral.shareLink}',
                    );
                    referral.recordIgShare();
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShareBtn(
                  icon: Icons.chat_bubble_rounded,
                  label: 'LINE',
                  color: const Color(0xFF00B900),
                  onTap: () {
                    Share.share(
                      '$_shareText\n\n${referral.shareLink}',
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShareBtn(
                  icon: Icons.share_rounded,
                  label: '更多',
                  color: AppTheme.primary,
                  onTap: () {
                    Share.share(
                      '$_shareText\n\n${referral.shareLink}',
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Skip
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '之後再說',
              style: TextStyle(color: AppTheme.textHint),
            ),
          ),

          const SizedBox(height: AppTheme.spacingSm),
        ],
      ),
    );
  }
}

class _ShareBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
