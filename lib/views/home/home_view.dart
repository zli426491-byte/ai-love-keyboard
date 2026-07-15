import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ai_love_keyboard/models/reply_style.dart';
import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/analytics_service.dart';
import 'package:ai_love_keyboard/services/coin_service.dart';
import 'package:ai_love_keyboard/services/revenuecat_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/coins/coin_store_view.dart';
import 'package:ai_love_keyboard/views/keyboard/keyboard_guide_view.dart';
import 'package:ai_love_keyboard/views/paywall/paywall_view.dart';
import 'package:ai_love_keyboard/views/reply/reply_cards_view.dart';
import 'package:ai_love_keyboard/views/settings/settings_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  static const _ink = Color(0xFF241827);
  static const _muted = Color(0xFF7D6C78);
  static const _pink = Color(0xFFFF467C);
  static const _hotPink = Color(0xFFFF315F);
  static const _peach = Color(0xFFFFE4EC);

  final _messageController = TextEditingController();
  int _tabIndex = 0;
  ReplyStyle _selectedStyle = ReplyStyle.warm;
  String _selectedGoal = '自然接話';

  static const _keyboardStyles = [
    _KeyboardTone('😁', '幽默', ReplyStyle.humorous),
    _KeyboardTone('😉', '高情商', ReplyStyle.intellectual),
    _KeyboardTone('😌', '溫柔', ReplyStyle.warm),
    _KeyboardTone('💞', '曖昧拉扯', ReplyStyle.romantic),
    _KeyboardTone('😃', '智能回覆', ReplyStyle.mature),
    _KeyboardTone('😊', '可愛', ReplyStyle.cute),
    _KeyboardTone('😎', '大男子', ReplyStyle.cool),
    _KeyboardTone('😘', '撒嬌', ReplyStyle.cute),
    _KeyboardTone('🍷', '氛圍文學', ReplyStyle.contrast),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _generateReplies({ReplyStyle? style}) async {
    if (style != null) {
      setState(() => _selectedStyle = style);
    }

    if (_messageController.text.trim().isEmpty) {
      _showSnack('請先貼上對方的訊息，再生成回覆');
      return;
    }

    final usage = context.read<UsageService>();
    if (!usage.canUse) {
      _showPaywall();
      return;
    }

    final text = _messageController.text.trim();
    final ai = context.read<AiService>();
    final replies = await ai.generateReplies(
      text,
      _selectedStyle,
      goal: _selectedGoal,
    );
    if (!mounted) return;

    if (replies.isEmpty) {
      _showSnack('AI 回覆暫時失敗，請稍後再試');
      return;
    }

    await usage.recordUsage();
    AnalyticsService.instance.trackReplyGenerated(style: _selectedStyle.name);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReplyCardsView(
          originalMessage: text,
          style: _selectedStyle,
          goal: _selectedGoal,
        ),
      ),
    );
  }

  void _showPaywall() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallView(),
    );
  }

  void _openKeyboardGuide() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KeyboardGuideView()),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsView()),
    );
  }

  void _openCoinStore() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoinStoreView()),
    );
  }

  void _switchToBlindBox() => setState(() => _tabIndex = 1);

  void _showBlindBoxComposer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BlindBoxComposeSheet(
        onSubmit: (intro) {
          Navigator.pop(context);
          _showSnack(intro.trim().isEmpty ? '已放入一個匿名盲盒' : '盲盒已送出');
        },
      ),
    );
  }

  Future<void> _drawBlindBox() async {
    final coins = context.read<CoinService>();
    if (!coins.hasEnoughCoins(10)) {
      _showNeedCoinsDialog();
      return;
    }

    final spent = await coins.spendCoins(10, '抽盲盒');
    if (!mounted) return;
    if (!spent) {
      _showNeedCoinsDialog();
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BlindMatchSheet(),
    );
  }

  void _showNeedCoinsDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('金幣不足'),
        content: const Text('抽盲盒需要 10 金幣。可以先領每日金幣，或到金幣商店補充。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('先不用'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _openCoinStore();
            },
            child: const Text('去金幣商店'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFeedback() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'zli426491@gmail.com',
      queryParameters: {
        'subject': 'LoveKey 反饋建議',
        'body': '我想回報：\n\n手機型號：\niOS 版本：\nTestFlight Build：',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _copyBusinessEmail();
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'LoveKey',
      applicationVersion: '1.0.4',
      applicationIcon: const Icon(
        Icons.favorite_rounded,
        color: _hotPink,
        size: 42,
      ),
      children: const [Text('LoveKey 是一個用來快速生成聊天回覆與設定 iOS 鍵盤的工具。')],
    );
  }

  Future<void> _openReview() async {
    final uri = Uri.parse(AppConstants.appStoreReviewUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('目前無法開啟 App Store');
    }
  }

  void _copyBusinessEmail() {
    Clipboard.setData(const ClipboardData(text: 'zli426491@gmail.com'));
    _showSnack('已複製商務合作信箱');
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
    final ai = context.watch<AiService>();
    final usage = context.watch<UsageService>();
    final revenueCat = context.watch<RevenueCatService>();
    final subscribed = usage.isSubscribed || revenueCat.isSubscribed;
    final remainingFree = usage.remainingFree;

    final pages = [
      _HomeTab(
        loading: ai.isLoading,
        messageController: _messageController,
        selectedGoal: _selectedGoal,
        onGoalChanged: (value) => setState(() => _selectedGoal = value),
        subscribed: subscribed,
        remainingFree: remainingFree,
        keyboardStyles: _keyboardStyles,
        onGenerate: () => _generateReplies(),
        onToneTap: (tone) => _generateReplies(style: tone.style),
        onPaywall: _showPaywall,
        onRewrite: () => _generateReplies(style: ReplyStyle.intellectual),
        onKeyboardGuide: _openKeyboardGuide,
        onBlindBox: _switchToBlindBox,
      ),
      _BlindBoxTab(
        onOpen: _showBlindBoxComposer,
        onDraw: _drawBlindBox,
        onSettings: _openSettings,
        onCoinStore: _openCoinStore,
      ),
      _MessagesTab(
        onHome: () => setState(() => _tabIndex = 0),
        onBlindBox: _switchToBlindBox,
      ),
      _ProfileTab(
        subscribed: subscribed,
        remainingFree: remainingFree,
        onPaywall: _showPaywall,
        onSettings: _openSettings,
        onKeyboardGuide: _openKeyboardGuide,
        onCopyEmail: _copyBusinessEmail,
        onFeedback: _sendFeedback,
        onAbout: _showAbout,
        onReview: _openReview,
      ),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: pages[_tabIndex],
      ),
      bottomNavigationBar: _AppBottomNav(
        currentIndex: _tabIndex,
        onTap: (index) => setState(() => _tabIndex = index),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final bool loading;
  final TextEditingController messageController;
  final String selectedGoal;
  final ValueChanged<String> onGoalChanged;
  final bool subscribed;
  final int remainingFree;
  final List<_KeyboardTone> keyboardStyles;
  final VoidCallback onGenerate;
  final ValueChanged<_KeyboardTone> onToneTap;
  final VoidCallback onPaywall;
  final VoidCallback onRewrite;
  final VoidCallback onKeyboardGuide;
  final VoidCallback onBlindBox;

  const _HomeTab({
    required this.loading,
    required this.messageController,
    required this.selectedGoal,
    required this.onGoalChanged,
    required this.subscribed,
    required this.remainingFree,
    required this.keyboardStyles,
    required this.onGenerate,
    required this.onToneTap,
    required this.onPaywall,
    required this.onRewrite,
    required this.onKeyboardGuide,
    required this.onBlindBox,
  });

  @override
  Widget build(BuildContext context) {
    return _PinkShell(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 128),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HomeHeader(onPaywall: onPaywall),
            const SizedBox(height: 8),
            const _IntimacyHero(percent: 30),
            const SizedBox(height: 10),
            _MessageComposer(
              controller: messageController,
              goal: selectedGoal,
              onGoalChanged: onGoalChanged,
            ),
            const SizedBox(height: 14),
            _MainCtaButton(loading: loading, onTap: onGenerate),
            const SizedBox(height: 10),
            _UsageSummary(subscribed: subscribed, remainingFree: remainingFree),
            const SizedBox(height: 18),
            _FeatureGrid(onPaywall: onPaywall, onRewrite: onRewrite),
            const SizedBox(height: 10),
            _BlindBanner(onTap: onBlindBox),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  '我的鍵盤',
                  style: TextStyle(
                    color: _HomeViewState._ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onKeyboardGuide,
                  icon: const Icon(Icons.settings_rounded, size: 19),
                  label: const Text('鍵盤管理'),
                  style: TextButton.styleFrom(
                    foregroundColor: _HomeViewState._muted,
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _KeyboardToneGrid(items: keyboardStyles, onTap: onToneTap),
          ],
        ),
      ),
    );
  }
}

