import 'package:flutter/material.dart';

class OnboardingTryView extends StatefulWidget {
  const OnboardingTryView({super.key});

  @override
  State<OnboardingTryView> createState() => _OnboardingTryViewState();
}

class _OnboardingTryViewState extends State<OnboardingTryView> {
  static const _cream = Color(0xFFFFF6FA);
  static const _card = Color(0xFFFFFFFF);
  static const _forest = Color(0xFFFF4F78);
  static const _sage = Color(0xFFFFEAF2);
  static const _warmYellow = Color(0xFFFFF0C8);
  static const _roseSoft = Color(0xFFFFD7E5);
  static const _navySoft = Color(0xFFE9DDFF);
  static const _brown = Color(0xFFC147E9);
  static const _red = Color(0xFFFF3E7A);
  static const _text = Color(0xFF201722);
  static const _muted = Color(0xFF786873);
  static const _line = Color(0xFFF0DDE7);

  final _demoMessages = const [
    '我今天真的有點累',
    '你假日都做什麼？',
    '隨便啦你決定',
    '晚上要吃什麼',
    '我覺得我們不太適合',
  ];

  final _styles = const ['溫柔', '幽默', '曖昧', '道歉'];

  int _messageIndex = 0;
  String _currentStyle = '曖昧';

  String get _currentMessage => _demoMessages[_messageIndex];

  List<String> get _currentReplies =>
      _generateReplies(_currentStyle, _currentMessage);

  void _nextMessage() {
    setState(() => _messageIndex = (_messageIndex + 1) % _demoMessages.length);
  }

  void _selectStyle(String style) {
    setState(() => _currentStyle = style);
  }

  IconData _toneIcon(String style) {
    switch (style) {
      case '幽默':
        return Icons.wb_sunny_rounded;
      case '曖昧':
        return Icons.favorite_rounded;
      case '道歉':
        return Icons.water_drop_rounded;
      case '溫柔':
      default:
        return Icons.eco_rounded;
    }
  }

