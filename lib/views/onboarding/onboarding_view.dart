import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/home/home_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  static const _bg = Color(0xFFFFF5F8);
  static const _card = Color(0xFFFFFCFE);
  static const _text = Color(0xFF201722);
  static const _muted = Color(0xFF786873);
  static const _line = Color(0xFFF0DDE7);
  static const _pink = Color(0xFFFF6B9D);
  static const _purple = Color(0xFFC147E9);
  static const _softPink = Color(0xFFFFEAF2);

  final _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingComplete, true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeView()),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _completeOnboarding();
  }

  Future<void> _openSettings() async {
    final uri = Uri.parse('app-settings:com.ailovekeyboard.app');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          SafeArea(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _StepPage(
                  step: 'STEP 1',
                  title: '長按對方訊息\n點「複製」',
                  mock: const _CopyMessageMock(),
                ),
                _StepPage(
                  step: 'STEP 2',
                  title: '長按地球圖示\n切到 LoveKey',
                  mock: const _SwitchKeyboardMock(),
                  footer: _SettingsHint(onTap: _openSettings),
                ),
                const _StepPage(
                  step: 'STEP 3',
                  title: '選語氣\n按填入',
                  mock: _FillReplyMock(),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            right: 18,
            child: TextButton(
              onPressed: _completeOnboarding,
              style: TextButton.styleFrom(
                foregroundColor: _muted,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('跳過'),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.paddingOf(context).bottom + 20,
            child: Column(
              children: [
                _GradientButton(
                  label: _currentPage == 2 ? '開始使用' : '下一步',
                  onTap: _nextPage,
                ),
                const SizedBox(height: 18),
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: const ExpandingDotsEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 3,
                    spacing: 7,
                    dotColor: _line,
                    activeDotColor: _pink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  final String step;
  final String title;
  final Widget mock;
  final Widget? footer;

  const _StepPage({
    required this.step,
    required this.title,
    required this.mock,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 58, 24, 142),
      children: [
        const SizedBox(height: 4),
        mock
            .animate()
            .fadeIn(duration: 360.ms)
            .slideY(begin: 0.06, duration: 420.ms, curve: Curves.easeOutCubic),
        const SizedBox(height: 34),
        Text(
          step,
          style: const TextStyle(
            color: _OnboardingViewState._purple,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            color: _OnboardingViewState._text,
            fontSize: 32,
            height: 1.12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        if (footer != null) ...[const SizedBox(height: 20), footer!],
      ],
    );
  }
}

class _CopyMessageMock extends StatelessWidget {
  const _CopyMessageMock();

  @override
  Widget build(BuildContext context) {
    return _MockShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MessageBubble(text: '我今天好累，回家好了'),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 188,
              padding: const EdgeInsets.all(10),
              decoration: _mockBox(),
              child: Column(
                children: const [
                  _MenuRow(
                    icon: Icons.content_copy_rounded,
                    label: '複製',
                    active: true,
                  ),
                  _MenuRow(icon: Icons.reply_rounded, label: '回覆'),
                  _MenuRow(icon: Icons.near_me_rounded, label: '轉發'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchKeyboardMock extends StatelessWidget {
  const _SwitchKeyboardMock();

  @override
  Widget build(BuildContext context) {
    return _MockShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F1F5),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: _OnboardingViewState._softPink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: _OnboardingViewState._purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: _mockBox(),
                  child: Column(
                    children: const [
                      _KeyboardChoice(label: '繁體注音'),
                      _KeyboardChoice(label: 'English (US)'),
                      _KeyboardChoice(label: 'LoveKey 鍵盤', active: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FillReplyMock extends StatelessWidget {
  const _FillReplyMock();

  @override
  Widget build(BuildContext context) {
    return _MockShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LoveKey',
            style: TextStyle(
              color: _OnboardingViewState._purple,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          const _PastedMessage(text: '我今天真的有點累'),
          const SizedBox(height: 14),
          Row(
            children: const [
              _ToneChip(label: '溫柔', selected: true),
              _ToneChip(label: '幽默'),
              _ToneChip(label: '曖昧'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: _OnboardingViewState._softPink,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _OnboardingViewState._line),
            ),
            child: Row(
              children: const [
                Expanded(
                  child: Text(
                    '先休息，我在。晚點想說話的時候，我陪你慢慢聊。',
                    style: TextStyle(
                      color: _OnboardingViewState._text,
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                _FillButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockShell extends StatelessWidget {
  final Widget child;

  const _MockShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 318),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _OnboardingViewState._card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _OnboardingViewState._line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;

  const _MessageBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECEF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _OnboardingViewState._text,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: active ? _OnboardingViewState._softPink : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: active
                ? _OnboardingViewState._purple
                : _OnboardingViewState._muted,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: active
                  ? _OnboardingViewState._purple
                  : _OnboardingViewState._text,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyboardChoice extends StatelessWidget {
  final String label;
  final bool active;

  const _KeyboardChoice({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: active ? _OnboardingViewState._softPink : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_rounded : Icons.keyboard_rounded,
            size: 17,
            color: active
                ? _OnboardingViewState._purple
                : _OnboardingViewState._muted,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: active
                  ? _OnboardingViewState._purple
                  : _OnboardingViewState._text,
              fontSize: 14,
              fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _PastedMessage extends StatelessWidget {
  final String text;

  const _PastedMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.content_paste_rounded,
            size: 18,
            color: _OnboardingViewState._purple,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _OnboardingViewState._text,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToneChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _ToneChip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 42,
        margin: const EdgeInsets.only(right: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? _OnboardingViewState._purple
              : _OnboardingViewState._card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? _OnboardingViewState._purple
                : _OnboardingViewState._line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _OnboardingViewState._text,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _FillButton extends StatelessWidget {
  const _FillButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_OnboardingViewState._pink, _OnboardingViewState._purple],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Text(
        '填入',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _SettingsHint extends StatelessWidget {
  final VoidCallback onTap;

  const _SettingsHint({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '還沒新增鍵盤？',
          style: TextStyle(
            color: _OnboardingViewState._muted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: _OnboardingViewState._purple,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: const Text('開啟 iPhone 設定'),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_OnboardingViewState._pink, _OnboardingViewState._purple],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _OnboardingViewState._purple.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

BoxDecoration _mockBox() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _OnboardingViewState._line),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