class _BlindBoxTab extends StatelessWidget {
  final VoidCallback onOpen;
  final VoidCallback onDraw;
  final VoidCallback onSettings;
  final VoidCallback onCoinStore;

  const _BlindBoxTab({
    required this.onOpen,
    required this.onDraw,
    required this.onSettings,
    required this.onCoinStore,
  });

  @override
  Widget build(BuildContext context) {
    return _PurpleShell(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 58, 24, 128),
        child: Column(
          children: [
            Row(
              children: [
                _CoinPill(onTap: onCoinStore),
                const Spacer(),
                IconButton(
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings_rounded),
                  color: Colors.white,
                  iconSize: 32,
                ),
              ],
            ),
            const SizedBox(height: 34),
            const _BlindTitle(),
            const SizedBox(height: 16),
            const Text(
              '匿名放入心動訊息，探索新的聊天可能',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Color(0x55FF3E7A), blurRadius: 8)],
              ),
            ),
            const SizedBox(height: 34),
            const _GiftOrb(),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: _BlindButton(
                    title: '放盲盒',
                    colors: [Color(0xFF86A7FF), Color(0xFF7878FF)],
                    onTap: onOpen,
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: _BlindButton(
                    title: '抽盲盒',
                    colors: [Color(0xFFFF74D4), Color(0xFFFF3E95)],
                    badge: '10 金幣 / 次',
                    onTap: onDraw,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            TextButton(
              onPressed: onOpen,
              child: const Text(
                '我的盲盒',
                style: TextStyle(
                  color: Color(0xFF8F6BA6),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesTab extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onBlindBox;

  const _MessagesTab({required this.onHome, required this.onBlindBox});

  @override
  Widget build(BuildContext context) {
    return _PinkShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 70, 24, 128),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '消息',
              style: TextStyle(
                color: _HomeViewState._ink,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 22),
            _MessageCard(
              title: '鍵盤已更新',
              subtitle: '新的粉色鍵盤與主 App 樣式已可在最新 TestFlight 測試。',
              icon: Icons.keyboard_alt_rounded,
              onTap: onHome,
            ),
            const SizedBox(height: 14),
            _MessageCard(
              title: '盲盒交友',
              subtitle: '可以放入一則匿名訊息，也可以花 10 金幣抽一個盲盒。',
              icon: Icons.card_giftcard_rounded,
              onTap: onBlindBox,
            ),
            const SizedBox(height: 34),
            _MessagesEmptyState(onStart: onHome),
          ],
        ),
      ),
    );
  }
}

class _MessagesEmptyState extends StatelessWidget {
  final VoidCallback onStart;

