import 'package:flutter/material.dart';
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
  static const _bg = Color(0xFFFFF6FB);
  static const _surface = Color(0xFFFFFFFF);
  static const _ink = Color(0xFF19131F);
  static const _muted = Color(0xFF7A6F82);
  static const _line = Color(0xFFEAD7E9);
  static const _primary = Color(0xFF7C3AED);
  static const _pink = Color(0xFFEC4899);
  static const _soft = Color(0xFFF6E8FF);

  final _messageController = TextEditingController();
  ReplyStyle _selectedStyle = ReplyStyle.warm;
  int _selectedMode = 0;

  static const _modes = [
    _ModeItem('接話', Icons.chat_bubble_rounded),
    _ModeItem('破冰', Icons.auto_awesome_rounded),
    _ModeItem('邀約', Icons.calendar_month_rounded),
    _ModeItem('安撫', Icons.favorite_rounded),
    _ModeItem('自訂', Icons.tune_rounded),
  ];

  static const _styles = [
    _ToneItem(ReplyStyle.warm, '溫柔', Icons.spa_rounded),
    _ToneItem(ReplyStyle.humorous, '幽默', Icons.wb_sunny_rounded),
    _ToneItem(ReplyStyle.flirty, '曖昧', Icons.local_florist_rounded),
    _ToneItem(ReplyStyle.romantic, '深情', Icons.favorite_rounded),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _generateReplies() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      _showSnack('先貼上一句對方訊息');
      return;
    }

    final usage = context.read<UsageService>();
    if (!usage.canUse) {
      _showPaywall();
      return;
    }

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

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: -120,
              right: -90,
              child: _Glow(size: 260, color: Color(0x33EC4899)),
            ),
            const Positioned(
              top: 170,
              left: -130,
              child: _Glow(size: 260, color: Color(0x337C3AED)),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    subscribed: usage.isSubscribed || revenueCat.isSubscribed,
                    onProTap: _showPaywall,
                    onSettingsTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsView()),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    '不用想破頭',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.3,
                      height: 0.98,
                    ),
                  ),
                  const Text(
                    '直接生成一句能貼回去的回覆',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '複製對方訊息，選一種情境和語氣，LoveKey 只給你一個最適合貼回去的答案。',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _InputCard(
                    controller: _messageController,
                    onExample: () {
                      _messageController.text = '我今天真的有點累';
                    },
                  ),
                  const SizedBox(height: 18),
                  _ModeSelector(
                    modes: _modes,
                    selectedIndex: _selectedMode,
                    onChanged: (index) => setState(() => _selectedMode = index),
                  ),
                  const SizedBox(height: 18),
                  _ToneSelector(
                    styles: _styles,
                    selected: _selectedStyle,
                    onChanged: (style) =>
                        setState(() => _selectedStyle = style),
                  ),
                  const SizedBox(height: 22),
                  _PrimaryButton(
                    loading: ai.isLoading,
                    title: ai.isLoading ? '正在生成...' : '生成回覆',
                    onTap: ai.isLoading ? null : _generateReplies,
                  ),
                  const SizedBox(height: 18),
                  _KeyboardCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KeyboardGuideView(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ProCard(
                    remaining: usage.remainingFree,
                    subscribed: usage.isSubscribed || revenueCat.isSubscribed,
                    onTap: _showPaywall,
                  ),
                  const SizedBox(height: 22),
                  const _StepsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool subscribed;
  final VoidCallback onProTap;
  final VoidCallback onSettingsTap;

  const _Header({
    required this.subscribed,
    required this.onProTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'LoveKey',
          style: TextStyle(
            color: _HomeViewState._ink,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onProTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_HomeViewState._primary, _HomeViewState._pink],
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x338B5CF6),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              subscribed ? 'PRO' : '升級',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: onSettingsTap,
          icon: const Icon(Icons.settings_rounded),
          color: _HomeViewState._muted,
        ),
      ],
    );
  }
}

