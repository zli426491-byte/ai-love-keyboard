import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/paywall/paywall_view.dart';

class TranslateReplyView extends StatefulWidget {
  const TranslateReplyView({super.key});

  @override
  State<TranslateReplyView> createState() => _TranslateReplyViewState();
}

class _TranslateReplyViewState extends State<TranslateReplyView> {
  final _messageController = TextEditingController();
  String _selectedStyle = '溫暖體貼';
  static const _styles = ['溫暖體貼', '幽默風趣', '浪漫深情', '直接大方'];

  Map<String, String>? _result;
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _translateAndReply() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先貼上對方的外語訊息')),
      );
      return;
    }

    final usage = context.read<UsageService>();
    if (!usage.canUse) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const PaywallView(),
      );
      return;
    }

    setState(() => _isLoading = true);

    final ai = context.read<AiService>();
    final result = await ai.translateAndReply(text, _selectedStyle);
    if (result != null) {
      await usage.recordUsage();
      if (mounted) {
        setState(() => _result = result);
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已複製到剪貼簿')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🌍 跨國翻譯回覆'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.1),
                    const Color(0xFF2DD4BF).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  const Icon(Icons.translate_rounded,
                      size: 48, color: Color(0xFF6366F1)),
                  const SizedBox(height: 8),
                  Text(
                    '跨國戀愛翻譯機',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '貼上外語訊息，AI 翻譯 + 幫你用對方語言回覆',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: AppTheme.spacingMd),

            Text('對方的外語訊息',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _messageController,
              maxLines: 4,
              maxLength: AppConstants.maxInputLength,
              decoration: const InputDecoration(
                hintText: '貼上對方用外語傳的訊息...\n例如："I had a great time last night"',
              ),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // Style selector
            Text('回覆風格', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: 8,
              children: _styles.map((style) {
                final isSelected = style == _selectedStyle;
                return ChoiceChip(
                  label: Text(style),
                  selected: isSelected,
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _selectedStyle = style),
                );
              }).toList(),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // Generate button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: (_isLoading || ai.isLoading)
                    ? null
                    : _translateAndReply,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.translate_rounded),
                label: Text(_isLoading ? '翻譯回覆中...' : '翻譯並生成回覆'),
              ),
            ),

            if (ai.error != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Text(ai.error!,
                  style: const TextStyle(color: AppTheme.error)),
            ],

            // Results
            if (_result != null) ...[
              const SizedBox(height: AppTheme.spacingXl),

              // Translation
              _ResultCard(
                title: '對方的意思（中文翻譯）',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF6366F1),
                content: _result!['translation'] ?? '',
                onCopy: () => _copyText(_result!['translation'] ?? ''),
              ).animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: AppTheme.spacingMd),

              // Reply
              _ResultCard(
                title: '建議回覆（用對方的語言）',
                icon: Icons.chat_bubble_outline_rounded,
                color: const Color(0xFF2DD4BF),
                content: _result!['reply'] ?? '',
                onCopy: () => _copyText(_result!['reply'] ?? ''),
                showCopyProminent: true,
              ).animate().fadeIn(delay: const Duration(milliseconds: 200)).slideY(begin: 0.1),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String content;
  final VoidCallback onCopy;
  final bool showCopyProminent;

  const _ResultCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
    required this.onCopy,
    this.showCopyProminent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy_rounded, color: color, size: 20),
                onPressed: onCopy,
                tooltip: '複製',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(height: 1.6),
          ),
          if (showCopyProminent) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('複製回覆'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