  const _MessagesEmptyState({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0DDE7)),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE4ED),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: _HomeViewState._pink,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '你的回覆會出現在這裡',
            style: TextStyle(
              color: _HomeViewState._ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '貼上一段聊天訊息，先生成一則自然的回覆吧。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _HomeViewState._muted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.home_rounded, size: 17),
            label: const Text('回到首頁開始'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _HomeViewState._pink,
              side: const BorderSide(color: Color(0xFFFFA9C0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final bool subscribed;
  final int remainingFree;
  final VoidCallback onPaywall;
  final VoidCallback onSettings;
  final VoidCallback onKeyboardGuide;
  final VoidCallback onCopyEmail;
  final VoidCallback onFeedback;
  final VoidCallback onAbout;
  final VoidCallback onReview;

  const _ProfileTab({
    required this.subscribed,
    required this.remainingFree,
    required this.onPaywall,
    required this.onSettings,
    required this.onKeyboardGuide,
    required this.onCopyEmail,
    required this.onFeedback,
    required this.onAbout,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return _PinkShell(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 94, 24, 128),
        child: Column(
          children: [
            const _ProfileHeader(),
            const SizedBox(height: 28),
            _MembershipCard(
              subscribed: subscribed,
              remainingFree: remainingFree,
              onTap: onPaywall,
            ),
            const SizedBox(height: 34),
            _MenuSection(
              children: [
                _MenuRow(title: '設定語言', trailing: '繁體中文', onTap: onSettings),
              ],
            ),
            const SizedBox(height: 14),
            _MenuSection(
              children: [_MenuRow(title: '鍵盤使用教學', onTap: onKeyboardGuide)],
            ),
            const SizedBox(height: 14),
            _MenuSection(
              children: [
                _MenuRow(title: '反饋建議', onTap: onFeedback),
                _MenuRow(title: '關於我們', onTap: onAbout),
                _MenuRow(
                  title: '商務合作',
                  trailing: 'zli426491@gmail.com',
                  copy: true,
                  onTap: onCopyEmail,
                ),
                _MenuRow(title: '五星好評，鼓勵一下⭐', onTap: onReview),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PinkShell extends StatelessWidget {
  final Widget child;

  const _PinkShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFFFF7FA)),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _RomanticBackgroundPainter()),
          ),
          const Positioned(
            top: -120,
            left: -90,
            child: _GlowBlob(
              size: 300,
              colors: [Color(0x40FF789F), Color(0x00FF789F)],
            ),
          ),
          const Positioned(
            top: 90,
            right: -120,
            child: _GlowBlob(
              size: 270,
              colors: [Color(0x30FFC2D2), Color(0x00FFC2D2)],
            ),
          ),
          const Positioned(
            bottom: 250,
            left: -110,
            child: _GlowBlob(
              size: 260,
              colors: [Color(0x33FFD9B7), Color(0x00FFD9B7)],
            ),
          ),
          const Positioned(
            bottom: -120,
            right: -90,
            child: _GlowBlob(
              size: 260,
              colors: [Color(0x2CBEE7FF), Color(0x00BEE7FF)],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _RomanticBackgroundPainter extends CustomPainter {
  const _RomanticBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFE5EE),
          Color(0xFFFFF7FA),
          Color(0xFFFFFFFF),
          Color(0xFFFFF6F8),
        ],
        stops: [0, 0.45, 0.78, 1],
      ).createShader(rect);
    canvas.drawRect(rect, base);

    void radial(Offset center, double radius, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    radial(
      Offset(size.width * 0.18, size.height * 0.09),
      size.width * 0.54,
      const Color(0x38FF789F),
    );
    radial(
      Offset(size.width * 0.88, size.height * 0.18),
      size.width * 0.44,
      const Color(0x30FFB8CA),
    );
    radial(
      Offset(size.width * 0.24, size.height * 0.62),
      size.width * 0.46,
      const Color(0x24FFE1B8),
    );
    radial(
      Offset(size.width * 0.82, size.height * 0.76),
      size.width * 0.50,
      const Color(0x18FFD6E1),
    );

    final veil = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.46),
          Colors.white.withValues(alpha: 0.10),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, veil);
  }

  @override
  bool shouldRepaint(covariant _RomanticBackgroundPainter oldDelegate) => false;
}

class _PurpleShell extends StatelessWidget {
  final Widget child;

  const _PurpleShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9FB4FF),
            Color(0xFFDCC2FF),
            Color(0xFFFFCAE0),
            Color(0xFFFBE6FF),
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -70,
            right: -70,
            child: _GlowBlob(
              size: 230,
              colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
            ),
          ),
          const Positioned(
            bottom: 120,
            left: -90,
            child: _GlowBlob(
              size: 260,
              colors: [Color(0xFFFF6FB5), Color(0x00FF6FB5)],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _GlowBlob({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final VoidCallback onPaywall;

  const _HomeHeader({required this.onPaywall});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.50),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0DFF5C82),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: _HomeViewState._hotPink,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LoveKey',
                    style: TextStyle(
                      color: _HomeViewState._ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onPaywall,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.76),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: Colors.white),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14FF4F78),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0xFFFFE7B5), Color(0x00FFE7B5)],
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: _HomeViewState._hotPink,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IntimacyHero extends StatelessWidget {
  final int percent;

  const _IntimacyHero({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            '$percent%',
            style: const TextStyle(
              color: Color(0xFF24212A),
              fontSize: 52,
              height: 0.95,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '聊天親密度',
            style: TextStyle(
              color: Color(0xFF7D6D75),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 220,
            height: 156,
            child: _GlossyHeart(percent: percent),
          ),
        ],
      ),
    );
  }
}

class _GlossyHeart extends StatelessWidget {
  final int percent;

  const _GlossyHeart({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Positioned.fill(child: CustomPaint(painter: _HeartGlowPainter())),
        Positioned(
          bottom: 2,
          child: Container(
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2A8D3B5A),
                  blurRadius: 30,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 170,
          height: 146,
          child: CustomPaint(painter: _HeartGaugePainter(percent / 100)),
        ),
      ],
    );
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final String goal;
  final ValueChanged<String> onGoalChanged;

  const _MessageComposer({
    required this.controller,
    required this.goal,
    required this.onGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFC4D4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16FF467C),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: '對方的訊息',
              hintText: '貼上聊天內容，LoveKey 幫你生成回覆',
              hintStyle: const TextStyle(
                color: Color(0xFFB4A4AE),
                fontSize: 14,
              ),
              labelStyle: const TextStyle(
                color: _HomeViewState._pink,
                fontWeight: FontWeight.w800,
              ),
              border: InputBorder.none,
              suffixIcon: IconButton(
                tooltip: '清除',
                onPressed: controller.clear,
                icon: const Icon(Icons.close_rounded, color: Color(0xFFB4A4AE)),
              ),
            ),
          ),
          const Divider(height: 12, color: Color(0x22FF467C)),
          _ContextChoiceRow(
            label: '目的',
            values: const ['自然接話', '安慰', '邀約', '道歉'],
            selected: goal,
            onChanged: onGoalChanged,
          ),
        ],
      ),
    );
  }
}

class _ContextChoiceRow extends StatelessWidget {
  final String label;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ContextChoiceRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _HomeViewState._muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        ...values.map(
          (value) => ChoiceChip(
            label: Text(value),
            selected: value == selected,
            onSelected: (_) => onChanged(value),
            selectedColor: _HomeViewState._pink.withValues(alpha: 0.16),
            backgroundColor: Colors.white.withValues(alpha: 0.72),
            side: BorderSide(
              color: value == selected
                  ? _HomeViewState._pink
                  : const Color(0x22FF467C),
            ),
            labelStyle: TextStyle(
              color: value == selected
                  ? _HomeViewState._pink
                  : _HomeViewState._muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        ),
      ],
    );
  }
}

