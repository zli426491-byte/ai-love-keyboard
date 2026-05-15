import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/services/analytics_service.dart';
import 'package:ai_love_keyboard/services/revenuecat_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';

class PaywallView extends StatefulWidget {
  const PaywallView({super.key});

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> {
  static const _ink = Color(0xFF19131F);
  static const _muted = Color(0xFF7A6F82);
  static const _primary = Color(0xFF7C3AED);
  static const _pink = Color(0xFFEC4899);
  static const _line = Color(0xFFEAD7E9);
  static const _soft = Color(0xFFFFF2FA);

  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackPaywallShown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RevenueCatService>().loadOfferings();
    });
  }

  Future<void> _purchase(SubscriptionPlan plan) async {
    final revenueCat = context.read<RevenueCatService>();
    final usage = context.read<UsageService>();

    try {
      final purchased = await revenueCat.purchase(plan);
      if (!mounted) return;
      if (purchased) {
        await usage.setSubscribed(true);
        if (mounted) Navigator.pop(context);
      } else if (revenueCat.errorMessage != null) {
        _showSnack(revenueCat.errorMessage!);
      }
    } catch (_) {
      _showSnack('RevenueCat 產品尚未設定完成');
    }
  }

  Future<void> _restore() async {
    final revenueCat = context.read<RevenueCatService>();
    final restored = await revenueCat.restore();
    if (!mounted) return;
    if (restored) {
      await context.read<UsageService>().setSubscribed(true);
      if (mounted) Navigator.pop(context);
    } else if (revenueCat.errorMessage != null) {
      _showSnack(revenueCat.errorMessage!);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final revenueCat = context.watch<RevenueCatService>();
    final plans = revenueCat.plans;
    final selected = plans[_selectedIndex];
    final canPurchase = selected.isAvailable && !revenueCat.isLoading;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'LoveKey Pro',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: _muted),
                    onPressed: () {
                      AnalyticsService.instance.trackPaywallClosed();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '解鎖鍵盤 AI 回覆、所有情境模式與不限次生成。所有購買都透過 App Store 完成。',
                style: TextStyle(
                  color: _muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              const _FeatureRow(text: '鍵盤內直接生成一則可貼上的回覆'),
              const _FeatureRow(text: '接話、破冰、邀約、安撫、自訂模式'),
              const _FeatureRow(text: '依語氣調整：溫柔、幽默、曖昧、深情'),
              const SizedBox(height: 14),
              ...List.generate(plans.length, (index) {
                final plan = plans[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PlanCard(
                    plan: plan,
                    selected: index == _selectedIndex,
                    onTap: () => setState(() => _selectedIndex = index),
                  ),
                );
              }),
              if (revenueCat.errorMessage != null) ...[
                const SizedBox(height: 2),
                Text(
                  revenueCat.errorMessage!,
                  style: const TextStyle(
                    color: _pink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              GestureDetector(
                onTap: canPurchase ? () => _purchase(selected) : null,
                child: AnimatedOpacity(
                  opacity: canPurchase ? 1 : 0.45,
                  duration: const Duration(milliseconds: 160),
                  child: Container(
                    height: 58,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_primary, _pink]),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x36EC4899),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: revenueCat.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            canPurchase
                                ? '立即解鎖 ${selected.price}'
                                : 'RevenueCat 尚未載入產品',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: revenueCat.isLoading ? null : _restore,
                  child: const Text(
                    '恢復購買',
                    style: TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  '可隨時在 Apple ID 設定中管理或取消訂閱',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? _PaywallViewState._soft : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _PaywallViewState._pink : _PaywallViewState._line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? _PaywallViewState._pink
                  : _PaywallViewState._muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.title,
                        style: const TextStyle(
                          color: _PaywallViewState._ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (plan.badge.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _PaywallViewState._pink,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            plan.badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.subtitle,
                    style: const TextStyle(
                      color: _PaywallViewState._muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              plan.price,
              style: const TextStyle(
                color: _PaywallViewState._ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;

  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 23,
            height: 23,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _PaywallViewState._primary,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _PaywallViewState._ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
