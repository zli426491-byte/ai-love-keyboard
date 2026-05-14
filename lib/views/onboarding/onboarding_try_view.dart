import 'package:flutter/material.dart';

class OnboardingTryView extends StatefulWidget {
  const OnboardingTryView({super.key});

  @override
  State<OnboardingTryView> createState() => _OnboardingTryViewState();
}

class _OnboardingTryViewState extends State<OnboardingTryView> {
  static const _cream = Color(0xFFFAF7F2);
  static const _card = Color(0xFFFFFCF7);
  static const _forest = Color(0xFF1F3A2E);
  static const _sage = Color(0xFFE7EFE8);
  static const _brown = Color(0xFF8B6F47);
  static const _red = Color(0xFFC8385C);
  static const _text = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF6B6B6B);
  static const _line = Color(0xFFE7DDD0);

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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _cream,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 148),
          children: [
            const Text(
              '試玩一下\n我們的 AI',
              style: TextStyle(
                color: _text,
                fontSize: 36,
                height: 1.02,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '不用先去聊天 App，直接選一句常見訊息，看看鍵盤會怎麼接。',
              style: TextStyle(
                color: _muted,
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            _MessageCard(message: _currentMessage, onNext: _nextMessage),
            const SizedBox(height: 14),
            for (var i = 0; i < _currentReplies.length; i++) ...[
              _ReplyCard(
                text: _currentReplies[i],
                selected: i == 0,
                label: i == 0 ? '主推薦' : '可替換',
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final style in _styles)
                  _ToneChip(
                    text: style,
                    selected: style == _currentStyle,
                    onTap: () => _selectStyle(style),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: _forest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                '試完了，下一步設定鍵盤',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
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
        return ['我先接住這題', '等我切換高情商模式。', '要不要我交一版不尷尬的答案給你?'];
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _OnboardingTryViewState._card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _OnboardingTryViewState._line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onNext,
                child: const Text(
                  '換例句',
                  style: TextStyle(
                    color: _OnboardingTryViewState._red,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF1ECE5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: _OnboardingTryViewState._text,
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: selected
            ? _OnboardingTryViewState._sage
            : _OnboardingTryViewState._card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? _OnboardingTryViewState._forest
              : _OnboardingTryViewState._line,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: selected
                    ? _OnboardingTryViewState._forest
                    : _OnboardingTryViewState._text,
                fontSize: selected ? 15 : 14,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? _OnboardingTryViewState._forest
                  : _OnboardingTryViewState._brown,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToneChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _ToneChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? _OnboardingTryViewState._forest
              : _OnboardingTryViewState._card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? _OnboardingTryViewState._forest
                : _OnboardingTryViewState._line,
          ),
        ),
        child: Text(
          selected ? '$text ✓' : text,
          style: TextStyle(
            color: selected ? Colors.white : _OnboardingTryViewState._muted,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