class _UsageSummary extends StatelessWidget {
  final bool subscribed;
  final int remainingFree;

  const _UsageSummary({required this.subscribed, required this.remainingFree});

  @override
  Widget build(BuildContext context) {
    final color = subscribed ? const Color(0xFF8D47C7) : _HomeViewState._muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            subscribed ? Icons.workspace_premium_rounded : Icons.bolt_rounded,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            subscribed ? 'Pro 已解鎖無限回覆' : '今日剩餘免費回覆 $remainingFree 次',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _HeartGaugePainter extends CustomPainter {
  final double value;

  const _HeartGaugePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final fill = value.clamp(0.0, 1.0);
    final heart = _heartPath(size);
    final bounds = Offset.zero & size;

    final outerGlow = Paint()
      ..color = const Color(0x30FF5B86)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawPath(heart.shift(const Offset(0, 2)), outerGlow);

    final softShadow = Paint()
      ..color = const Color(0x2C6E233F)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawPath(heart.shift(const Offset(0, 18)), softShadow);

    final base = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.36, -0.42),
        radius: 1.05,
        colors: [
          Colors.white.withValues(alpha: 0.94),
          const Color(0xFFFFCFE0).withValues(alpha: 0.86),
          const Color(0xFFFF86A0).withValues(alpha: 0.78),
          const Color(0xFFFF5E72).withValues(alpha: 0.72),
        ],
      ).createShader(bounds);
    canvas.drawPath(heart, base);

    canvas.save();
    canvas.clipPath(heart);
    final glassWash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.58),
          Colors.white.withValues(alpha: 0.12),
          const Color(0xFFFF2F64).withValues(alpha: 0.12),
        ],
        stops: const [0, 0.47, 1],
      ).createShader(bounds);
    canvas.drawRect(bounds, glassWash);

    final refract = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.17,
        size.width * 0.68,
        size.height * 0.54,
      ),
      3.55,
      2.1,
      false,
      refract,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.36,
        size.width * 0.48,
        size.height * 0.42,
      ),
      0.18,
      1.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x66FFEDF4),
    );
    canvas.restore();

    canvas.save();
    canvas.clipPath(heart);
    final fillTop = size.height * (1 - fill);
    final liquid = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF7D9E).withValues(alpha: 0.58),
          const Color(0xFFFF2F64).withValues(alpha: 0.82),
          const Color(0xFFD81855).withValues(alpha: 0.92),
        ],
      ).createShader(bounds);
    final liquidPath = Path()
      ..moveTo(0, fillTop + size.height * 0.02)
      ..cubicTo(
        size.width * 0.24,
        fillTop - size.height * 0.07,
        size.width * 0.58,
        fillTop + size.height * 0.10,
        size.width,
        fillTop,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(liquidPath, liquid);
    canvas.drawPath(
      Path()
        ..moveTo(0, fillTop + size.height * 0.02)
        ..cubicTo(
          size.width * 0.24,
          fillTop - size.height * 0.07,
          size.width * 0.58,
          fillTop + size.height * 0.10,
          size.width,
          fillTop,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.34),
    );
    canvas.restore();

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.92),
          Colors.white.withValues(alpha: 0.24),
          const Color(0x66FF6E92),
        ],
      ).createShader(bounds);
    canvas.drawPath(heart, stroke);

    final innerDepth = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = const Color(0x24B01048);
    canvas.drawPath(heart.shift(const Offset(0, 7)), innerDepth);

    final shine = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.88),
              Colors.white.withValues(alpha: 0.18),
            ],
          ).createShader(
            Rect.fromLTWH(10, 7, size.width * 0.56, size.height * 0.36),
          );
    final shinePath = Path()
      ..moveTo(size.width * 0.18, size.height * 0.34)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.15,
        size.width * 0.43,
        size.height * 0.12,
        size.width * 0.49,
        size.height * 0.29,
      )
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.24,
        size.width * 0.26,
        size.height * 0.34,
        size.width * 0.18,
        size.height * 0.48,
      )
      ..close();
    canvas.drawPath(shinePath, shine);

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.72);
    canvas.drawCircle(
      Offset(size.width * 0.34, size.height * 0.20),
      4,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.70, size.height * 0.26),
      3,
      dotPaint,
    );
  }

  Path _heartPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.50, h * 0.92)
      ..cubicTo(w * 0.18, h * 0.70, w * 0.04, h * 0.52, w * 0.11, h * 0.31)
      ..cubicTo(w * 0.18, h * 0.08, w * 0.42, h * 0.06, w * 0.50, h * 0.27)
      ..cubicTo(w * 0.58, h * 0.06, w * 0.82, h * 0.08, w * 0.89, h * 0.31)
      ..cubicTo(w * 0.96, h * 0.52, w * 0.82, h * 0.70, w * 0.50, h * 0.92)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _HeartGaugePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

// ignore: unused_element
class _HeartGlowPainter extends CustomPainter {
  const _HeartGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.50, size.height * 0.50);
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0x26FF6C95),
              const Color(0x14FFD4E5),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.width * 0.48),
          );
    canvas.drawCircle(center, size.width * 0.48, glow);

    final shine = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.54),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.32, size.height * 0.28),
              radius: size.width * 0.20,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.32, size.height * 0.28),
      size.width * 0.20,
      shine,
    );
  }

  @override
  bool shouldRepaint(covariant _HeartGlowPainter oldDelegate) => false;
}

class _GiftOrbPainter extends CustomPainter {
  const _GiftOrbPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);
    final orbRadius = size.width * 0.34;
    final orbRect = Rect.fromCircle(center: center, radius: orbRadius);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.90),
          const Color(0x88FFB8E2),
          const Color(0x00FFFFFF),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: orbRadius * 1.35));
    canvas.drawCircle(center, orbRadius * 1.35, glow);

    final orb = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        colors: [
          Colors.white.withValues(alpha: 0.95),
          const Color(0xCCFFE1F3),
          const Color(0x88C9BCFF),
          Colors.white.withValues(alpha: 0.12),
        ],
      ).createShader(orbRect);
    canvas.drawCircle(center, orbRadius, orb);

    final orbStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.72);
    canvas.drawCircle(center, orbRadius, orbStroke);

    final pedestal = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFE7D4FF), Color(0x00FFFFFF)],
      ).createShader(Rect.fromLTWH(0, size.height * 0.75, size.width, 54));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.80),
        width: size.width * 0.74,
        height: 54,
      ),
      pedestal,
    );

    final shine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.62);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: orbRadius * 0.76),
      -2.75,
      1.1,
      false,
      shine,
    );
  }

  @override
  bool shouldRepaint(covariant _GiftOrbPainter oldDelegate) => false;
}

