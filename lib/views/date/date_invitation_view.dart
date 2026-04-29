import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/paywall/paywall_view.dart';

class DateInvitationView extends StatefulWidget {
  const DateInvitationView({super.key});

  @override
  State<DateInvitationView> createState() => _DateInvitationViewState();
}

class _DateInvitationViewState extends State<DateInvitationView> {
  final _contextController = TextEditingController();
  String _selectedStyle = '隨性自然';
  static const _styles = ['隨性自然', '浪漫約會', '創意驚喜'];

  List<Map<String, String>>? _invitations;
  bool _isLoading = false;

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final text = _contextController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先輸入對方的資訊')),
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
    final result =
        await ai.generateDateInvitation(text, _selectedStyle);
    if (result.isNotEmpty) {
      await usage.recordUsage();
      if (mounted) {
        setState(() => _invitations = result);
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
        title: const Text('💌 約會邀請'),
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
                    const Color(0xFFEC4899).withValues(alpha: 0.1),
                    const Color(0xFF9333EA).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  const Icon(Icons.favorite_rounded,
                      size: 48, color: Color(0xFFEC4899)),
                  const SizedBox(height: 8),
                  Text(
                    '約會邀請產生器',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '根據對方喜好，生成完美的約會邀約訊息',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: AppTheme.spacingMd),

            Text('關於對方的資訊',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _contextController,
              maxLines: 4,
              maxLength: AppConstants.maxInputLength,
              decoration: const InputDecoration(
                hintText: '例如：她喜歡看電影和吃日本料理，住台北，預算中等',
              ),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            Text('約會風格', style: Theme.of(context).textTheme.titleMedium),
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
                  onSelected: (_) =>
                      setState(() => _selectedStyle = style),
                );
              }).toList(),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed:
                    (_isLoading || ai.isLoading) ? null : _generate,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(_isLoading ? '生成中...' : '生成約會邀請'),
              ),
            ),

            if (ai.error != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Text(ai.error!,
                  style: const TextStyle(color: AppTheme.error)),
            ],

            if (_invitations != null) ...[
              const SizedBox(height: AppTheme.spacingXl),
              ..._invitations!.asMap().entries.map(
                    (e) => _InvitationCard(
                      place: e.value['place'] ?? '',
                      time: e.value['time'] ?? '',
                      message: e.value['message'] ?? '',
                      onCopy: () =>
                          _copyText(e.value['message'] ?? ''),
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

class _InvitationCard extends StatelessWidget {
  final String place;
  final String time;
  final String message;
  final VoidCallback onCopy;
  final int index;

  const _InvitationCard({
    required this.place,
    required this.time,
    required this.message,
    required this.onCopy,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: const Color(0xFFEC4899).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: const Color(0xFFEC4899).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '方案 ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.place_rounded,
                  size: 16, color: Color(0xFFEC4899)),
              const SizedBox(width: 4),
              Text(place,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 16, color: Color(0xFFEC4899)),
              const SizedBox(width: 4),
              Text(time,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('複製邀請訊息'),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 150))
        .fadeIn()
        .slideY(begin: 0.1);
  }
}
