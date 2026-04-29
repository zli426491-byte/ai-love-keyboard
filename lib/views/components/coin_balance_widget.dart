import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/services/coin_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';

/// Small widget showing the current coin balance. Tappable to open coin store.
class CoinBalanceWidget extends StatelessWidget {
  const CoinBalanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final coinService = context.watch<CoinService>();

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/coin-store'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: AppTheme.gold.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\u{1FA99}', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '${coinService.balance}',
              style: const TextStyle(
                color: AppTheme.gold,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