class _MainCtaButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _MainCtaButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFFF2F5F), Color(0xFFFF6F7E), Color(0xFFFF9A8B)],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40FF4F78),
                blurRadius: 30,
                offset: Offset(0, 15),
              ),
              BoxShadow(
                color: Color(0x3DFFFFFF),
                blurRadius: 16,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                top: 1,
                bottom: 36,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.30),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (loading)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    else
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      loading ? '生成中...' : '生成一則回覆',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final VoidCallback onPaywall;
  final VoidCallback onRewrite;

  const _FeatureGrid({required this.onPaywall, required this.onRewrite});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FeatureCard(
            title: '情感老師',
            subtitle: '全天在線解答問題',
            colors: const [Color(0xFFFFD6DF), Color(0xFFFFF1F4)],
            accent: const Color(0xFFFF4F7D),
            artwork: _FeatureArtwork.coach,
            onTap: onPaywall,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _FeatureCard(
            title: '文案改寫',
            subtitle: '引起Ta的興趣',
            colors: const [Color(0xFFFFE0B8), Color(0xFFFFF4DE)],
            accent: const Color(0xFFFF8A42),
            artwork: _FeatureArtwork.rewrite,
            onTap: onRewrite,
          ),
        ),
      ],
    );
  }
}

enum _FeatureArtwork { coach, rewrite }

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Color> colors;
  final Color accent;
  final _FeatureArtwork artwork;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.accent,
    required this.artwork,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 116,
            padding: const EdgeInsets.fromLTRB(16, 15, 10, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x16FF5C82),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FeatureCardBackgroundPainter(
                      accent: accent,
                      artwork: artwork,
                    ),
                  ),
                ),
                Positioned(
                  left: -2,
                  bottom: -4,
                  child: Text(
                    artwork == _FeatureArtwork.coach ? 'Mentor' : 'Rewrite',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.28),
                      fontSize: 31,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: 4,
                  child: SizedBox(
                    width: 72,
                    height: 82,
                    child: CustomPaint(
                      painter: artwork == _FeatureArtwork.coach
                          ? _CoachPainter(accent)
                          : _PencilHandPainter(accent),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    SizedBox(
                      width: 94,
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8F737C),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.28,
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 2,
                  right: 2,
                  top: 0,
                  child: Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.55),
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

class _FeatureCardBackgroundPainter extends CustomPainter {
  final Color accent;
  final _FeatureArtwork artwork;

  const _FeatureCardBackgroundPainter({
    required this.accent,
    required this.artwork,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.56),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.80, size.height * 0.30),
              radius: size.width * 0.55,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.80, size.height * 0.30),
      size.width * 0.55,
      light,
    );

    final bubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.36);
    final dotPaint = Paint()..color = accent.withValues(alpha: 0.13);
    canvas.drawCircle(
      Offset(size.width * 0.14, size.height * 0.74),
      4,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.18),
      3,
      bubblePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.18),
      3.5,
      bubblePaint,
    );

    if (artwork == _FeatureArtwork.rewrite) {
      final starPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFC852).withValues(alpha: 0.64);
      _drawSpark(
        canvas,
        Offset(size.width * 0.70, size.height * 0.20),
        8,
        starPaint,
      );
      _drawSpark(
        canvas,
        Offset(size.width * 0.58, size.height * 0.76),
        5,
        starPaint,
      );
    }
  }

  void _drawSpark(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawLine(
      center.translate(-radius, 0),
      center.translate(radius, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(0, -radius),
      center.translate(0, radius),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FeatureCardBackgroundPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.artwork != artwork;
  }
}

class _CoachPainter extends CustomPainter {
  final Color accent;

  const _CoachPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = const Color(0x22000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.90),
        width: size.width * 0.54,
        height: 14,
      ),
      shadow,
    );

    final bg = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.86),
          accent.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawCircle(
      Offset(size.width * 0.53, size.height * 0.55),
      size.width * 0.48,
      bg,
    );

    final hair = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4B263F), Color(0xFFB85B7A), Color(0xFFFFA1B8)],
      ).createShader(Offset.zero & size);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.40),
        width: size.width * 0.56,
        height: size.height * 0.55,
      ),
      hair,
    );

    final face = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFE0CA), Color(0xFFFFBFAE)],
      ).createShader(Offset.zero & size);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.43),
        width: size.width * 0.40,
        height: size.height * 0.40,
      ),
      face,
    );

    final lens = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = Colors.white.withValues(alpha: 0.92);
    canvas.drawCircle(Offset(size.width * 0.43, size.height * 0.42), 6, lens);
    canvas.drawCircle(Offset(size.width * 0.57, size.height * 0.42), 6, lens);
    canvas.drawLine(
      Offset(size.width * 0.49, size.height * 0.42),
      Offset(size.width * 0.51, size.height * 0.42),
      lens,
    );

    final body = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white, accent.withValues(alpha: 0.32)],
      ).createShader(Offset.zero & size);
    final bodyPath = Path()
      ..moveTo(size.width * 0.18, size.height * 0.92)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.62,
        size.width * 0.82,
        size.height * 0.92,
      )
      ..close();
    canvas.drawPath(bodyPath, body);

    final book = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF6F8F), Color(0xFFFFC6D5)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.15,
          size.height * 0.66,
          size.width * 0.38,
          size.height * 0.22,
        ),
        const Radius.circular(6),
      ),
      book,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.50,
          size.height * 0.66,
          size.width * 0.14,
          size.height * 0.24,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.72),
    );

    final pointer = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFC45F);
    canvas.drawLine(
      Offset(size.width * 0.65, size.height * 0.70),
      Offset(size.width * 0.84, size.height * 0.48),
      pointer,
    );
  }

  @override
  bool shouldRepaint(covariant _CoachPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

// ignore: unused_element
class _PencilHandPainter extends CustomPainter {
  final Color accent;

  const _PencilHandPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = const Color(0x1F6A3D1E)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.84),
        width: size.width * 0.58,
        height: 16,
      ),
      shadow,
    );

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF1B8).withValues(alpha: 0.92),
          const Color(0x00FFF1B8),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawCircle(
      Offset(size.width * 0.54, size.height * 0.52),
      size.width * 0.46,
      glow,
    );

    final hand = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFE1CF), Color(0xFFFFB996)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.21,
          size.height * 0.58,
          size.width * 0.56,
          size.height * 0.27,
        ),
        const Radius.circular(14),
      ),
      hand,
    );
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(size.width * (0.26 + i * 0.12), size.height * 0.56),
        8,
        hand,
      );
    }

    final pencil = Paint()
      ..shader = LinearGradient(
        colors: [accent, const Color(0xFFFFD66B)],
      ).createShader(Offset.zero & size);
    canvas.save();
    canvas.translate(size.width * 0.10, size.height * 0.33);
    canvas.rotate(-0.32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * 0.84, 14),
        const Radius.circular(7),
      ),
      pencil,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.84, 0)
        ..lineTo(size.width * 0.99, 7)
        ..lineTo(size.width * 0.84, 14)
        ..close(),
      Paint()..color = const Color(0xFF5B3A2C),
    );
    canvas.restore();

    final sparkle = Paint()..color = const Color(0xFFFFD66B);
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.20),
      3,
      sparkle,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.28),
      2.5,
      sparkle,
    );
  }

  @override
  bool shouldRepaint(covariant _PencilHandPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _BlindBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _BlindBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            height: 98,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFC8C8FF),
                  Color(0xFFFFD5EC),
                  Color(0xFFBEE7FF),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18C147E9),
                  blurRadius: 26,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _BlindBannerPainter()),
                ),
                const Positioned(
                  left: 13,
                  bottom: 10,
                  child: _BannerSideIcon(icon: Icons.help_rounded),
                ),
                const Positioned(
                  right: 13,
                  bottom: 10,
                  child: _BannerSideIcon(icon: Icons.favorite_rounded),
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 72),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '盲盒交友',
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            shadows: [
                              Shadow(color: Color(0x88FF4F8B), blurRadius: 11),
                            ],
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          '解鎖未知的Ta，擁抱意外的心動',
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                      ],
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

