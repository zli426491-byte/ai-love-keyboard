import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/paywall/paywall_view.dart';

class EmojiSuggesterView extends StatefulWidget {
  const EmojiSuggesterView({super.key});

  @override
  State<EmojiSuggesterView> createState() => _EmojiSuggesterViewState();
}

class _EmojiSuggesterViewState extends State<EmojiSuggesterView> {
  final _messageController = TextEditingController();
  List<Map<String, String>>? _suggestions;
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _suggestEmojis() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先輸入訊息')),
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
    final result = await ai.suggestEmojis(text);
    if (result.isNotEmpty) {
      await usage.recordUsage();
      if (mounted) {
        setState(() => _suggestions = result);
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _copyEmojis(String emojis) {
    Clipboard.setData(ClipboardData(text: emojis));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已複製表情符號')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('😊 表情符號建議'),
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
                    const Color(0xFFFBBF24).withValues(alpha: 0.1),
                    const Color(0xFFEC4899).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  const Text('😊😍🥰', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text(
                    '表情符號推薦',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '輸入訊息，AI 幫你搭配最適合的表情組合',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: AppTheme.spacingMd),

            Text('你想傳的訊息',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _messageController,
              maxLines: 3,
              maxLength: AppConstants.maxInputLength,
              decoration: const InputDecoration(
                hintText: '例如：今天見面很開心',
              ),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed:
                    (_isLoading || ai.isLoading) ? null : _suggestEmojis,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.emoji_emotions_rounded),
                label: Text(_isLoading ? '生成中...' : '推薦表情'),
              ),
            ),

            if (ai.error != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Text(ai.error!,
                  style: const TextStyle(color: AppTheme.error)),
            ],

            if (_suggestions != null) ...[
              const SizedBox(height: AppTheme.spacingXl),
              Text('推薦表情',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppTheme.spacingSm),
              ..._suggestions!.asMap().entries.map(
                    (e) => _EmojiGroupCard(
                      label: e.value['label'] ?? '',
                      emojis: e.value['emojis'] ?? '',
                      onCopy: () =>
                          _copyEmojis(e.value['emojis'] ?? ''),
                      index: e.key,
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmojiGroupCard extends StatelessWidget {
  final String label;
  final String emojis;
  final VoidCallback onCopy;
  final int index;

  const _EmojiGroupCard({
    required this.label,
    required this.emojis,
    required this.onCopy,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCopy,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emojis,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.copy_rounded,
                    color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn()
        .slideX(begin: 0.1);
  }
}
