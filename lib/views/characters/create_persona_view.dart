import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/models/chat_persona.dart';
import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';

class CreatePersonaView extends StatefulWidget {
  const CreatePersonaView({super.key});

  @override
  State<CreatePersonaView> createState() => _CreatePersonaViewState();
}

class _CreatePersonaViewState extends State<CreatePersonaView> {
  final _nameController = TextEditingController();
  final _personalityController = TextEditingController();
  final _selectedStyles = <String>{};
  String _replyLength = 'medium';
  String? _previewReply;
  bool _isPreviewing = false;

  static const _styleOptions = [
    '溫柔',
    '幽默',
    '直接',
    '文藝',
    '撩人',
    '正經',
  ];

  static const _lengthOptions = {
    'short': '簡短',
    'medium': '適中',
    'long': '詳細',
  };

  static const _emojiOptions = [
    '😊',
    '😎',
    '🌟',
    '💪',
    '🎭',
    '🦊',
    '🐱',
    '🌈',
    '🔮',
    '🎨',
    '🎯',
    '💫',
  ];
  String _selectedEmoji = '😊';

  @override
  void dispose() {
    _nameController.dispose();
    _personalityController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _personalityController.text.trim().isNotEmpty &&
      _selectedStyles.isNotEmpty;

  String get _speakingStyleText => _selectedStyles.join('、');

  String get _lengthHint {
    switch (_replyLength) {
      case 'short':
        return '回覆要簡短精煉，1句話以內';
      case 'long':
        return '回覆可以較長，2-4句話，內容豐富';
      default:
        return '回覆長度適中，1-2句話';
    }
  }

  Future<void> _generatePreview() async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先填寫名稱、性格描述和說話風格')),
      );
      return;
    }

    setState(() {
      _isPreviewing = true;
      _previewReply = null;
    });

    try {
      final ai = context.read<AiService>();
      final persona = _buildPersona();
      final preview = await ai.previewPersonaReply(
        persona: persona,
        sampleMessage: '今天好累喔，上班好煩',
      );
      if (mounted) {
        setState(() {
          _previewReply = preview;
          _isPreviewing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPreviewing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('預覽失敗：$e')),
        );
      }
    }
  }

  ChatPersona _buildPersona() {
    return ChatPersona(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      emoji: _selectedEmoji,
      description: _personalityController.text.trim().length > 20
          ? '${_personalityController.text.trim().substring(0, 20)}...'
          : _personalityController.text.trim(),
      personality: _personalityController.text.trim(),
      speakingStyle: '$_speakingStyleText。$_lengthHint',
      exampleReply: _previewReply ?? '',
      isCustom: true,
    );
  }

  void _savePersona() {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫所有必要欄位')),
      );
      return;
    }
    Navigator.pop(context, _buildPersona());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自訂人設'),
        actions: [
          TextButton(
            onPressed: _isValid ? _savePersona : null,
            child: const Text(
              '儲存',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Emoji Picker ─────────────────────────────────────────
            Text(
              '選擇頭像',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojiOptions.map((emoji) {
                final isSelected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // ── Name ─────────────────────────────────────────────────
            Text(
              '人設名稱',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _nameController,
              maxLength: 10,
              decoration: const InputDecoration(
                hintText: '例如：溫柔學長',
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // ── Personality ──────────────────────────────────────────
            Text(
              '性格描述',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _personalityController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: '描述這個角色的性格特徵...\n例如：溫柔體貼但偶爾會吃醋，喜歡用可愛的方式表達關心',
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // ── Speaking Style Chips ─────────────────────────────────
            Text(
              '說話風格',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _styleOptions.map((style) {
                final isSelected = _selectedStyles.contains(style);
                return FilterChip(
                  label: Text(style),
                  selected: isSelected,
                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.primary,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedStyles.add(style);
                      } else {
                        _selectedStyles.remove(style);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // ── Reply Length ──────────────────────────────────────────
            Text(
              '回覆長度偏好',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              children: _lengthOptions.entries.map((entry) {
                final isSelected = _replyLength == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) =>
                        setState(() => _replyLength = entry.key),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // ── Preview Button ───────────────────────────────────────
            GestureDetector(
              onTap: _isPreviewing ? null : _generatePreview,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isPreviewing)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accent,
                        ),
                      )
                    else
                      const Icon(Icons.preview_rounded,
                          color: AppTheme.accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isPreviewing ? '生成中...' : '預覽回覆效果',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Preview Result ───────────────────────────────────────
            if (_previewReply != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_selectedEmoji,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          '${_nameController.text.trim()} 會這樣回覆：',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '對方說：「今天好累喔，上班好煩」',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _previewReply!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
            ],

            const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
      ),
    );
  }
}
