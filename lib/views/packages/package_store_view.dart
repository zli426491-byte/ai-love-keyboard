import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/models/situation_package.dart';
import 'package:ai_love_keyboard/services/package_manager.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/views/components/situation_package_dialog.dart';

class PackageStoreView extends StatelessWidget {
  const PackageStoreView({super.key});

  static const List<List<Color>> _gradientColors = [
    [Color(0xFF10B981), Color(0xFF059669)], // argument - green
    [Color(0xFFEC4899), Color(0xFFBE185D)], // breakup - pink
    [Color(0xFFF472B6), Color(0xFFE11D48)], // confession - rose
    [Color(0xFFF97316), Color(0xFFEA580C)], // escalation - orange
    [Color(0xFF6366F1), Color(0xFF4F46E5)], // leftOnRead - indigo
  ];

  @override
  Widget build(BuildContext context) {
    final packageManager = context.watch<PackageManager>();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd, AppTheme.spacingMd,
                  AppTheme.spacingMd, 0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '\u{1F381} 情境禮包商店',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),

            // Subtitle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd, AppTheme.spacingSm,
                  AppTheme.spacingMd, AppTheme.spacingMd,
                ),
                child: Text(
                  '針對不同戀愛情境，提供專業 AI 分析與話術',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // Package cards
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final pkg = SituationPackage.allPackages[index];
                  final owned = packageManager.hasPackage(pkg.type);
                  final remaining = packageManager.remainingUses(pkg.type);
                  final colors = _gradientColors[index];

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingMd, 0,
                      AppTheme.spacingMd, AppTheme.spacingMd,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        if (!owned) {
                          SituationPackageDialog.show(context, pkg);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors[0].withValues(alpha: 0.15),
                              colors[1].withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(
                            color: owned
                                ? AppTheme.success.withValues(alpha: 0.4)
                                : colors[0].withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Emoji + badge
                            Stack(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: colors[0].withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      pkg.emoji,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                ),
                                if (owned)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.success,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                              ],
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
                                        pkg.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (owned)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.success
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '剩餘 $remaining 次',
                                            style: const TextStyle(
                                              color: AppTheme.success,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        )
                                      else
                                        Text(
                                          '\$${pkg.price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: colors[0],
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pkg.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: pkg.features.map((f) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              colors[0].withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          f,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: colors[0],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: 100 * index),
                        duration: const Duration(milliseconds: 400),
                      );
                },
                childCount: SituationPackage.allPackages.length,
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingXl),
            ),
          ],
        ),
      ),
    );
  }
}
