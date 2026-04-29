import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/config/ad_tracking_config.dart';
import 'package:ai_love_keyboard/models/chat_persona.dart';
import 'package:ai_love_keyboard/models/reply_style.dart';
import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/analytics_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/analysis/chat_analysis_view.dart';
import 'package:ai_love_keyboard/views/characters/character_market_view.dart';
import 'package:ai_love_keyboard/views/components/intimacy_selector.dart';
import 'package:ai_love_keyboard/views/components/usage_indicator.dart';
import 'package:ai_love_keyboard/views/components/particle_background.dart';
import 'package:ai_love_keyboard/views/opener/opener_view.dart';
import 'package:ai_love_keyboard/views/paywall/paywall_view.dart';
import 'package:ai_love_keyboard/views/reply/reply_cards_view.dart';
import 'package:ai_love_keyboard/views/argument/argument_resolve_view.dart';
import 'package:ai_love_keyboard/views/coach/timing_coach_view.dart';
import 'package:ai_love_keyboard/views/components/emoji_suggester.dart';
import 'package:ai_love_keyboard/views/components/reply_scorer.dart';
import 'package:ai_love_keyboard/views/culture/culture_tips_view.dart';
import 'package:ai_love_keyboard/views/date/date_invitation_view.dart';
import 'package:ai_love_keyboard/views/greetings/greetings_view.dart';
import 'package:ai_love_keyboard/views/settings/settings_view.dart';
import 'package:ai_love_keyboard/views/topics/topic_suggestions_view.dart';
import 'package:ai_love_keyboard/views/translate/translate_reply_view.dart';
import 'package:ai_love_keyboard/models/situation_package.dart';
import 'package:ai_love_keyboard/services/achievement_service.dart';
import 'package:ai_love_keyboard/services/seasonal_service.dart';
import 'package:ai_love_keyboard/services/situation_detector.dart';
import 'package:ai_love_keyboard/services/package_manager.dart';
import 'package:ai_love_keyboard/views/achievements/achievements_view.dart';
import 'package:ai_love_keyboard/views/components/situation_package_dialog.dart';
import 'package:ai_love_keyboard/views/components/coin_balance_widget.dart';
import 'package:ai_love_keyboard/views/emergency/emergency_coach_view.dart';
import 'package:ai_love_keyboard/views/packages/seasonal_packages_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _messageController = TextEditingController();
  ReplyStyle _selectedStyle = ReplyStyle.humorous;
  String _selectedPlatform = '交友App';
  static const _platforms = ['交友App', 'LINE', 'IG'];
  bool _keyboardBannerDismissed = false;
  ChatPersona? _selectedPersona;
  int _intimacyLevel = 3;
  bool _showAllStyles = false;
  final FocusNode _inputFocusNode = FocusNode();
  bool _inputFocused = false;

  // Main 4 styles + 6 more
  static const _mainStyleCount = 4;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageChanged);
    _inputFocusNode.addListener(() {
      setState(() => _inputFocused = _inputFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  int _lastCheckedLength = 0;

  void _onMessageChanged() {
    final text = _messageController.text.trim();
    if (text.length < 4 || (text.length - _lastCheckedLength).abs() < 4) {
      return;
    }
    _lastCheckedLength = text.length;

    final detected = SituationDetector.instance.detect(text);
    if (detected == null) return;

    final packageManager = context.read<PackageManager>();
    if (!packageManager.shouldShowDialog(detected)) return;

    final pkg = SituationPackage.getPackage(detected);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _messageController.text.trim() == text) {
        SituationPackageDialog.show(context, pkg);
      }
    });
  }

  Future<void> _generateReplies() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先輸入對方的訊息')),
      );
      return;
    }

    final usage = context.read<UsageService>();
    if (!usage.canUse) {
      _showPaywall();
      return;
    }

    final ai = context.read<AiService>();
    final replies = await ai.generateReplies(
      text,
      _selectedStyle,
      persona: _selectedPersona,
      intimacyLevel: _intimacyLevel,
    );

    if (replies.isNotEmpty) {
      await usage.recordUsage();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReplyCardsView(
              originalMessage: text,
              style: _selectedStyle,
            ),
          ),
        );
      }
    }
  }

  void _showPaywall() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiService>();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Gradient glow at top ──────────────────────────────
            Positioned(
              top: -100,
              left: -50,
              right: -50,
              height: 300,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.2,
                    colors: [
                      Color(0x40AB47BC),
                      Color(0x20FF80AB),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Particle background ───────────────────────────────
            const ParticleBackground(),

            // ── Main content ──────────────────────────────────────
            CustomScrollView(
              slivers: [
                // ── App Bar ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingMd, AppTheme.spacingMd,
                      AppTheme.spacingMd, 0,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '\u{2728} AI \u{6200}\u{611B}\u{9375}\u{76E4}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // PRO badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: AppTheme.romanticGradient,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const CoinBalanceWidget(),
                        const SizedBox(width: 4),
                        const UsageIndicator(),
                        const SizedBox(width: 4),
                        Consumer<AchievementService>(
                          builder: (_, achievementSvc, child) {
                            final unclaimed = achievementSvc.unclaimedCount;
                            return Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.emoji_events_rounded,
                                      color: AppTheme.textSecondary),
                                  tooltip: '成就',
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AchievementsView()),
                                  ),
                                ),
                                if (unclaimed > 0)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$unclaimed',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined,
                              color: AppTheme.textSecondary),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsView()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Keyboard Setup Banner ─────────────────────────
                if (!_keyboardBannerDismissed)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacingMd, AppTheme.spacingMd,
                        AppTheme.spacingMd, 0,
                      ),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsView()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFAB47BC), Color(0xFFFF80AB)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusLg),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary
                                    .withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.keyboard_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '\u{2328}\u{FE0F} \u{555F}\u{7528} AI \u{9375}\u{76E4}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      '在 LINE、IG、交友 App 中直接生成回覆',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(
                                    () => _keyboardBannerDismissed = true),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(
                          duration: const Duration(milliseconds: 500)),
                  ),

                // ── Seasonal Package Banner ──────────────────────
                Consumer<SeasonalService>(
                  builder: (_, seasonalSvc, child) {
                    final banner = seasonalSvc.bannerPackage;
                    if (banner == null) {
                      return const SliverToBoxAdapter(
                          child: SizedBox.shrink());
                    }
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.spacingMd, AppTheme.spacingMd,
                          AppTheme.spacingMd, 0,
                        ),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const SeasonalPackagesView()),
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusLg),
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: banner.gradient,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusLg),
                                  boxShadow: [
                                    BoxShadow(
                                      color: banner.primaryColor
                                          .withValues(alpha: 0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Text(banner.emoji,
                                        style:
                                            const TextStyle(fontSize: 28)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${banner.name} 限時優惠！',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '剩餘 ${banner.daysRemaining} 天 | \$${banner.price.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => seasonalSvc
                                          .dismissBanner(banner.id),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white54,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(
                            duration: const Duration(milliseconds: 500)),
                    );
                  },
                ),

                // ── Persona Pill ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingMd, AppTheme.spacingMd,
                      AppTheme.spacingMd, 0,
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        final persona =
                            await Navigator.push<ChatPersona?>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CharacterMarketView(
                              currentPersona: _selectedPersona,
                            ),
                          ),
                        );
                        if (mounted) {
                          setState(
                              () => _selectedPersona = persona);
                        }
                      },
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                        child: BackdropFilter(
                          filter:
                              ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull),
                              border: Border.all(
                                color: _selectedPersona != null
                                    ? AppTheme.accent
                                        .withValues(alpha: 0.4)
                                    : Colors.white
                                        .withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedPersona?.emoji ?? '\u{1F3AD}',
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedPersona != null
                                      ? '角色：${_selectedPersona!.name}'
                                      : '選擇 AI 角色',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedPersona != null
                                        ? AppTheme.accent
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppTheme.textHint,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(
                        duration: const Duration(milliseconds: 400)),
                ),

                // ── Intimacy hearts ───────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingMd, AppTheme.spacingMd,
                      AppTheme.spacingMd, 0,
                    ),
                    child: IntimacySelector(
                      selectedLevel: _intimacyLevel,
                      onChanged: (level) =>
                          setState(() => _intimacyLevel = level),
                    ),
                  ).animate().fadeIn(
                        duration: const Duration(milliseconds: 400)),
                ),

                // ── Platform Chips ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingMd, AppTheme.spacingMd,
                      AppTheme.spacingMd, 0,
                    ),
                    child: Row(
                      children: _platforms.map((platform) {
                        final isSelected =
                            platform == _selectedPlatform;
                        final emoji = platform == '交友App'
                            ? '\u{1F498}'
                            : platform == 'LINE'
                                ? '\u{1F4AC}'
                                : '\u{1F4F8}';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _selectedPlatform = platform),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 8, sigmaY: 8),
                                child: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primary
                                            .withValues(alpha: 0.25)
                                        : Colors.white
                                            .withValues(alpha: 0.06),
                                    borderRadius:
                                        BorderRadius.circular(
                                            AppTheme.radiusFull),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.accent
                                              .withValues(alpha: 0.5)
                                          : Colors.white
                                              .withValues(alpha: 0.1),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.accent
                                                  .withValues(
                                                      alpha: 0.2),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    '$emoji $platform',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ).animate().fadeIn(
                        duration: const Duration(milliseconds: 400)),
                ),

                // ── Message Input (glassmorphism) ─────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '對方傳了什麼？',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                                sigmaX: 10, sigmaY: 10),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusLg),
                                border: Border.all(
                                  color: _inputFocused
                                      ? AppTheme.accent
                                          .withValues(alpha: 0.5)
                                      : Colors.white
                                          .withValues(alpha: 0.08),
                                  width: _inputFocused ? 1.5 : 1,
                                ),
                                boxShadow: _inputFocused
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.accent
                                              .withValues(alpha: 0.15),
                                          blurRadius: 12,
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: TextField(
                                controller: _messageController,
                                focusNode: _inputFocusNode,
                                maxLines: 4,
                                maxLength:
                                    AppConstants.maxInputLength,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary),
                                decoration: InputDecoration(
                                  hintText: '貼上對方的訊息...',
                                  hintStyle: const TextStyle(
                                      color: AppTheme.textHint),
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(
                        duration: const Duration(milliseconds: 500)),
                  ),
                ),

                // ── Style Selector (2 rows of emoji chips) ────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '選擇回覆風格',
                          style:
                              Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        _buildStyleChips(),
                      ],
                    ),
                  ),
                ),

                // ── Generate Button ───────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(AppTheme.spacingMd),
                    child: _GradientButton(
                      onTap:
                          ai.isLoading ? null : _generateReplies,
                      isLoading: ai.isLoading,
                      label: '\u{2728} 生成回覆',
                    ),
                  ),
                ),

                // ── Error Message ─────────────────────────────────
                if (ai.error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd),
                          border: Border.all(
                              color: AppTheme.error
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppTheme.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ai.error!,
                                style: const TextStyle(
                                    color: AppTheme.error,
                                    fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18,
                                  color: AppTheme.error),
                              onPressed: ai.clearError,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Feature Grid (3 columns) ─────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '更多功能',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        _buildFeatureGrid(),
                      ],
                    ),
                  ),
                ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),

            // ── Floating Emergency Button ─────────────────────────
            Positioned(
              right: AppTheme.spacingMd,
              bottom: AppTheme.spacingMd,
              child: _PulsingEmergencyButton(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EmergencyCoachView()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleChips() {
    final styles = _showAllStyles
        ? ReplyStyle.values
        : ReplyStyle.values.take(_mainStyleCount).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...styles.map((style) {
          final isSelected = style == _selectedStyle;
          return GestureDetector(
            onTap: () => setState(() => _selectedStyle = style),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? style.color.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(
                  color: isSelected
                      ? style.color.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.1),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: style.color.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(style.emoji,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    style.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? style.color
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (!_showAllStyles)
          GestureDetector(
            onTap: () => setState(() => _showAllStyles = true),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('\u{2795}', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 4),
                  Text(
                    '更多',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeatureGrid() {
    final features = <_FeatureItem>[
      _FeatureItem(
          emoji: '\u{1F321}\u{FE0F}', label: '聊天溫度計',
          onTap: () {
            AnalyticsService.instance.trackFeatureUsed(
                feature: AdTrackingConfig.featureAnalysis);
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => const ChatAnalysisView()));
          }),
      _FeatureItem(
          emoji: '\u{1F9E0}', label: '她什麼意思',
          onTap: () {
            AnalyticsService.instance.trackFeatureUsed(
                feature: AdTrackingConfig.featureInterpret);
            Navigator.push(context, MaterialPageRoute(
                builder: (_) =>
                    const ChatAnalysisView(initialTab: 1)));
          }),
      _FeatureItem(
          emoji: '\u{1F4AC}', label: '破冰開場白',
          onTap: () {
            AnalyticsService.instance.trackFeatureUsed(
                feature: AdTrackingConfig.featureOpener);
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => const OpenerView()));
          }),
      _FeatureItem(
          emoji: '\u{1F4A1}', label: '話題建議',
          onTap: () {
            AnalyticsService.instance.trackFeatureUsed(
                feature: AdTrackingConfig.featureTopic);
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => const TopicSuggestionsView()));
          }),
      _FeatureItem(
          emoji: '\u{1F30D}', label: '跨國翻譯',
          onTap: () {
            AnalyticsService.instance.trackFeatureUsed(
                feature: AdTrackingConfig.featureTranslate);
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => const TranslateReplyView()));
          }),
      _FeatureItem(
          emoji: '\u{23F0}', label: '節奏教練',
          onTap: () {
            AnalyticsService.instance.trackFeatureUsed(
                feature: AdTrackingConfig.featureTiming);
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => const TimingCoachView()));
          }),
      _FeatureItem(
          emoji: '\u{1F60A}', label: '表情建議',
          onTap: () {
            AnalyticsService.instance.trackFeatureUsed(
                feature: AdTrackingConfig.featureEmoji);
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => const EmojiSuggesterView()));
          }),
      _FeatureItem(
          emoji: '\u{2764}\u{FE0F}', label: '約會邀請',
          onTap: () {
            AnalyticsService.instance.trackFeatureUsed(
                feature: AdTrackingConfig.featureDate);
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => const DateInvitationView()));
          }),
      _FeatureItem(
          emoji: '\u{1F91D}', label: '吵架和好',
          onTap: () {
            AnalyticsService.instance.trackFeatureUsed(
                feature: AdTrackingConfig.featureArgument);
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => const ArgumentResolveView()));
          }),
      _FeatureItem(
          emoji: '\u{2600}\u{FE0F}', label: '早安晚安',
          onTap: () {
            AnalyticsService.instance.trackFeatureUsed(
                feature: AdTrackingConfig.featureGreeting);
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => const GreetingsView()));
          }),
      _FeatureItem(
          emoji: '\u{2B50}', label: '回覆評分',
          onTap: () {
            AnalyticsService.instance.trackFeatureUsed(
                feature: AdTrackingConfig.featureScore);
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => const ReplyScorerView()));
          }),
      _FeatureItem(
          emoji: '\u{1F30F}', label: '約會文化',
          onTap: () {
            AnalyticsService.instance.trackFeatureUsed(
                feature: AdTrackingConfig.featureCulture);
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => const CultureTipsView()));
          }),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final item = features[index];
        return GestureDetector(
          onTap: item.onTap,
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(AppTheme.radiusLg),
            child: BackdropFilter(
              filter:
                  ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(
                      AppTheme.radiusLg),
                  border: Border.all(
                    color:
                        Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(item.emoji,
                        style:
                            const TextStyle(fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            .animate(
                delay: Duration(milliseconds: 200 + index * 50))
            .fadeIn(duration: const Duration(milliseconds: 400));
      },
    );
  }
}

class _FeatureItem {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  _FeatureItem({
    required this.emoji,
    required this.label,
    required this.onTap,
  });
}

// ── Pulsing Emergency FAB ────────────────────────────────────────────
class _PulsingEmergencyButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PulsingEmergencyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '\u{1F198}',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.08, 1.08),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOut,
        );
  }
}

// ── Gradient Button ──────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final String label;

  const _GradientButton({
    required this.onTap,
    required this.isLoading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: onTap != null
              ? const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFAB47BC)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: onTap == null
              ? Colors.white.withValues(alpha: 0.1)
              : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color:
                        const Color(0xFFEC4899).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}