class _BlindBannerPainter extends CustomPainter {
  const _BlindBannerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.82),
              Colors.white.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.52, size.height * 0.45),
              radius: size.width * 0.46,
            ),
          );
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.45), 140, glow);

    final heart = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF5F92), Color(0xFFFFB6CE)],
      ).createShader(Offset.zero & size);
    final path = Path()
      ..moveTo(size.width * 0.50, size.height * 0.66)
      ..cubicTo(
        size.width * 0.39,
        size.height * 0.56,
        size.width * 0.34,
        size.height * 0.47,
        size.width * 0.38,
        size.height * 0.37,
      )
      ..cubicTo(
        size.width * 0.43,
        size.height * 0.27,
        size.width * 0.49,
        size.height * 0.36,
        size.width * 0.50,
        size.height * 0.41,
      )
      ..cubicTo(
        size.width * 0.51,
        size.height * 0.36,
        size.width * 0.57,
        size.height * 0.27,
        size.width * 0.62,
        size.height * 0.37,
      )
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.47,
        size.width * 0.61,
        size.height * 0.56,
        size.width * 0.50,
        size.height * 0.66,
      )
      ..close();
    canvas.drawPath(path, heart);

    final dot = Paint()..color = Colors.white.withValues(alpha: 0.44);
    canvas.drawCircle(Offset(size.width * 0.16, size.height * 0.22), 4, dot);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.24), 3, dot);
    canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.78), 2.5, dot);
  }

  @override
  bool shouldRepaint(covariant _BlindBannerPainter oldDelegate) => false;
}

// ignore: unused_element
class _ToyAvatar extends StatelessWidget {
  final List<Color> colors;
  final IconData icon;

  const _ToyAvatar({required this.colors, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F8246A8),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _ToyPainter(
          colors: colors,
          isGirl: icon == Icons.favorite_rounded,
        ),
      ),
    );
  }
}

class _BannerSideIcon extends StatelessWidget {
  final IconData icon;

  const _BannerSideIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16A35BFF),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }
}

class _ToyPainter extends CustomPainter {
  final List<Color> colors;
  final bool isGirl;

  const _ToyPainter({required this.colors, required this.isGirl});

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = const Color(0x22000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.88),
        width: size.width * 0.70,
        height: 11,
      ),
      shadow,
    );

    final body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.20,
          size.height * 0.46,
          size.width * 0.60,
          size.height * 0.38,
        ),
        const Radius.circular(18),
      ),
      body,
    );

    final face = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE5D4), Color(0xFFFFC3AB)],
      ).createShader(Offset.zero & size);
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.34),
      size.width * 0.24,
      face,
    );

    final cap = Paint()
      ..shader = LinearGradient(
        colors: isGirl
            ? const [Color(0xFFFFD66B), Color(0xFFFF9AC1)]
            : const [Color(0xFF8294FF), Color(0xFFB6C3FF)],
      ).createShader(Offset.zero & size);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.27),
        width: size.width * 0.52,
        height: size.height * 0.30,
      ),
      3.12,
      3.15,
      true,
      cap,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.32,
          size.height * 0.18,
          size.width * 0.36,
          9,
        ),
        const Radius.circular(8),
      ),
      cap,
    );

    final eye = Paint()..color = const Color(0xFF6E4D56);
    canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.35), 2.1, eye);
    canvas.drawCircle(Offset(size.width * 0.58, size.height * 0.35), 2.1, eye);

    if (!isGirl) {
      final lens = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.78);
      canvas.drawCircle(
        Offset(size.width * 0.42, size.height * 0.35),
        5.2,
        lens,
      );
      canvas.drawCircle(
        Offset(size.width * 0.58, size.height * 0.35),
        5.2,
        lens,
      );
    } else {
      final cheek = Paint()..color = const Color(0x66FF7A9E);
      canvas.drawCircle(
        Offset(size.width * 0.37, size.height * 0.42),
        3.5,
        cheek,
      );
      canvas.drawCircle(
        Offset(size.width * 0.63, size.height * 0.42),
        3.5,
        cheek,
      );
    }

    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.10,
        size.width * 0.42,
        size.height * 0.36,
      ),
      3.7,
      1.0,
      false,
      shine,
    );
  }

  @override
  bool shouldRepaint(covariant _ToyPainter oldDelegate) {
    return oldDelegate.colors != colors || oldDelegate.isGirl != isGirl;
  }
}

