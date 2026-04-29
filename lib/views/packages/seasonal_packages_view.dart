import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/models/seasonal_package.dart';
import 'package:ai_love_keyboard/services/seasonal_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';

class SeasonalPackagesView extends StatefulWidget {
  const SeasonalPackagesView({super.key});

  @override
  State<SeasonalPackagesView> createState() => _SeasonalPackagesViewState();
}

class _SeasonalPackagesViewState extends State<SeasonalPackagesView> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Update countdown every minute
    _countdownTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seasonal = context.watch<SeasonalService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('節日限定禮包'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // Active packages section
          if (SeasonalPackage.activePackages.isNotEmpty) ...[
            _SectionHeader(
              title: '限時優惠中',
              icon: Icons.local_fire_department_rounded,
              color: AppTheme.error,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ...SeasonalPackage.activePackages.map(
              (pkg) => _SeasonalCard(
                package: pkg,
                isPurchased: seasonal.isPurchased(pkg.id),
                onPurchase: () => _handlePurchase(context, pkg),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          // Upcoming packages
          if (SeasonalPackage.upcomingPackages.isNotEmpty) ...[
            _SectionHeader(
              title: '即將推出',
              icon: Icons.schedule_rounded,
              color: AppTheme.warning,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ...SeasonalPackage.upcomingPackages.map(
              (pkg) => _SeasonalCard(
                package: pkg,
                isDisabled: true,
                statusLabel: '即將推出',
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          // Past packages
          if (SeasonalPackage.pastPackages.isNotEmpty) ...[
            _SectionHeader(
              title: '已結束',
              icon: Icons.history_rounded,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ...SeasonalPackage.pastPackages.map(
              (pkg) => _SeasonalCard(
                package: pkg,
                isDisabled: true,
                statusLabel: '已結束',
              ),
            ),
          ],

          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  Future<void> _handlePurchase(
      BuildContext ctx, SeasonalPackage pkg) async {
    final seasonal = ctx.read<SeasonalService>();
    // TODO: Integrate with real IAP
    await seasonal.purchasePackage(pkg.id);
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('已購買 ${pkg.emoji} ${pkg.name}！')),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _SeasonalCard extends StatelessWidget {
  final SeasonalPackage package;
  final bool isPurchased;
  final bool isDisabled;
  final String? statusLabel;
  final VoidCallback? onPurchase;

  const _SeasonalCard({
    required this.package,
    this.isPurchased = false,
    this.isDisabled = false,
    this.statusLabel,
    this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = isDisabled ? 0.5 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
        decoration: BoxDecoration(
          gradient: isDisabled ? null : package.gradient,
          color: isDisabled ? AppTheme.bgCard : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: isDisabled
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.08))
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Text(
                    package.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          package.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (statusLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        statusLabel!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Features
              ...package.features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        f,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Bottom row: countdown + price/button
              Row(
                children: [
                  if (package.isActive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_rounded,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '剩餘 ${package.daysRemaining} 天',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (!isDisabled)
                    isPurchased
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusFull),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  '已購買',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: onPurchase,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusFull),
                              ),
                              child: Text(
                                '\$${package.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: package.primaryColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400));
  }
}
