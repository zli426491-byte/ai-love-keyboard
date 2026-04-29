import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/views/paywall/paywall_view.dart';

class OpenerView extends StatefulWidget {
  const OpenerView({super.key});

  @override
  State<OpenerView> createState() => _OpenerViewState();
}

class _OpenerViewState extends State<OpenerView> {
  final _contextController = TextEditingController();

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
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
    final results =
        await ai.generateOpeners(_contextController.text.trim());
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
        title: const Text('💬 破冰開場白'),
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
            Text(
              '對方的資訊（選填）',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _contextController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '交友 App 名稱、對方自介、興趣等...\n留空也能生成通用開場白',
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
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(ai.isLoading ? '生成中...' : '生成開場白'),
              ),
            ),

            if (ai.error != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Text(ai.error!,
                  style: const TextStyle(color: AppTheme.error)),
            ],

            if (ai.openers.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingXl),
              Text('推薦開場白',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppTheme.spacingMd),
              ...ai.openers.asMap().entries.map((entry) {
                final opener = entry.value;
                return Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.only(bottom: AppTheme.spacingMd),
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull),
                            ),
                            child: Text(
                              opener['type'] ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accentDark,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded,
                                size: 18, color: AppTheme.primary),
                            onPressed: () =>
                                _copy(opener['text'] ?? ''),
                            tooltip: '複製',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        opener['text'] ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(height: 1.5),
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