class _KeyboardToneGrid extends StatelessWidget {
  final List<_KeyboardTone> items;
  final ValueChanged<_KeyboardTone> onTap;

  const _KeyboardToneGrid({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 2.45,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => onTap(item),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0EFF5C82),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  '${item.emoji} ${item.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomeViewState._ink,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CoinPill extends StatelessWidget {
  final VoidCallback onTap;

  const _CoinPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<CoinService>().balance;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFE37A), Color(0xFFFFA63D)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monetization_on_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$balance',
              style: const TextStyle(
                color: _HomeViewState._ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE0EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: _HomeViewState._pink),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlindTitle extends StatelessWidget {
  const _BlindTitle();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          '交友盲盒',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 58,
            height: 1,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 10
              ..color = const Color(0xFF7D64FF),
          ),
        ),
        const Text(
          '交友盲盒',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 58,
            height: 1,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Color(0x88FFF0A6), blurRadius: 10)],
          ),
        ),
      ],
    );
  }
}

class _GiftOrb extends StatelessWidget {
  const _GiftOrb();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 330,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size(330, 330), painter: _GiftOrbPainter()),
          Positioned(top: 74, child: _LoveMatchImage()),
          Positioned(left: 18, bottom: 68, child: _MiniAvatar(text: 'L')),
          Positioned(right: 24, bottom: 86, child: _MiniAvatar(text: 'K')),
          Positioned(
            top: 34,
            right: 48,
            child: _FloatingBadge(icon: Icons.favorite_rounded),
          ),
          Positioned(
            left: 18,
            top: 88,
            child: _FloatingBadge(icon: Icons.auto_awesome_rounded),
          ),
        ],
      ),
    );
  }
}

class _LoveMatchImage extends StatelessWidget {
  const _LoveMatchImage();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 230,
      height: 188,
      child: CustomPaint(painter: _LoveMatchPainter()),
    );
  }
}

class _LoveMatchPainter extends CustomPainter {
  const _LoveMatchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFFF7DAC).withValues(alpha: 0.36),
              const Color(0xFFB9CCFF).withValues(alpha: 0.20),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.width * 0.48),
          );
    canvas.drawCircle(center, size.width * 0.48, glow);

    final shadow = Paint()
      ..color = const Color(0x226B46C1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.84),
        width: size.width * 0.72,
        height: 28,
      ),
      shadow,
    );

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 8),
        width: size.width * 0.86,
        height: size.height * 0.70,
      ),
      const Radius.circular(34),
    );
    final cardPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.92),
          const Color(0xFFFFD8EA).withValues(alpha: 0.78),
          const Color(0xFFD9E6FF).withValues(alpha: 0.74),
        ],
      ).createShader(cardRect.outerRect);
    canvas.drawRRect(cardRect, cardPaint);

    final cardStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.72);
    canvas.drawRRect(cardRect, cardStroke);

    final heartPath = Path();
    final heartCenter = Offset(center.dx, size.height * 0.44);
    final scale = size.width * 0.012;
    for (var i = 0; i <= 120; i++) {
      final t = (i / 120) * 2 * math.pi;
      final x = 16 * math.pow(math.sin(t), 3).toDouble();
      final y =
          -(13 * math.cos(t) -
              5 * math.cos(2 * t) -
              2 * math.cos(3 * t) -
              math.cos(4 * t));
      final point = Offset(
        heartCenter.dx + x * scale,
        heartCenter.dy + y * scale,
      );
      if (i == 0) {
        heartPath.moveTo(point.dx, point.dy);
      } else {
        heartPath.lineTo(point.dx, point.dy);
      }
    }
    heartPath.close();

    final heartShadow = Paint()
      ..color = const Color(0x33FF2F64)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawPath(heartPath.shift(const Offset(0, 8)), heartShadow);

    final heartPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        colors: [
          Colors.white.withValues(alpha: 0.96),
          const Color(0xFFFFA7BF).withValues(alpha: 0.92),
          const Color(0xFFFF4C76).withValues(alpha: 0.94),
          const Color(0xFFD8295D).withValues(alpha: 0.98),
        ],
      ).createShader(Rect.fromCircle(center: heartCenter, radius: 58));
    canvas.drawPath(heartPath, heartPaint);

    final heartHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(heartCenter.dx - 18, heartCenter.dy - 15),
        width: 42,
        height: 30,
      ),
      -2.65,
      1.2,
      false,
      heartHighlight,
    );

    void drawAvatar({
      required Offset origin,
      required Color hair,
      required Color shirt,
      required Color face,
      required bool right,
    }) {
      final bubblePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.92),
            shirt.withValues(alpha: 0.42),
          ],
        ).createShader(Rect.fromCircle(center: origin, radius: 42));
      canvas.drawCircle(origin, 42, bubblePaint);
      canvas.drawCircle(
        origin,
        42,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.80),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(origin.dx, origin.dy + 35),
            width: 52,
            height: 42,
          ),
          const Radius.circular(18),
        ),
        Paint()..color = shirt.withValues(alpha: 0.70),
      );
      canvas.drawCircle(origin, 22, Paint()..color = face);

      final hairPath = Path()
        ..moveTo(origin.dx - 23, origin.dy - 3)
        ..quadraticBezierTo(
          origin.dx - 10,
          origin.dy - 28,
          origin.dx + 15,
          origin.dy - 20,
        )
        ..quadraticBezierTo(
          origin.dx + 26,
          origin.dy - 4,
          origin.dx + 18,
          origin.dy + 10,
        )
        ..quadraticBezierTo(
          origin.dx - 3,
          origin.dy - 2,
          origin.dx - 23,
          origin.dy - 3,
        )
        ..close();
      canvas.drawPath(hairPath, Paint()..color = hair);

      final eye = Paint()..color = const Color(0xFF463247);
      canvas.drawCircle(Offset(origin.dx - 7, origin.dy + 2), 2.1, eye);
      canvas.drawCircle(Offset(origin.dx + 7, origin.dy + 2), 2.1, eye);
      canvas.drawCircle(
        Offset(origin.dx + (right ? -14 : 14), origin.dy + 8),
        4.3,
        Paint()..color = const Color(0x3DFF5F8C),
      );

      final smile = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFB75A76);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(origin.dx, origin.dy + 9),
          width: 14,
          height: 9,
        ),
        0.2,
        2.75,
        false,
        smile,
      );
    }

    drawAvatar(
      origin: Offset(size.width * 0.28, size.height * 0.48),
      hair: const Color(0xFF6A5CE8),
      shirt: const Color(0xFF8EA6FF),
      face: const Color(0xFFFFD9C3),
      right: false,
    );
    drawAvatar(
      origin: Offset(size.width * 0.72, size.height * 0.48),
      hair: const Color(0xFFFF78A9),
      shirt: const Color(0xFFFF8AB3),
      face: const Color(0xFFFFD8C6),
      right: true,
    );

    final chatPaint = Paint()..color = Colors.white.withValues(alpha: 0.88);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.06, size.height * 0.10, 58, 25),
        const Radius.circular(14),
      ),
      chatPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.68, size.height * 0.12, 58, 25),
        const Radius.circular(14),
      ),
      chatPaint,
    );

    final chatHeart = Paint()..color = const Color(0xFFFF467C);
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.165),
      4,
      chatHeart,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.185),
      4,
      chatHeart,
    );

    final sparklePaint = Paint()..color = Colors.white.withValues(alpha: 0.78);
    canvas.drawCircle(
      Offset(size.width * 0.46, size.height * 0.17),
      3,
      sparklePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.58, size.height * 0.15),
      2.2,
      sparklePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LoveMatchPainter oldDelegate) => false;
}

