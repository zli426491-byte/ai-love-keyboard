import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/paywall/paywall_view.dart';

class TimingCoachView extends StatefulWidget {
  const TimingCoachView({super.key});

  @override
  State<TimingCoachView> createState() => _TimingCoachViewState();
}

class _TimingCoachViewState extends State<TimingCoachView> {
  final _chatLogController = TextEditingController();
  String? _analysis;
  bool _isLoading = false;

  @override
  void dispose() {
    _chatLogController.dispose();
    super.dispose();
  }

  Future<void> _analyzeTiming() async {
    final text = _chatLogController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先貼上聊天紀錄')),
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
    final result = await ai.analyzeTiming(text);
    if (result != null) {
      await usage.recordUsage();
      if (mounted) {
        setState(() => _analysis = result);
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('⏰ 聊天節奏教練'),
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
                    const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    const Color(0xFFEF4444).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  const Icon(Icons.timer_rounded,
                      size: 48, color: Color(0xFFF59E0B)),
                  const SizedBox(height: 8),
                  Text(
                    '聊天節奏分析',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '分析回覆時間模式，教你掌握最佳回覆節奏',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: AppTheme.spacingMd),

            Text('貼上聊天紀錄（含時間）',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _chatLogController,
              maxLines: 8,
              maxLength: AppConstants.maxInputLength,
              decoration: const InputDecoration(
                hintText:
                    '貼上包含時間的聊天紀錄...\n\n例如：\n10:30 我：早安\n10:35 她：早安～\n10:36 我：今天天氣好好\n12:00 她：對啊',
              ),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed:
                    (_isLoading || ai.isLoading) ? null : _analyzeTiming,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.timer_rounded),
                label: Text(_isLoading ? '分析中...' : '分析回覆節奏'),
              ),
            ),

            if (ai.error != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Text(ai.error!,
                  style: const TextStyle(color: AppTheme.error)),
            ],

            if (_analysis != null) ...[
              const SizedBox(height: AppTheme.spacingXl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF59E0B).withValues(alpha: 0.08),
                      const Color(0xFFEF4444).withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.insights_rounded,
                            color: Color(0xFFF59E0B), size: 20),
                        SizedBox(width: 8),
                        Text(
                          '節奏分析報告',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _analysis!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.7),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1),
            ],
          ],
        ),
      ),
    );
  }
}
