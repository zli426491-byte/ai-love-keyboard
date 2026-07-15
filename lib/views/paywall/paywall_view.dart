import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/services/analytics_service.dart';
import 'package:ai_love_keyboard/services/account_service.dart';
import 'package:ai_love_keyboard/services/revenuecat_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/views/auth/account_view.dart';

class PaywallView extends StatefulWidget {
  const PaywallView({super.key});

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> {
  static const _ink = Color(0xFFFFF7FB);
  static const _muted = Color(0xFFC9B8CA);
  static const _line = Color(0x33FFFFFF);
  static const _pink = Color(0xFFFF4F8B);
  static const _violet = Color(0xFFC147E9);
  static const _gold = Color(0xFFFFD37A);

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
      AnalyticsService.instance.trackPlanSelected(planType: plan.id);
      AnalyticsService.instance.trackPurchaseStarted(planType: plan.id);
      final purchased = await revenueCat.purchase(plan);
      if (purchased) {
        // Persist entitlement before checking whether the paywall is still
        // mounted. A purchase may finish after the sheet was dismissed.
        await usage.setSubscribed(true);
        if (!mounted) return;
        AnalyticsService.instance.trackSubscriptionStarted(planType: plan.id);
        if (plan.amount > 0) {
          AnalyticsService.instance.trackRevenue(
            amount: plan.amount,
            currency: plan.currency,
            planType: plan.id,
          );
        }
        if (mounted) Navigator.pop(context);
      } else if (revenueCat.errorMessage != null) {
        if (mounted) _showSnack(revenueCat.errorMessage!);
      }
    } catch (_) {
      if (mounted) {
        _showSnack('訂閱付款暫時無法使用，請確認 RevenueCat 產品設定');
      }
    }
  }

  Future<void> _restore() async {
    final revenueCat = context.read<RevenueCatService>();
    final usage = context.read<UsageService>();
    final restored = await revenueCat.restore();
    if (restored) {
      // Restore can also finish after the paywall was dismissed. Persist the
      // entitlement independently of the sheet lifecycle.
      await usage.setSubscribed(true);
      if (!mounted) return;
      if (mounted) Navigator.pop(context);
    } else if (revenueCat.errorMessage != null) {
      if (mounted) _showSnack(revenueCat.errorMessage!);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF19131F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final revenueCat = context.watch<RevenueCatService>();
    final account = context.watch<AccountService>();
    final plans = revenueCat.plans;
    final selected = plans[_selectedIndex];
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final isNativeStore = isIos || isAndroid;
    final canPurchase =
        isNativeStore &&
        account.isSignedIn &&
        selected.isAvailable &&
        !revenueCat.isLoading;
    final canRestore =
        isNativeStore && account.isSignedIn && !revenueCat.isLoading;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF211620), Color(0xFF170F18), Color(0xFF2B1430)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.94,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                Text(
                  '解鎖鍵盤 AI 回覆、所有情境模式與不限次生成。付款透過 ${isAndroid ? 'Google Play' : 'App Store'} 完成，價格會依所在地自動顯示。',
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
                if (isNativeStore && revenueCat.errorMessage != null) ...[
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
                  onTap: () {
                    if (!isNativeStore) return;
                    if (!account.isSignedIn) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AccountView()),
                      );
                      return;
                    }
                    if (canPurchase) _purchase(selected);
                  },
                  child: AnimatedOpacity(
                    opacity: canPurchase ? 1 : 0.48,
                    duration: const Duration(milliseconds: 160),
                    child: Container(
                      height: 58,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_pink, _violet],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55EC4899),
                            blurRadius: 24,
                            offset: Offset(0, 12),
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
                                  : isNativeStore && !account.isSignedIn
                                  ? '請先登入 LoveKey 帳號'
                                  : isNativeStore
                                  ? '訂閱方案載入中'
                                  : '請在 iOS／Android 實機完成購買',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ),
                if (!isNativeStore) ...[
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      '這是 Web 預覽，付款與恢復購買請在 TestFlight 實機完成。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: canRestore
                        ? _restore
                        : isNativeStore
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AccountView(),
                            ),
                          )
                        : null,
                    child: Text(
                      isNativeStore ? '恢復購買' : '請在實機恢復購買',
                      style: const TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '訂閱會透過 ${isAndroid ? 'Google Play' : 'Apple ID'} 扣款，可在商店設定中管理或取消',
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? const [Color(0xFF3A253C), Color(0xFF241426)]
                : const [Color(0xFF2B1D2B), Color(0xFF211620)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _PaywallViewState._ink : _PaywallViewState._line,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: _PaywallViewState._pink.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
          ],
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
                      Flexible(
                        child: Text(
                          plan.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _PaywallViewState._ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
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
                            gradient: const LinearGradient(
                              colors: [
                                _PaywallViewState._pink,
                                _PaywallViewState._violet,
                              ],
                            ),
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
            const SizedBox(width: 12),
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
              gradient: LinearGradient(
                colors: [_PaywallViewState._pink, _PaywallViewState._violet],
              ),
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
