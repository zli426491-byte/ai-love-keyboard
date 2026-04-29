import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/models/coin_system.dart';
import 'package:ai_love_keyboard/services/coin_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';

class CoinStoreView extends StatelessWidget {
  const CoinStoreView({super.key});

  @override
  Widget build(BuildContext context) {
    final coinService = context.watch<CoinService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('金幣商店'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // Balance card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '\u{1FA99}',
                  style: TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 8),
                Text(
                  '${coinService.balance}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  '金幣餘額',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: const Duration(milliseconds: 400)),

          const SizedBox(height: AppTheme.spacingLg),

          // Coin packages
          Text(
            '購買金幣',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),

          ...CoinPackage.allPackages.map(
            (pkg) => _CoinPackageCard(
              package: pkg,
              onPurchase: () async {
                // TODO: Integrate with real IAP
                await coinService.addCoins(
                  pkg.totalCoins,
                  feature: '購買 ${pkg.coins} 金幣包',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '購買成功！獲得 ${pkg.totalCoins} 金幣'),
                    ),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // Coin costs reference
          Text(
            '金幣用途',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),

          _CoinCostTile(
            emoji: '\u{1F6A8}',
            label: '緊急求助 AI 教練',
            cost: CoinCost.emergencyCoach,
          ),
          _CoinCostTile(
            emoji: '\u{1F54A}\uFE0F',
            label: '吵架急救包（單次）',
            cost: CoinCost.argumentPackage,
          ),
          _CoinCostTile(
            emoji: '\u{1F494}',
            label: '挽回分析（單次）',
            cost: CoinCost.breakupAnalysis,
          ),
          _CoinCostTile(
            emoji: '\u{1F498}',
            label: '表白方案（單次）',
            cost: CoinCost.confessionPlan,
          ),
          _CoinCostTile(
            emoji: '\u{1F198}',
            label: '已讀不回急救',
            cost: CoinCost.leftOnRead,
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // Free coins
          Text(
            '免費獲得金幣',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),

          _FreeCoinTile(
            icon: Icons.login_rounded,
            label: '每日登入',
            coins: CoinCost.dailyLogin,
          ),
          _FreeCoinTile(
            icon: Icons.play_circle_rounded,
            label: '觀看廣告（即將推出）',
            coins: CoinCost.watchAd,
          ),
          _FreeCoinTile(
            icon: Icons.person_add_rounded,
            label: '邀請好友',
            coins: CoinCost.inviteFriend,
          ),
          const _FreeCoinTile(
            icon: Icons.emoji_events_rounded,
            label: '完成成就',
            coins: 0,
            subtitle: '依成就而定',
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // Transaction history link
          if (coinService.history.isNotEmpty) ...[
            Text(
              '最近交易',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ...coinService.history.reversed.take(10).map(
                  (tx) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          tx.isCredit
                              ? Icons.add_circle_rounded
                              : Icons.remove_circle_rounded,
                          color: tx.isCredit
                              ? AppTheme.success
                              : AppTheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tx.feature,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${tx.isCredit ? "+" : "-"}${tx.amount}',
                          style: TextStyle(
                            color: tx.isCredit
                                ? AppTheme.success
                                : AppTheme.error,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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

class _CoinPackageCard extends StatelessWidget {
  final CoinPackage package;
  final VoidCallback onPurchase;

  const _CoinPackageCard({
    required this.package,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: package.isPopular
              ? AppTheme.accent.withValues(alpha: 0.4)
              : package.isBestValue
                  ? AppTheme.gold.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Coin icon + amount
          Column(
            children: [
              const Text('\u{1FA99}', style: TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(
                '${package.coins}',
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${package.coins} 金幣',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (package.isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: const Text(
                          '最熱門',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    if (package.isBestValue) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.gold,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: const Text(
                          '最超值',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (package.bonusCoins > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '+${package.bonusCoins} 額外贈送',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Price button
          GestureDetector(
            onTap: onPurchase,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: package.isPopular
                    ? AppTheme.accentGradient
                    : package.isBestValue
                        ? const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                          )
                        : AppTheme.primaryGradient,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                '\$${package.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinCostTile extends StatelessWidget {
  final String emoji;
  final String label;
  final int cost;

  const _CoinCostTile({
    required this.emoji,
    required this.label,
    required this.cost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '$cost \u{1FA99}',
            style: const TextStyle(
              color: AppTheme.gold,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeCoinTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int coins;
  final String? subtitle;

  const _FreeCoinTile({
    required this.icon,
    required this.label,
    required this.coins,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            subtitle ?? '+$coins \u{1FA99}',
            style: const TextStyle(
              color: AppTheme.success,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