class _MiniAvatar extends StatelessWidget {
  final String text;

  const _MiniAvatar({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.92),
            const Color(0xFFFFDCEC).withValues(alpha: 0.72),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33C147E9),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _HomeViewState._hotPink,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  final IconData icon;

  const _FloatingBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFFD5EA)],
        ),
        boxShadow: [
          BoxShadow(
            color: _HomeViewState._pink.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, color: _HomeViewState._hotPink, size: 28),
    );
  }
}

class _BlindButton extends StatelessWidget {
  final String title;
  final List<Color> colors;
  final String? badge;
  final VoidCallback onTap;

  const _BlindButton({
    required this.title,
    required this.colors,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(23),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withValues(alpha: 0.36),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            right: -4,
            top: -14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3A3),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: _HomeViewState._ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BlindBoxComposeSheet extends StatefulWidget {
  final ValueChanged<String> onSubmit;

  const _BlindBoxComposeSheet({required this.onSubmit});

  @override
  State<_BlindBoxComposeSheet> createState() => _BlindBoxComposeSheetState();
}

class _BlindBoxComposeSheetState extends State<_BlindBoxComposeSheet> {
  final _controller = TextEditingController(text: '喜歡輕鬆聊天，也想認識有趣的人。');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0DDE7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '放入盲盒',
                style: TextStyle(
                  color: _HomeViewState._ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '寫一句自然的自我介紹，系統會匿名放入盲盒池。',
                style: TextStyle(
                  color: _HomeViewState._muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '例如：下班後喜歡散步和找好吃的店。',
                  filled: true,
                  fillColor: const Color(0xFFFFF6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFF0DDE7)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () => widget.onSubmit(_controller.text),
                  style: FilledButton.styleFrom(
                    backgroundColor: _HomeViewState._hotPink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    '放入盲盒',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
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

class _BlindMatchSheet extends StatelessWidget {
  const _BlindMatchSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF7AA4), Color(0xFFC147E9)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '抽到一個盲盒',
              style: TextStyle(
                color: _HomeViewState._ink,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '「我也喜歡輕鬆聊天，最近在找週末可以去的咖啡店。」',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _HomeViewState._muted,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: _HomeViewState._hotPink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  '收下',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MessageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _HomeViewState._peach,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, color: _HomeViewState._pink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _HomeViewState._ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _HomeViewState._muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB5C4FF), Color(0xFF8C9CFF)],
            ),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('🐻', style: TextStyle(fontSize: 54)),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '遊客 69ec487e554ce',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _HomeViewState._ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6D83FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '♂ 18',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE6F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'ID:795684',
                      style: TextStyle(
                        color: _HomeViewState._pink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.copy_rounded,
                    color: _HomeViewState._pink,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0AAB0)),
      ],
    );
  }
}

class _MembershipCard extends StatelessWidget {
  final bool subscribed;
  final int remainingFree;
  final VoidCallback onTap;

  const _MembershipCard({
    required this.subscribed,
    required this.remainingFree,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 106,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: subscribed
                ? const [Color(0xFFFF467C), Color(0xFFB248E8)]
                : const [Color(0xFFFFA6C5), Color(0xFFE4D3FF)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22FF467C),
              blurRadius: 22,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    subscribed ? '會員' : '非會員',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subscribed ? '已解鎖所有回覆' : '今日還可回覆 $remainingFree 次',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xF2FFFFFF),
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                subscribed ? '會員' : '升級 Pro',
                style: const TextStyle(
                  color: _HomeViewState._ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<Widget> children;

  const _MenuSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0DDE7)),
      ),
      child: Column(children: children),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String title;
  final String? trailing;
  final bool copy;
  final VoidCallback onTap;

  const _MenuRow({
    required this.title,
    required this.onTap,
    this.trailing,
    this.copy = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _HomeViewState._ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (trailing != null)
              Flexible(
                child: Text(
                  trailing!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: _HomeViewState._muted,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              copy ? Icons.copy_rounded : Icons.chevron_right_rounded,
              color: const Color(0xFFAAA5AB),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AppBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem('首頁', Icons.home_rounded),
    _NavItem('盲盒交友', Icons.help_rounded),
    _NavItem('消息', Icons.chat_bubble_rounded),
    _NavItem('我的', Icons.face_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.82)),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14FF5C82),
                  blurRadius: 26,
                  offset: Offset(0, -10),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final selected = index == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 34,
                          height: 30,
                          decoration: BoxDecoration(
                            color: selected
                                ? _HomeViewState._hotPink.withValues(
                                    alpha: 0.12,
                                  )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            item.icon,
                            color: selected
                                ? _HomeViewState._hotPink
                                : const Color(0xFFC8BEC9),
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          style: TextStyle(
                            color: selected
                                ? _HomeViewState._hotPink
                                : const Color(0xFF9B8F9B),
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w900
                                : FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyboardTone {
  final String emoji;
  final String title;
  final ReplyStyle style;

  const _KeyboardTone(this.emoji, this.title, this.style);
}

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem(this.label, this.icon);
}
