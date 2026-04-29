import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/paywall/paywall_view.dart';

class ArgumentResolveView extends StatefulWidget {
  const ArgumentResolveView({super.key});

  @override
  State<ArgumentResolveView> createState() => _ArgumentResolveViewState();
}

class _ArgumentResolveViewState extends State<ArgumentResolveView> {
  final _chatLogController = TextEditingController();
  String _selectedTone = '認錯型';
  static const _tones = ['認錯型', '解釋型', '撒嬌型', '冷靜型'];
  static const _toneIcons = ['🙏', '💬', '🥺', '🧊'];

  String? _result;
  bool _isLoading = false;

  @override
  void dispose() {
    _chatLogController.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    final text = _chatLogController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先貼上吵架紀錄')),
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
    final result = await ai.resolveArgument(text, _selectedTone);
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
        title: const Text('🕊️ 吵架和好模式'),
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
                    const Color(0xFF10B981).withValues(alpha: 0.1),
                    const Color(0xFF6366F1).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  const Icon(Icons.healing_rounded,
                      size: 48, color: Color(0xFF10B981)),
                  const SizedBox(height: 8),
                  Text(
                    '吵架和好神器',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '貼上吵架訊息，AI 幫你分析並生成和好訊息',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: AppTheme.spacingMd),

            Text('貼上吵架紀錄',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _chatLogController,
              maxLines: 8,
              maxLength: AppConstants.maxInputLength,
              decoration: const InputDecoration(
                hintText: '貼上你們吵架的對話...\n\n例如：\n她：你怎麼又忘記了\n我：我真的太忙了\n她：你每次都這樣說',
              ),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            Text('和好語氣', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: 8,
              children: List.generate(_tones.length, (i) {
                final isSelected = _tones[i] == _selectedTone;
                return ChoiceChip(
                  label: Text('${_toneIcons[i]} ${_tones[i]}'),
                  selected: isSelected,
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) =>
                      setState(() => _selectedTone = _tones[i]),
                );
              }),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed:
                    (_isLoading || ai.isLoading) ? null : _resolve,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.healing_rounded),
                label: Text(_isLoading ? '分析中...' : '分析並生成和好訊息'),
              ),
            ),

            if (ai.error != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Text(ai.error!,
                  style: const TextStyle(color: AppTheme.error)),
            ],

            if (_result != null) ...[
              const SizedBox(height: AppTheme.spacingXl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0.08),
                      const Color(0xFF6366F1).withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.healing_rounded,
                            color: Color(0xFF10B981), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'AI 和好建議',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _result!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.7),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _copyText(_result!),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('複製和好訊息'),
                      ),
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