class _InputCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onExample;

  const _InputCard({required this.controller, required this.onExample});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _HomeViewState._surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _HomeViewState._line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '對方訊息',
                style: TextStyle(
                  color: _HomeViewState._muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onExample,
                child: const Text(
                  '換例句',
                  style: TextStyle(
                    color: _HomeViewState._pink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(
              color: _HomeViewState._ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
            decoration: InputDecoration(
              hintText: '貼上她剛剛傳來的話...',
              hintStyle: TextStyle(
                color: _HomeViewState._muted.withValues(alpha: 0.45),
                fontWeight: FontWeight.w700,
              ),
              filled: true,
              fillColor: _HomeViewState._soft,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(22),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final List<_ModeItem> modes;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ModeSelector({
    required this.modes,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: modes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final mode = modes[index];
          final selected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: selected ? _HomeViewState._primary : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? _HomeViewState._primary
                      : _HomeViewState._line,
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x307C3AED),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    mode.icon,
                    size: 18,
                    color: selected ? Colors.white : _HomeViewState._primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    mode.title,
                    style: TextStyle(
                      color: selected ? Colors.white : _HomeViewState._ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ToneSelector extends StatelessWidget {
  final List<_ToneItem> styles;
  final ReplyStyle selected;
  final ValueChanged<ReplyStyle> onChanged;

  const _ToneSelector({
    required this.styles,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: styles.map((tone) {
        final active = tone.style == selected;
        return GestureDetector(
          onTap: () => onChanged(tone.style),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFFFD8EA) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? _HomeViewState._pink : _HomeViewState._line,
                    width: active ? 3 : 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 12,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: Icon(
                  tone.icon,
                  color: active ? _HomeViewState._pink : _HomeViewState._muted,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                tone.title,
                style: TextStyle(
                  color: active ? _HomeViewState._ink : _HomeViewState._muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final bool loading;
  final String title;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.loading,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 62,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_HomeViewState._primary, _HomeViewState._pink],
          ),
          borderRadius: BorderRadius.circular(23),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3AEC4899),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else
              const Icon(Icons.bolt_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyboardCard extends StatelessWidget {
  final VoidCallback onTap;

  const _KeyboardCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: Icons.keyboard_alt_rounded,
      title: '設定鍵盤',
      subtitle: '在 LINE、IG、交友 App 裡直接使用',
      buttonText: '查看教學',
      onTap: onTap,
    );
  }
}

class _ProCard extends StatelessWidget {
  final int remaining;
  final bool subscribed;
  final VoidCallback onTap;

  const _ProCard({
    required this.remaining,
    required this.subscribed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: Icons.workspace_premium_rounded,
      title: subscribed ? 'Pro 已解鎖' : '免費剩餘 $remaining 次',
      subtitle: subscribed
          ? '已解鎖所有語氣與鍵盤 AI 回覆'
          : 'Monthly \$9.99 · Quarterly \$19.99 · Yearly \$39.99',
      buttonText: subscribed ? '已啟用' : '升級 Pro',
      onTap: subscribed ? null : onTap,
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _HomeViewState._line),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _HomeViewState._soft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: _HomeViewState._primary),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _HomeViewState._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onTap,
            child: Text(
              buttonText,
              style: TextStyle(
                color: onTap == null
                    ? _HomeViewState._muted
                    : _HomeViewState._pink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _HomeViewState._line),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '使用方式',
            style: TextStyle(
              color: _HomeViewState._ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          _StepRow(number: '1', text: '複製一則對方訊息'),
          _StepRow(number: '2', text: '選情境與語氣'),
          _StepRow(number: '3', text: '產生一則回覆並貼回聊天'),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _HomeViewState._primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: _HomeViewState._muted,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _ModeItem {
  final String title;
  final IconData icon;

  const _ModeItem(this.title, this.icon);
}

class _ToneItem {
  final ReplyStyle style;
  final String title;
  final IconData icon;

  const _ToneItem(this.style, this.title, this.icon);
}
