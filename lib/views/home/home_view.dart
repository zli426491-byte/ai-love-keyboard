import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/models/reply_style.dart';
import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/revenuecat_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
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
  static const _ink = Color(0xFF161318);
  static const _muted = Color(0xFF8C838C);
  static const _pink = Color(0xFFFF4F78);
  static const _hotPink = Color(0xFFFF3E7A);
  static const _peach = Color(0xFFFFE3DF);

  final _messageController = TextEditingController();
  int _tabIndex = 0;
  ReplyStyle _selectedStyle = ReplyStyle.warm;

  static const _keyboardStyles = [
    _KeyboardTone('😁', '幽默', ReplyStyle.humorous),
    _KeyboardTone('😉', '高情商', ReplyStyle.intellectual),
    _KeyboardTone('😌', '溫柔', ReplyStyle.warm),
    _KeyboardTone('💞', '曖昧拉扯', ReplyStyle.romantic),
    _KeyboardTone('😀', '智能回覆', ReplyStyle.mature),
    _KeyboardTone('😊', '可愛', ReplyStyle.cute),
    _KeyboardTone('😎', '大男子', ReplyStyle.cool),
    _KeyboardTone('☺️', '撒嬌', ReplyStyle.cute),
    _KeyboardTone('🍷', '甄嬛文學', ReplyStyle.contrast),
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
      _messageController.text = '我今天真的有點累';
    }

    final usage = context.read<UsageService>();
    if (!usage.canUse) {
      _showPaywall();
      return;
    }

    final text = _messageController.text.trim();
    final ai = context.read<AiService>();
    final replies = await ai.generateReplies(text, _selectedStyle);
    if (!mounted) return;

    if (replies.isEmpty) {
      _showSnack('暫時沒有產生成功，請換一句再試');
      return;
    }

    await usage.recordUsage();
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReplyCardsView(originalMessage: text, style: _selectedStyle),
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

  void _copyBusinessEmail() {
    Clipboard.setData(const ClipboardData(text: '362666@gmail.com'));
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

    final pages = [
      _HomeTab(
        controller: _messageController,
        loading: ai.isLoading,
        keyboardStyles: _keyboardStyles,
        onGenerate: () => _generateReplies(),
        onToneTap: (tone) => _generateReplies(style: tone.style),
        onPaywall: _showPaywall,
        onKeyboardGuide: _openKeyboardGuide,
      ),
      _BlindBoxTab(
        onOpen: () => _showSnack('放盲盒功能準備中'),
        onDraw: () => _showSnack('抽盲盒功能準備中'),
        onSettings: _openSettings,
      ),
      _MessagesTab(onHome: () => setState(() => _tabIndex = 0)),
      _ProfileTab(
        subscribed: subscribed,
        onPaywall: _showPaywall,
        onSettings: _openSettings,
        onKeyboardGuide: _openKeyboardGuide,
        onCopyEmail: _copyBusinessEmail,
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
  final TextEditingController controller;
  final bool loading;
  final List<_KeyboardTone> keyboardStyles;
  final VoidCallback onGenerate;
  final ValueChanged<_KeyboardTone> onToneTap;
  final VoidCallback onPaywall;
  final VoidCallback onKeyboardGuide;

  const _HomeTab({
    required this.controller,
    required this.loading,
    required this.keyboardStyles,
    required this.onGenerate,
    required this.onToneTap,
    required this.onPaywall,
    required this.onKeyboardGuide,
  });

  @override
  Widget build(BuildContext context) {
    return _PinkShell(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 58, 24, 128),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SearchAndCrown(controller: controller, onSubmit: onGenerate),
            const SizedBox(height: 30),
            const Center(
              child: Column(
                children: [
                  Text(
                    '30%',
                    style: TextStyle(
                      color: _HomeViewState._ink,
                      fontSize: 60,
                      height: 0.95,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.8,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '聊天親密度',
                    style: TextStyle(
                      color: _HomeViewState._muted,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const _HeartHero(),
            const SizedBox(height: 26),
            _MainCtaButton(loading: loading, onTap: onGenerate),
            const SizedBox(height: 28),
            _FeatureGrid(
              onPaywall: onPaywall,
              onKeyboardGuide: onKeyboardGuide,
            ),
            const SizedBox(height: 18),
            _BlindBanner(onTap: () {}),
            const SizedBox(height: 26),
            Row(
              children: [
                const Text(
                  '我的鍵盤',
                  style: TextStyle(
                    color: _HomeViewState._ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
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
            const SizedBox(height: 14),
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

  const _BlindBoxTab({
    required this.onOpen,
    required this.onDraw,
    required this.onSettings,
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
                const _CoinPill(),
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
              '成功配對 208400 對',
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

  const _MessagesTab({required this.onHome});

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
              subtitle: '此區塊先完成 UI，後續再接配對和金幣流程。',
              icon: Icons.card_giftcard_rounded,
              onTap: onHome,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final bool subscribed;
  final VoidCallback onPaywall;
  final VoidCallback onSettings;
  final VoidCallback onKeyboardGuide;
  final VoidCallback onCopyEmail;

  const _ProfileTab({
    required this.subscribed,
    required this.onPaywall,
    required this.onSettings,
    required this.onKeyboardGuide,
    required this.onCopyEmail,
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
            _MembershipCard(subscribed: subscribed, onTap: onPaywall),
            const SizedBox(height: 34),
            _MenuSection(
              children: [
                _MenuRow(title: '設定語言', trailing: '繁體中文', onTap: onSettings),
              ],
            ),
            const SizedBox(height: 14),
            _MenuSection(
              children: [_MenuRow(title: '系統設定', onTap: onKeyboardGuide)],
            ),
            const SizedBox(height: 14),
            _MenuSection(
              children: [
                _MenuRow(title: '反饋建議', onTap: onSettings),
                _MenuRow(title: '關於我們', onTap: onSettings),
                _MenuRow(
                  title: '商務合作',
                  trailing: '362666@gmail.com',
                  copy: true,
                  onTap: onCopyEmail,
                ),
                _MenuRow(title: '五星好評，鼓勵一下⭐', onTap: onSettings),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE2E6), Color(0xFFFFF7F8), Colors.white],
          stops: [0, 0.46, 1],
        ),
      ),
      child: child,
    );
  }
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
          colors: [Color(0xFFABC1FF), Color(0xFFE9C6FF), Color(0xFFFFE6F4)],
        ),
      ),
      child: child,
    );
  }
}

class _SearchAndCrown extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _SearchAndCrown({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12FF4F78),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 1,
                    style: const TextStyle(
                      color: _HomeViewState._ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '搜尋更多回覆',
                      hintStyle: TextStyle(
                        color: _HomeViewState._muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onSubmitted: (_) => onSubmit(),
                  ),
                ),
                GestureDetector(
                  onTap: onSubmit,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD4E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: _HomeViewState._pink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 18),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12FF4F78),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: _HomeViewState._hotPink,
            size: 32,
          ),
        ),
      ],
    );
  }
}

class _HeartHero extends StatelessWidget {
  const _HeartHero();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 238,
            height: 238,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFFFD0D9)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33FF6686),
                  blurRadius: 42,
                  offset: Offset(0, 22),
                ),
              ],
            ),
          ),
          const Text(
            '♥',
            style: TextStyle(
              color: Color(0xFFFF5B78),
              fontSize: 188,
              height: 0.9,
              shadows: [
                Shadow(color: Color(0x55FFFFFF), blurRadius: 20),
                Shadow(color: Color(0x44FF3E7A), blurRadius: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
          width: 320,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF315F), Color(0xFFFF8D8F)],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44FF4F78),
                blurRadius: 28,
                offset: Offset(0, 16),
              ),
            ],
          ),
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
                const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                loading ? '生成中...' : '體驗戀愛鍵盤',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
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
  final VoidCallback onKeyboardGuide;

  const _FeatureGrid({required this.onPaywall, required this.onKeyboardGuide});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FeatureCard(
            title: '情感老師',
            subtitle: '全天在線解答問題',
            tint: const Color(0xFFFFC4C8),
            icon: Icons.school_rounded,
            onTap: onPaywall,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _FeatureCard(
            title: '文案改寫',
            subtitle: '引起Ta的興趣',
            tint: const Color(0xFFFFE3A3),
            icon: Icons.edit_rounded,
            onTap: onKeyboardGuide,
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color tint;
  final IconData icon;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 116,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tint.withValues(alpha: 0.95), Colors.white],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 18,
              offset: Offset(0, 8),
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
                    title,
                    style: const TextStyle(
                      color: _HomeViewState._hotPink,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _HomeViewState._muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: _HomeViewState._hotPink, size: 38),
          ],
        ),
      ),
    );
  }
}

