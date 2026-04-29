import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/paywall/paywall_view.dart';

class TopicSuggestionsView extends StatefulWidget {
  const TopicSuggestionsView({super.key});

  @override
  State<TopicSuggestionsView> createState() => _TopicSuggestionsViewState();
}

class _TopicSuggestionsViewState extends State<TopicSuggestionsView> {
  final _chatController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先貼上最近的聊天內容')),
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

    final ai = context.read<AiService>();
    final results = await ai.suggestTopics(text);
    if (results.isNotEmpty) {
      await usage.recordUsage();
    }
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已複製到剪貼簿 📋'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('💡 話題建議'),
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
            Text('最近的聊天內容',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _chatController,
              maxLines: 6,
              maxLength: AppConstants.maxInputLength,
              decoration: const InputDecoration(
                hintText: '貼上你們最近的聊天內容，AI 會根據話題脈絡給出建議...',
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: ai.isLoading ? null : _generate,
                icon: ai.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.lightbulb_rounded),
                label: Text(ai.isLoading ? '分析中...' : '推薦話題'),
              ),
            ),

            if (ai.error != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Text(ai.error!,
                  style: const TextStyle(color: AppTheme.error)),
            ],

            if (ai.topics.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingXl),
              Text('推薦話題',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppTheme.spacingMd),
              ...ai.topics.asMap().entries.map((entry) {
                final topic = entry.value;
                final colors = [
                  AppTheme.primary,
                  const Color(0xFFEC4899),
                  AppTheme.accent,
                  const Color(0xFFF59E0B),
                  const Color(0xFF6366F1),
                ];
                final color = colors[entry.key % colors.length];

                return Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.only(bottom: AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppTheme.radiusLg - 1)),
                        ),
                        child: Text(
                          topic['title'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      // Body
                      Padding(
                        padding:
                            const EdgeInsets.all(AppTheme.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic['explanation'] ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(height: 1.5),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius:
                                          BorderRadius.circular(
                                              AppTheme.radiusSm),
                                    ),
                                    child: Text(
                                      '💬 ${topic['opener'] ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded,
                                      size: 18,
                                      color: AppTheme.primary),
                                  onPressed: () =>
                                      _copy(topic['opener'] ?? ''),
                                  tooltip: '複製',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                    .animate(
                        delay:
                            Duration(milliseconds: entry.key * 120))
                    .fadeIn()
                    .slideY(begin: 0.1);
              }),
            ],
          ],
        ),
      ),
    );
  }
}
