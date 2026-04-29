import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';

class PaywallView extends StatefulWidget {
  const PaywallView({super.key});

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> {
  int _selectedPlan = 0; // 0=weekly, 1=monthly, 2=lifetime

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        gradient: LinearGradient(
          colors: [Color(0xFF1E1533), Color(0xFF2D1B4E)],
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
                // ── Handle ────────────────────────────────────────
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),

                // ── Close Button ──────────────────────────────────
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // ── Header Icon ──────────────────────────────────
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      size: 36, color: Colors.white),
                )
                    .animate()
                    .fadeIn()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: AppTheme.spacingMd),

                // ── Title ────────────────────────────────────────
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppTheme.primaryLight, AppTheme.accent],
                  ).createShader(bounds),
                  child: const Text(
                    '升級 PRO',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '解鎖所有 AI 戀愛超能力',
                  style: TextStyle(fontSize: 16, color: Colors.white60),
                ),
                const SizedBox(height: 6),

                // ── Urgency Badge ────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color:
                          const Color(0xFFEF4444).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          color: Color(0xFFEF4444), size: 16),
                      SizedBox(width: 4),
                      Text(
                        '限時優惠',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 200))
                    .shimmer(
                      delay: const Duration(milliseconds: 1000),
                      duration: const Duration(milliseconds: 1500),
                    ),

                const SizedBox(height: AppTheme.spacingLg),

                // ── Feature List ──────────────────────────────────
                ..._features.asMap().entries.map((e) => _FeatureRow(
                      icon: e.value.$1,
                      text: e.value.$2,
                    )
                        .animate(
                            delay: Duration(milliseconds: e.key * 60))
                        .fadeIn()
                        .slideX(begin: 0.15)),

                const SizedBox(height: AppTheme.spacingLg),

                // ── Plan Options ──────────────────────────────────
                _PlanOption(
                  title: '每週方案',
                  price: AppConstants.weeklyPriceDisplay,
                  subtitle: '免費試用 ${AppConstants.freeTrialDays} 天',
                  badge: '免費試用',
                  isSelected: _selectedPlan == 0,
                  onTap: () => setState(() => _selectedPlan = 0),
                ).animate().fadeIn(
                    delay: const Duration(milliseconds: 250)),

                const SizedBox(height: AppTheme.spacingSm),

                _PlanOption(
                  title: '每月方案',
                  price: AppConstants.monthlyPriceDisplay,
                  subtitle: '\$${AppConstants.monthlyPriceUsd}/month',
                  isSelected: _selectedPlan == 1,
                  onTap: () => setState(() => _selectedPlan = 1),
                ).animate().fadeIn(
                    delay: const Duration(milliseconds: 320)),

                const SizedBox(height: AppTheme.spacingSm),

                _PlanOption(
                  title: '買斷方案',
                  price: AppConstants.lifetimePriceDisplay,
                  subtitle: '一次付費，永久使用',
                  badge: '最超值',
                  badgeColor: AppTheme.accent,
                  isSelected: _selectedPlan == 2,
                  onTap: () => setState(() => _selectedPlan = 2),
                ).animate().fadeIn(
                    delay: const Duration(milliseconds: 390)),

                const SizedBox(height: AppTheme.spacingLg),

                // ── Primary CTA ──────────────────────────────────
                GestureDetector(
                  onTap: () => _subscribe(context),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppTheme.primary.withValues(alpha: 0.4),
                          blurRadius: 16,
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
                              style: const TextStyle(
                                color: Colors.white70,
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

                // ── Restore Purchases ─────────────────────────────
                TextButton(
                  onPressed: () {
                    // TODO: Implement restore
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

                // ── Legal Text ────────────────────────────────────
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
    // Temporary mock for development
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
    (Icons.all_inclusive_rounded, '無限AI回覆'),
    (Icons.style_rounded, '四種回覆風格'),
    (Icons.thermostat_rounded, '聊天態度分析'),
    (Icons.chat_bubble_outline_rounded, '破冰開場白'),
    (Icons.lightbulb_outline, '話題建議'),
    (Icons.speed_rounded, '優先速度'),
  ];
}

// ── Feature Row ────────────────────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
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
          const Spacer(),
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.accent, size: 20),
        ],
      ),
    );
  }
}

// ── Plan Option ────────────────────────────────────────────────────────
class _PlanOption extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanOption({
    required this.title,
    required this.price,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppTheme.accent
        : Colors.white.withValues(alpha: 0.15);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.accent : Colors.white30,
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
                          color: AppTheme.accent,
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
                              color: badgeColor ?? AppTheme.primaryLight,
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
    );
  }
}
