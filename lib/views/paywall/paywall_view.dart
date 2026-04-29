import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/services/analytics_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';

class PaywallView extends StatefulWidget {
  const PaywallView({super.key});

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> {
  int _selectedPlan = 0;

  static const _planNames = ['weekly', 'monthly', 'lifetime'];

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackPaywallShown();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        gradient: LinearGradient(
          colors: [Color(0xFF0D0515), Color(0xFF1A0F2E), Color(0xFF0D0515)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingLg,
              AppTheme.spacingSm,
              AppTheme.spacingLg,
              AppTheme.spacingLg,
            ),
            child: Column(
              children: [
                // ── Handle ──────────────────────────────────────
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),

                // ── Close Button ────────────────────────────────
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white54),
                    onPressed: () {
                      AnalyticsService.instance.trackPaywallClosed();
                      Navigator.pop(context);
                    },
                  ),
                ),

                // ── Shimmer Badge ───────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700)
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('\u{2728}',
                          style: TextStyle(fontSize: 14)),
                      SizedBox(width: 4),
                      Text(
                        '限時優惠',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn()
                    .shimmer(
                      delay: const Duration(milliseconds: 800),
                      duration: const Duration(milliseconds: 1500),
                    ),

                const SizedBox(height: AppTheme.spacingMd),

                // ── Title ───────────────────────────────────────
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppTheme.primaryLight, AppTheme.accent],
                  ).createShader(bounds),
                  child: const Text(
                    '解鎖所有功能',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // ── Feature List ────────────────────────────────
                ..._features.asMap().entries.map((e) => _FeatureRow(
                      text: e.value,
                    )
                        .animate(
                            delay: Duration(milliseconds: e.key * 60))
                        .fadeIn()
                        .slideX(begin: 0.15)),

                const SizedBox(height: AppTheme.spacingLg),

                // ── Plan Cards ──────────────────────────────────
                // Weekly
                _PlanCard(
                  title: '週方案',
                  price: AppConstants.weeklyPriceDisplay,
                  subtitle: '每週自動續訂',
                  badge: '免費試用7天',
                  badgeColor: AppTheme.success,
                  isSelected: _selectedPlan == 0,
                  onTap: () {
                    setState(() => _selectedPlan = 0);
                    AnalyticsService.instance
                        .trackPlanSelected(planType: 'weekly');
                  },
                ).animate().fadeIn(
                    delay: const Duration(milliseconds: 250)),

                const SizedBox(height: AppTheme.spacingSm),

                // Monthly
                _PlanCard(
                  title: '月方案',
                  price: AppConstants.monthlyPriceDisplay,
                  subtitle: '每月自動續訂',
                  isSelected: _selectedPlan == 1,
                  onTap: () {
                    setState(() => _selectedPlan = 1);
                    AnalyticsService.instance
                        .trackPlanSelected(planType: 'monthly');
                  },
                ).animate().fadeIn(
                    delay: const Duration(milliseconds: 320)),

                const SizedBox(height: AppTheme.spacingSm),

                // Lifetime
                _PlanCard(
                  title: '終身方案',
                  price: AppConstants.lifetimePriceDisplay,
                  subtitle: '一次付費，永久使用',
                  badge: '最超值',
                  badgeColor: AppTheme.accent,
                  trailingEmoji: '\u{2764}\u{FE0F}',
                  isSelected: _selectedPlan == 2,
                  onTap: () {
                    setState(() => _selectedPlan = 2);
                    AnalyticsService.instance
                        .trackPlanSelected(planType: 'lifetime');
                  },
                ).animate().fadeIn(
                    delay: const Duration(milliseconds: 390)),

                const SizedBox(height: AppTheme.spacingLg),

                // ── CTA Button ──────────────────────────────────
                GestureDetector(
                  onTap: () => _subscribe(context),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFFAB47BC)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC4899)
                              .withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedPlan == 0
                                ? '免費試用 7 天'
                                : _selectedPlan == 1
                                    ? '立即訂閱'
                                    : '立即買斷',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (_selectedPlan == 0)
                            Text(
                              '試用結束後 ${AppConstants.weeklyPriceDisplay}',
                              style: TextStyle(
                                color:
                                    Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 450))
                    .shimmer(
                      delay: const Duration(milliseconds: 1500),
                      duration: const Duration(milliseconds: 1500),
                    ),

                const SizedBox(height: AppTheme.spacingMd),

                // ── Restore Purchases ───────────────────────────
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('正在恢復購買...')),
                    );
                  },
                  child: const Text(
                    '恢復購買',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),

                // ── Legal ───────────────────────────────────────
                const Text(
                  '訂閱會自動續約，可隨時在設定中取消',
                  style: TextStyle(color: Colors.white30, fontSize: 11),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppTheme.spacingMd),
              ],
            ),
          );
        },
      ),
    );
  }

  void _subscribe(BuildContext context) {
    final planType = _planNames[_selectedPlan];

    if (_selectedPlan == 0) {
      AnalyticsService.instance.trackFreeTrialStarted();
    }
    AnalyticsService.instance
        .trackSubscriptionStarted(planType: planType);

    context.read<UsageService>().setSubscribed(true);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已升級為 PRO（開發模式）'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  static const _features = [
    '無限AI回覆',
    '10種回覆風格',
    '聊天態度分析',
    '破冰開場白',
    '話題建議',
    '跨國翻譯',
    '優先速度',
  ];
}

// ── Feature Row ──────────────────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final String text;

  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 14, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plan Card (glassmorphism) ────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final String? trailingEmoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    this.trailingEmoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: isSelected
                    ? AppTheme.accent.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.15),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Radio
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accent
                          : Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.accent,
                                  AppTheme.primary
                                ],
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (badgeColor ?? AppTheme.primary)
                                    .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusFull),
                              ),
                              child: Text(
                                badge!,
                                style: TextStyle(
                                  color: badgeColor ??
                                      AppTheme.primaryLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white38),
                      ),
                    ],
                  ),
                ),
                if (trailingEmoji != null)
                  Text(trailingEmoji!,
                      style: const TextStyle(fontSize: 18)),
                if (trailingEmoji != null) const SizedBox(width: 8),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppTheme.accent : Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