class _BlindBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _BlindBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 94,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC4D6FF), Color(0xFFFFB7DA)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Text('👦', style: TextStyle(fontSize: 46)),
            Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '盲盒交友',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Color(0x66FF3E7A), blurRadius: 8)],
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '解鎖未知的Ta，擁抱意外的心動',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Spacer(),
            Text('👧', style: TextStyle(fontSize: 46)),
          ],
        ),
      ),
    );
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
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${item.emoji} ${item.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _HomeViewState._ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD45A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFFFFA800),
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '0',
            style: TextStyle(
              color: _HomeViewState._muted,
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
    return SizedBox(
      height: 330,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 284,
            height: 284,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.38),
              border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55FFFFFF),
                  blurRadius: 60,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          Container(
            width: 198,
            height: 188,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD9FB), Color(0xFFD7C1FF)],
              ),
              borderRadius: BorderRadius.circular(34),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x558A6BFF),
                  blurRadius: 34,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '?',
                style: TextStyle(
                  color: Color(0xFFE678D5),
                  fontSize: 92,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const Positioned(
            top: 26,
            right: 54,
            child: Text('😍', style: TextStyle(fontSize: 48)),
          ),
          const Positioned(
            left: 18,
            bottom: 68,
            child: _MiniAvatar(text: '👩'),
          ),
          const Positioned(
            right: 24,
            bottom: 86,
            child: _MiniAvatar(text: '🙈'),
          ),
          const Positioned(
            left: 16,
            top: 86,
            child: Text('✨', style: TextStyle(fontSize: 36)),
          ),
        ],
      ),
    );
  }
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
        color: Colors.white.withValues(alpha: 0.65),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(text, style: const TextStyle(fontSize: 28)),
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
              Row(
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
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'ID:795684',
                      style: TextStyle(
                        color: _HomeViewState._muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Icon(
                    Icons.copy_rounded,
                    color: Color(0xFFB9B9B9),
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
  final VoidCallback onTap;

  const _MembershipCard({required this.subscribed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 106,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFA6ACBC), Color(0xFFD7D5DF)],
          ),
          borderRadius: BorderRadius.circular(28),
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
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subscribed ? '已解鎖所有回覆' : '無限鍵盤回覆',
                    style: const TextStyle(
                      color: Color(0xF2FFFFFF),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                subscribed ? '已開通' : '未開通',
                style: const TextStyle(
                  color: _HomeViewState._ink,
                  fontSize: 18,
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
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
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
            Text(
              title,
              style: const TextStyle(
                color: _HomeViewState._ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
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
      child: Container(
        height: 82,
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 18,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final selected = index == currentIndex;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(index),
              child: SizedBox(
                width: 72,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      color: selected ? Colors.black : const Color(0xFFD0D0D0),
                      size: 29,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.label,
                      maxLines: 1,
                      style: TextStyle(
                        color: selected
                            ? Colors.black
                            : const Color(0xFF9B9B9B),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
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
