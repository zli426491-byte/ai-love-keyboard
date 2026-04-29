import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';

class UsageIndicator extends StatelessWidget {
  const UsageIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UsageService>(
      builder: (context, usage, _) {
        if (usage.isSubscribed) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        final remaining = usage.remainingFree;
        final total = AppConstants.freeDailyLimit;
        final ratio = remaining / total;

        Color barColor;
        if (ratio > 0.5) {
          barColor = AppTheme.success;
        } else if (ratio > 0) {
          barColor = AppTheme.warning;
        } else {
          barColor = AppTheme.error;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '今日剩餘 $remaining/$total 次',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: barColor,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
