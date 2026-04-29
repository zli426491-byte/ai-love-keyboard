import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/paywall/paywall_view.dart';

class ReplyScorerView extends StatefulWidget {
  const ReplyScorerView({super.key});

  @override
  State<ReplyScorerView> createState() => _ReplyScorerViewState();
}

class _ReplyScorerViewState extends State<ReplyScorerView> {
  final _theirMsgController = TextEditingController();
  final _yourReplyController = TextEditingController();

  Map<String, dynamic>? _scoreResult;
  bool _isLoading = false;
  bool _isOptimizing = false;

  @override
  void dispose() {
    _theirMsgController.dispose();
    _yourReplyController.dispose();
    super.dispose();
  }

  Future<void> _scoreReply() async {
    final theirMsg = _theirMsgController.text.trim();
    final yourReply = _yourReplyController.text.trim();
    if (theirMsg.isEmpty || yourReply.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入對方訊息和你的回覆')),
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
    final result = await ai.scoreReply(theirMsg, yourReply);
    if (result != null) {
      await usage.recordUsage();
      if (mounted) {
        setState(() => _scoreResult = result);
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _optimizeReply() async {
    if (_scoreResult == null) return;

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

    setState(() => _isOptimizing = true);

    final optimized = _scoreResult!['optimized'] as String?;
    if (optimized != null && optimized.isNotEmpty) {
      _yourReplyController.text = optimized;
      // Re-score with optimized reply
      await _scoreReply();
    }

    if (mounted) {
      setState(() => _isOptimizing = false);
    }
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已複製到剪貼簿')),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppTheme.success;
    if (score >= 60) return const Color(0xFFF59E0B);
    if (score >= 40) return const Color(0xFFF97316);
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('💯 回覆評分'),
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
                    const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    const Color(0xFF2DD4BF).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  const Icon(Icons.grade_rounded,
                      size: 48, color: Color(0xFF8B5CF6)),
                  const SizedBox(height: 8),
                  Text(
                    '回覆評分系統',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI 幫你的回覆打分數，並提供改進建議',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: AppTheme.spacingMd),

            Text('對方的訊息',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _theirMsgController,
              maxLines: 3,
              maxLength: AppConstants.maxInputLength,
              decoration: const InputDecoration(
                hintText: '對方傳了什麼？',
              ),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            Text('你的回覆草稿',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _yourReplyController,
              maxLines: 3,
              maxLength: AppConstants.maxInputLength,
              decoration: const InputDecoration(
                hintText: '你打算怎麼回？',
              ),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed:
                    (_isLoading || ai.isLoading) ? null : _scoreReply,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.grade_rounded),
                label: Text(_isLoading ? '評分中...' : '開始評分'),
              ),
            ),

            if (ai.error != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Text(ai.error!,
                  style: const TextStyle(color: AppTheme.error)),
            ],

            if (_scoreResult != null) ...[
              const SizedBox(height: AppTheme.spacingXl),

              // Total score
              _buildScoreDisplay(context),

              const SizedBox(height: AppTheme.spacingMd),

              // Breakdown
              _buildBreakdown(context),

              const SizedBox(height: AppTheme.spacingMd),

              // Suggestions
              if (_scoreResult!['suggestions'] != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '改進建議',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.accentDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _scoreResult!['suggestions'] as String,
                        style: const TextStyle(
                            fontSize: 13, height: 1.6),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 400)),

              const SizedBox(height: AppTheme.spacingMd),

              // Optimized reply
              if (_scoreResult!['optimized'] != null &&
                  (_scoreResult!['optimized'] as String).isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '優化回覆',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _scoreResult!['optimized'] as String,
                        style: const TextStyle(
                            fontSize: 14, height: 1.6),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _copyText(
                                  _scoreResult!['optimized'] as String),
                              icon:
                                  const Icon(Icons.copy_rounded, size: 16),
                              label: const Text('複製'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isOptimizing
                                  ? null
                                  : _optimizeReply,
                              icon: const Icon(
                                  Icons.auto_fix_high_rounded,
                                  size: 16),
                              label: const Text('套用'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDisplay(BuildContext context) {
    final score = (_scoreResult!['total'] as num?)?.toInt() ?? 0;
    final color = _scoreColor(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$score',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          Text(
            '/100',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildBreakdown(BuildContext context) {
    final categories = <String, int>{
      '吸引力': (_scoreResult!['attraction'] as num?)?.toInt() ?? 0,
      '幽默感': (_scoreResult!['humor'] as num?)?.toInt() ?? 0,
      '真誠度': (_scoreResult!['sincerity'] as num?)?.toInt() ?? 0,
      '話題延續性': (_scoreResult!['continuity'] as num?)?.toInt() ?? 0,
    };

    return Column(
      children: categories.entries.map((e) {
        final color = _scoreColor(e.value);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  e.key,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusFull),
                  child: LinearProgressIndicator(
                    value: e.value / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                child: Text(
                  '${e.value}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: const Duration(milliseconds: 300));
  }
}
