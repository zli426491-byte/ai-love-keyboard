import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ai_love_keyboard/services/analytics_service.dart';

class KeyboardGuideView extends StatelessWidget {
  const KeyboardGuideView({super.key});

  static const _cream = Color(0xFFFAF7F2);
  static const _card = Color(0xFFFFFCF7);
  static const _forest = Color(0xFF1F3A2E);
  static const _sage = Color(0xFFE7EFE8);
  static const _warmYellow = Color(0xFFF5E6B8);
  static const _roseSoft = Color(0xFFF5D6DC);
  static const _navySoft = Color(0xFFD6E0EC);
  static const _brown = Color(0xFF8B6F47);
  static const _red = Color(0xFFC8385C);
  static const _text = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF6B6B6B);
  static const _line = Color(0xFFE7DDD0);

  Future<void> _openSettings() async {
    try {
      AnalyticsService.instance.trackKeyboardEnabled();
    } catch (_) {}
    final uri = Uri.parse('app-settings:com.ailovekeyboard.app');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: _forest,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _sage,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '鍵盤教學',
                    style: TextStyle(
                      color: _forest,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              '先設定一次\n聊天時直接回覆',
              style: TextStyle(
                color: _text,
                fontSize: 34,
                height: 1.05,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '在 LINE、IG、交友 App 裡複製對方訊息，切到 AI 戀愛鍵盤，就能讀取對話並把建議回覆填入輸入框。',
              style: TextStyle(
                color: _muted,
                fontSize: 15,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            const _KeyboardPreview(),
            const SizedBox(height: 20),
            const _FlowCard(),
            const SizedBox(height: 20),
            const _PracticeCard(),
            const SizedBox(height: 20),
            _SetupCard(onOpenSettings: _openSettings),
            const SizedBox(height: 20),
            const _FullAccessCard(),
            const SizedBox(height: 20),
            const _SwitchKeyboardCard(),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings_rounded),
                label: const Text('打開 iPhone 設定'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_rounded),
              label: const Text('我已設定，回 App 測試'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _forest,
                side: const BorderSide(color: _line),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyboardPreview extends StatelessWidget {
  const _KeyboardPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KeyboardGuideView._card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: KeyboardGuideView._line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '聊天 App',
                style: TextStyle(
                  color: KeyboardGuideView._muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                width: 54,
                height: 6,
                decoration: BoxDecoration(
                  color: KeyboardGuideView._line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _ChatBubble(text: '我今天真的有點累，先回家好了', isMine: false),
          const SizedBox(height: 8),
          const _ChatBubble(text: '等我一下，我想好好回你', isMine: true),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KeyboardGuideView._cream,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: KeyboardGuideView._line),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'AI 回覆',
                      style: TextStyle(
                        color: KeyboardGuideView._forest,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '已讀取對話',
                      style: TextStyle(
                        color: KeyboardGuideView._brown.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: KeyboardGuideView._forest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '我已複製，產生 3 句',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    _ToneIcon(
                      label: '溫柔',
                      icon: Icons.eco_rounded,
                      background: KeyboardGuideView._sage,
                      selected: true,
                    ),
                    _ToneIcon(
                      label: '幽默',
                      icon: Icons.wb_sunny_rounded,
                      background: KeyboardGuideView._warmYellow,
                    ),
                    _ToneIcon(
                      label: '曖昧',
                      icon: Icons.favorite_rounded,
                      background: KeyboardGuideView._roseSoft,
                    ),
                    _ToneIcon(
                      label: '道歉',
                      icon: Icons.water_drop_rounded,
                      background: KeyboardGuideView._navySoft,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const _ReplyPreview(text: '辛苦了，先別硬撐，我陪你慢慢放鬆。', selected: true),
                const SizedBox(height: 7),
                const _ReplyPreview(text: '回家先休息，晚點我再陪你聊。'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowCard extends StatelessWidget {
  const _FlowCard();

  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      title: '實際使用只要三步',
      child: Column(
        children: const [
          _GuideStep(
            number: '1',
            title: '複製對方訊息',
            body: '在任何聊天 App 長按訊息，點「複製」。',
          ),
          _GuideDivider(),
          _GuideStep(
            number: '2',
            title: '切到 AI 戀愛鍵盤',
            body: '長按地球圖示，選擇「AI 戀愛鍵盤」。',
          ),
          _GuideDivider(),
          _GuideStep(
            number: '3',
            title: '讀取後點回覆',
            body: '點「我已複製，產生 3 句」，選一句建議，會直接填入輸入框。',
          ),
        ],
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard();

  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      title: '先試一次',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '假裝對方傳了這句，先看 AI 鍵盤會怎麼接。',
            style: TextStyle(
              color: KeyboardGuideView._muted,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          _PracticeBubble(text: '我今天真的有點累，先回家好了'),
          SizedBox(height: 12),
          _PracticeReply(text: '★ 累的話靠近一點，我負責哄你', selected: true),
          SizedBox(height: 8),
          _PracticeReply(text: '今天先別撐了，我接走你的壞心情'),
          SizedBox(height: 8),
          _PracticeReply(text: '你休息，我想你這件事我來負責'),
          SizedBox(height: 12),
          Row(
            children: [
              _ToneIcon(
                label: '溫柔',
                icon: Icons.eco_rounded,
                background: KeyboardGuideView._sage,
                compact: true,
              ),
              _ToneIcon(
                label: '幽默',
                icon: Icons.wb_sunny_rounded,
                background: KeyboardGuideView._warmYellow,
                compact: true,
              ),
              _ToneIcon(
                label: '曖昧',
                icon: Icons.favorite_rounded,
                background: KeyboardGuideView._roseSoft,
                selected: true,
                compact: true,
              ),
              _ToneIcon(
                label: '道歉',
                icon: Icons.water_drop_rounded,
                background: KeyboardGuideView._navySoft,
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  final Future<void> Function() onOpenSettings;

  const _SetupCard({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      title: '第一次開啟鍵盤',
      trailing: TextButton(
        onPressed: onOpenSettings,
        child: const Text(
          '前往設定',
          style: TextStyle(
            color: KeyboardGuideView._red,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: Column(
        children: const [
          _GuideStep(
            number: '1',
            title: '設定 > 一般 > 鍵盤',
            body: '進入「鍵盤」清單後點「新增鍵盤」。',
          ),
          _GuideDivider(),
          _GuideStep(
            number: '2',
            title: '新增 AI 戀愛鍵盤',
            body: '在第三方鍵盤中選擇「AI 戀愛鍵盤」。',
          ),
          _GuideDivider(),
          _GuideStep(
            number: '3',
            title: '允許完整取用',
            body: '剪貼簿讀取需要此權限；不開啟時只能使用固定回覆。',
          ),
        ],
      ),
    );
  }
}

class _FullAccessCard extends StatelessWidget {
  const _FullAccessCard();

  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      title: '為什麼要「完整取用」',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ExplainHeading(text: '開了會怎樣？'),
          SizedBox(height: 10),
          _ExplainRow(text: '讓鍵盤讀到你剛複製的訊息', color: KeyboardGuideView._forest),
          _ExplainRow(text: '才能對訊息生成合適回覆', color: KeyboardGuideView._forest),
          SizedBox(height: 12),
          Divider(color: KeyboardGuideView._line),
          SizedBox(height: 12),
          _ExplainHeading(text: '不開會怎樣？'),
          SizedBox(height: 10),
          _ExplainRow(
            icon: '•',
            text: '只能用 4 種固定模板',
            color: KeyboardGuideView._muted,
          ),
          _ExplainRow(
            icon: '•',
            text: '無法依對方訊息個人化生成',
            color: KeyboardGuideView._muted,
          ),
          SizedBox(height: 12),
          Divider(color: KeyboardGuideView._line),
          SizedBox(height: 12),
          _ExplainHeading(text: '我們的承諾', color: KeyboardGuideView._forest),
          SizedBox(height: 10),
          _ExplainRow(text: '不蒐集你的訊息內容', color: KeyboardGuideView._forest),
          _ExplainRow(text: '目前不上傳到任何伺服器', color: KeyboardGuideView._forest),
          _ExplainRow(text: '處理完成立即丟棄', color: KeyboardGuideView._forest),
        ],
      ),
    );
  }
}

class _ExplainHeading extends StatelessWidget {
  final String text;
  final Color color;

  const _ExplainHeading({
    required this.text,
    this.color = KeyboardGuideView._text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900),
    );
  }
}

class _ExplainRow extends StatelessWidget {
  final String icon;
  final String text;
  final Color color;

  const _ExplainRow({
    required this.text,
    this.icon = '✓',
    this.color = KeyboardGuideView._forest,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              icon,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchKeyboardCard extends StatelessWidget {
  const _SwitchKeyboardCard();

  @override
  Widget build(BuildContext context) {
    return _GuideCard(
      title: '找不到鍵盤時',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '在聊天輸入框叫出鍵盤後，長按左下角地球圖示，選「AI 戀愛鍵盤」。',
            style: TextStyle(
              color: KeyboardGuideView._muted,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 14),
          _KeyboardSwitcherMock(),
        ],
      ),
    );
  }
}

class _KeyboardSwitcherMock extends StatelessWidget {
  const _KeyboardSwitcherMock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KeyboardGuideView._cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KeyboardGuideView._line),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 210,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: KeyboardGuideView._card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KeyboardGuideView._line),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: const [
                  _SwitcherOption(text: '繁體注音'),
                  _SwitcherOption(text: 'English (US)'),
                  _SwitcherOption(text: 'AI 戀愛鍵盤', selected: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 42,
                height: 36,
                decoration: BoxDecoration(
                  color: KeyboardGuideView._forest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: KeyboardGuideView._card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: KeyboardGuideView._line),
                  ),
                  child: const Center(
                    child: Text(
                      '空格',
                      style: TextStyle(
                        color: KeyboardGuideView._muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 54,
                height: 36,
                decoration: BoxDecoration(
                  color: KeyboardGuideView._card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: KeyboardGuideView._line),
                ),
                child: const Center(
                  child: Text(
                    'return',
                    style: TextStyle(
                      color: KeyboardGuideView._muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '長按地球圖示切換',
            style: TextStyle(
              color: KeyboardGuideView._forest,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitcherOption extends StatelessWidget {
  final String text;
  final bool selected;

  const _SwitcherOption({required this.text, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? KeyboardGuideView._sage : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.keyboard_rounded : Icons.language_rounded,
            size: 16,
            color: selected
                ? KeyboardGuideView._forest
                : KeyboardGuideView._muted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: selected
                    ? KeyboardGuideView._forest
                    : KeyboardGuideView._text,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeBubble extends StatelessWidget {
  final String text;

  const _PracticeBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 290),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF1ECE5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: KeyboardGuideView._line),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: KeyboardGuideView._text,
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PracticeReply extends StatelessWidget {
  final String text;
  final bool selected;

  const _PracticeReply({required this.text, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: selected ? KeyboardGuideView._sage : KeyboardGuideView._card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? KeyboardGuideView._forest : KeyboardGuideView._line,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: selected
                    ? KeyboardGuideView._forest
                    : KeyboardGuideView._text,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '填入',
            style: TextStyle(
              color: selected
                  ? KeyboardGuideView._forest
                  : KeyboardGuideView._brown,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToneIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final bool selected;
  final bool compact;

  const _ToneIcon({
    required this.label,
    required this.icon,
    required this.background,
    this.selected = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 38.0 : 42.0;
    final labelSize = compact ? 9.0 : 10.0;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: compact ? 5 : 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: selected ? 1.06 : 1,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: size,
                    height: size,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: background.withValues(alpha: selected ? 1 : 0.78),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? KeyboardGuideView._forest
                            : KeyboardGuideView._forest.withValues(alpha: 0.18),
                        width: selected ? 1.8 : 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: KeyboardGuideView._forest.withValues(
                        alpha: selected ? 1 : 0.72,
                      ),
                      size: compact ? 19 : 21,
                    ),
                  ),
                  if (selected)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 14,
                        height: 14,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: KeyboardGuideView._forest,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? KeyboardGuideView._forest
                    : KeyboardGuideView._muted,
                fontSize: labelSize,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _GuideCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KeyboardGuideView._card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KeyboardGuideView._line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: KeyboardGuideView._text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _GuideStep({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: KeyboardGuideView._sage,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: KeyboardGuideView._forest,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: KeyboardGuideView._text,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(
                  color: KeyboardGuideView._muted,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuideDivider extends StatelessWidget {
  const _GuideDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 15, top: 8, bottom: 8),
      width: 1,
      height: 18,
      color: KeyboardGuideView._line,
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMine;

  const _ChatBubble({required this.text, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? KeyboardGuideView._sage : const Color(0xFFF1ECE5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: KeyboardGuideView._text,
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final String text;
  final bool selected;

  const _ReplyPreview({required this.text, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? KeyboardGuideView._sage : KeyboardGuideView._card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KeyboardGuideView._line),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? KeyboardGuideView._forest : KeyboardGuideView._text,
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
