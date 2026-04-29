import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/models/coin_system.dart';
import 'package:ai_love_keyboard/models/situation_package.dart';
import 'package:ai_love_keyboard/services/coin_service.dart';
import 'package:ai_love_keyboard/services/package_manager.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';

int _getCoinCost(SituationType type) {
  switch (type) {
    case SituationType.argument:
      return CoinCost.argumentPackage;
    case SituationType.breakup:
      return CoinCost.breakupAnalysis;
    case SituationType.confession:
      return CoinCost.confessionPlan;
    case SituationType.leftOnRead:
      return CoinCost.leftOnRead;
    case SituationType.escalation:
      return CoinCost.confessionPlan;
  }
}

class SituationPackageDialog extends StatelessWidget {
  final SituationPackage package;

  const SituationPackageDialog({super.key, required this.package});

  static Future<void> show(BuildContext context, SituationPackage package) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SituationPackageDialog(package: package),
    );
  }

  @override
  Widget build(BuildContext context) {
    final packageManager = context.read<PackageManager>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0F2E), Color(0xFF0D0515)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0x40AB47BC), width: 1),
          left: BorderSide(color: Color(0x40AB47BC), width: 1),
          right: BorderSide(color: Color(0x40AB47BC), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Emoji
              Text(
                package.emoji,
                style: const TextStyle(fontSize: 56),
              ).animate().scale(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 12),

              // Package name
              Text(
                package.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                package.description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Features list
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '包含內容',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...package.features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.accent,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                f,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Urgency text
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '90% 的人在這個情境下購買了此禮包',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Buy with money button
              GestureDetector(
                onTap: () async {
                  // TODO: Integrate with actual IAP
                  await packageManager.purchasePackage(package.type);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${package.emoji} ${package.name} 購買成功！'),
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '立即購買 \$${package.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Buy with coins button
              Builder(
                builder: (ctx) {
                  final coinService = ctx.read<CoinService>();
                  final coinCost = _getCoinCost(package.type);
                  final hasCoins = coinService.hasEnoughCoins(coinCost);
                  return GestureDetector(
                    onTap: () async {
                      if (hasCoins) {
                        final spent = await coinService.spendCoins(
                            coinCost, package.name);
                        if (spent && ctx.mounted) {
                          await packageManager.purchasePackage(package.type);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${package.emoji} ${package.name} 購買成功！'),
                              ),
                            );
                          }
                        }
                      } else if (ctx.mounted) {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(ctx, '/coin-store');
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          hasCoins
                              ? '使用 $coinCost \u{1FA99} 購買'
                              : '$coinCost \u{1FA99}（餘額不足，前往商店）',
                          style: TextStyle(
                            color:
                                hasCoins ? AppTheme.gold : AppTheme.textHint,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Dismiss button
              TextButton(
                onPressed: () {
                  packageManager.dismissForSession(package.type);
                  Navigator.pop(context);
                },
                child: const Text(
                  '先不要',
                  style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(
          begin: 0.3,
          end: 0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
  }
}
