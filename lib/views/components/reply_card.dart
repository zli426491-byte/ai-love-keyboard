import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:ai_love_keyboard/models/ai_reply.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';

class ReplyCard extends StatelessWidget {
  final AiReply reply;
  final int index;

  const ReplyCard({
    super.key,
    required this.reply,
    this.index = 0,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: reply.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已複製到剪貼簿 📋'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        gradient: LinearGradient(
          colors: [
            reply.style.color.withValues(alpha: 0.3),
            AppTheme.accent.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg - 1),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: reply.style.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    reply.style.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: reply.style.color,
                    ),
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    onTap: () => _copyToClipboard(context),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '複製',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              reply.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 150)).fadeIn().slideY(
          begin: 0.15,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
  }
}