  Color _toneBackground(String style) {
    switch (style) {
      case '幽默':
        return _warmYellow;
      case '曖昧':
        return _roseSoft;
      case '道歉':
        return _navySoft;
      case '溫柔':
      default:
        return _sage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _cream,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 132),
          children: [
            const Text(
              '先試一句\nAI 幫你接話',
              style: TextStyle(
                color: _text,
                fontSize: 32,
                height: 1.08,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '選一句常見訊息，切換語氣，立刻看 AI 怎麼幫你回。',
              style: TextStyle(
                color: _muted,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _MessageCard(message: _currentMessage, onNext: _nextMessage),
            const SizedBox(height: 12),
            _ToneSelector(
              styles: _styles,
              currentStyle: _currentStyle,
              iconForStyle: _toneIcon,
              backgroundForStyle: _toneBackground,
              onSelect: _selectStyle,
            ),
            const SizedBox(height: 18),
            const Text(
              'AI 建議回覆',
              style: TextStyle(
                color: _text,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            for (var i = 0; i < _currentReplies.length; i++) ...[
              _ReplyCard(
                text: _currentReplies[i],
                selected: i == 0,
                label: i == 0 ? '主推薦' : '可替換',
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _generateReplies(String style, String message) {
    final text = message.trim();
    final isQuestion = _containsAny(text, [
      '?',
      '？',
      '嗎',
      '是不是',
      '要不要',
      '怎麼',
      '什麼',
    ]);
    final isFood = _containsAny(text, ['吃', '喝', '晚餐', '午餐', '火鍋', '咖啡']);
    final isTired = _containsAny(text, ['累', '忙', '煩', '壓力', '不舒服', '睡']);
    final isNegative = _containsAny(text, [
      '隨便',
      '算了',
      '不用',
      '沒差',
      '生氣',
      '不適合',
    ]);

    switch (style) {
      case '幽默':
        if (isFood) {
          return ['胃先答應了', '今天讓晚餐替我們主持公道。', '要不要直接出發，我負責不讓氣氛冷掉?'];
        }
        if (isTired) {
          return ['先開省電模式', '你今天唯一任務是躺平。', '要不要先休息，我晚點再帶笑話來報到?'];
        }
        if (isNegative) {
          return ['我先收起嘴砲', '這題不能亂答，我認真一點。', '要不要給我一次補考，我想把話講好?'];
        }
        return ['我懂你的意思', '那我先不亂猜，照你現在方便的節奏來。', '你想先聊輕鬆一點，還是我認真陪你想?'];
      case '曖昧':
        if (isFood) {
          return ['想坐妳旁邊', '吃什麼都行，重點是跟妳一起。', '要不要我帶妳去那家，妳上次說想吃的?'];
        }
        if (isTired) {
          return ['靠近一點吧', '今天別撐了，我想接走妳的壞心情。', '要不要休息一下，我晚點再溫柔地吵妳?'];
        }
        if (isQuestion) {
          return ['如果是妳我願意', '妳這樣問，我會忍不住多想。', '要不要讓我用行動回答，比文字更清楚?'];
        }
        return ['有點想妳了', '妳一句話就把我的注意力帶走。', '要不要晚點聊，我想把今天留一點給妳?'];
      case '道歉':
        if (isNegative) {
          return ['我剛剛沒做好', '先不辯解，我想把你的感受聽完。', '要不要給我一點時間，我會把態度改給你看?'];
        }
        return ['是我沒顧好', '我想把話說清楚，也顧到你。', '要不要讓我重新說一次，這次我會更小心?'];
      case '溫柔':
      default:
        if (isFood) {
          return ['就吃這個', '我來找時間，今天不用你費心。', '那我們吃完再散步一下，好不好?'];
        }
        if (isTired) {
          return ['先休息，我在', '今天別硬撐，把力氣留給自己。', '晚點想說話的時候，我陪你慢慢聊好嗎?'];
        }
        if (isQuestion) {
          return ['我認真想了', '這題我會先照顧你的感受。', '要不要我先說我的想法，再一起決定?'];
        }
        return ['我有放在心上', '這句我不會隨便帶過。', '要不要慢慢說，我想把你的意思聽完整?'];
    }
  }

  bool _containsAny(String text, List<String> needles) {
    return needles.any(text.contains);
  }
}

class _MessageCard extends StatelessWidget {
  final String message;
  final VoidCallback onNext;

  const _MessageCard({required this.message, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: _OnboardingTryViewState._card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _OnboardingTryViewState._line.withValues(alpha: 0.82),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 30,
            offset: const Offset(0, 16),
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
                  color: _OnboardingTryViewState._muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onNext,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '換例句',
                  style: TextStyle(
                    color: _OnboardingTryViewState._red,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: _OnboardingTryViewState._text,
                fontSize: 17,
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

class _ToneSelector extends StatelessWidget {
  final List<String> styles;
  final String currentStyle;
  final IconData Function(String style) iconForStyle;
  final Color Function(String style) backgroundForStyle;
  final ValueChanged<String> onSelect;

  const _ToneSelector({
    required this.styles,
    required this.currentStyle,
    required this.iconForStyle,
    required this.backgroundForStyle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: _OnboardingTryViewState._card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _OnboardingTryViewState._line.withValues(alpha: 0.78),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '選擇語氣',
            style: TextStyle(
              color: _OnboardingTryViewState._muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              for (final style in styles)
                _ToneIconButton(
                  label: style,
                  icon: iconForStyle(style),
                  background: backgroundForStyle(style),
                  selected: style == currentStyle,
                  onTap: () => onSelect(style),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReplyCard extends StatelessWidget {
  final String text;
  final bool selected;
  final String label;

  const _ReplyCard({
    required this.text,
    required this.selected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: selected
            ? _OnboardingTryViewState._sage
            : _OnboardingTryViewState._card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? _OnboardingTryViewState._forest.withValues(alpha: 0.52)
              : _OnboardingTryViewState._line.withValues(alpha: 0.76),
          width: selected ? 1.2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 38,
            decoration: BoxDecoration(
              color: selected
                  ? _OnboardingTryViewState._forest
                  : _OnboardingTryViewState._line,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: selected
                    ? _OnboardingTryViewState._forest
                    : _OnboardingTryViewState._text,
                fontSize: 14,
                height: 1.35,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? _OnboardingTryViewState._forest
                  : _OnboardingTryViewState._brown.withValues(alpha: 0.78),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToneIconButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final bool selected;
  final VoidCallback onTap;

  const _ToneIconButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: background.withValues(alpha: selected ? 1 : 0.78),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? _OnboardingTryViewState._forest
                            : _OnboardingTryViewState._forest.withValues(
                                alpha: 0.18,
                              ),
                        width: selected ? 1.5 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: _OnboardingTryViewState._forest
                                    .withValues(alpha: 0.10),
                                blurRadius: 12,
                                offset: const Offset(0, 7),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      icon,
                      color: _OnboardingTryViewState._forest.withValues(
                        alpha: selected ? 1 : 0.68,
                      ),
                      size: 21,
                    ),
                  ),
                  if (selected)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 15,
                        height: 15,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: _OnboardingTryViewState._forest,
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
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? _OnboardingTryViewState._forest
                    : _OnboardingTryViewState._muted,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
