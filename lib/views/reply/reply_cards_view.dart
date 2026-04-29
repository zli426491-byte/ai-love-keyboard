import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/models/reply_style.dart';
import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/views/components/reply_card.dart';

class ReplyCardsView extends StatelessWidget {
  final String originalMessage;
  final ReplyStyle style;

  const ReplyCardsView({
    super.key,
    required this.originalMessage,
    required this.style,
  });

  Future<void> _regenerate(BuildContext context) async {
    final usage = context.read<UsageService>();
    if (!usage.canUse) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('今日免費次數已用完，請升級 PRO')),
      );
      return;
    }

    final ai = context.read<AiService>();
    final replies = await ai.generateReplies(originalMessage, style);
    if (replies.isNotEmpty) {
      await usage.recordUsage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${style.emoji} ${style.label}回覆'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Original message ─────────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppTheme.spacingMd),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '對方的訊息',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  originalMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ).animate().fadeIn(),

          // ── Reply list ───────────────────────────────────────────
          Expanded(
            child: ai.isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primary),
                        SizedBox(height: 16),
                        Text('AI 正在思考最佳回覆...'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd),
                    itemCount: ai.replies.length,
                    itemBuilder: (context, index) {
                      return ReplyCard(
                        reply: ai.replies[index],
                        index: index,
                      );
                    },
                  ),
          ),

          // ── Regenerate button ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: ai.isLoading ? null : () => _regenerate(context),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重新生成'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
