import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/views/paywall/paywall_view.dart';

class GreetingsView extends StatefulWidget {
  const GreetingsView({super.key});

  @override
  State<GreetingsView> createState() => _GreetingsViewState();
}

class _GreetingsViewState extends State<GreetingsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStyle = '甜蜜';
  static const _styles = ['甜蜜', '文藝', '搞笑', '浪漫'];

  List<String>? _greetings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

    setState(() {
      _isLoading = true;
      _greetings = null;
    });

    final type = _tabController.index == 0 ? '早安' : '晚安';
    final ai = context.read<AiService>();
    final result = await ai.generateGreetings(type, _selectedStyle);
    if (result.isNotEmpty) {
      await usage.recordUsage();
      if (mounted) {
        setState(() => _greetings = result);
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
    final now = DateTime.now();
    final dateStr = '${now.year}/${now.month}/${now.day}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('🌅 早安晚安'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: '🌅 早安'),
            Tab(text: '🌙 晚安'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date display
            Center(
              child: Text(
                dateStr,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // Style selector
            Text('風格', style: Theme.of(context).textTheme.titleMedium),
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
                label: Text(_isLoading ? '生成中...' : '生成問候語'),
              ),
            ),

            if (ai.error != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Text(ai.error!,
                  style: const TextStyle(color: AppTheme.error)),
            ],

            if (_greetings != null) ...[
              const SizedBox(height: AppTheme.spacingXl),
              ..._greetings!.asMap().entries.map(
                    (e) => _GreetingCard(
                      text: e.value,
                      onCopy: () => _copyText(e.value),
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

class _GreetingCard extends StatelessWidget {
  final String text;
  final VoidCallback onCopy;
  final int index;

  const _GreetingCard({
    required this.text,
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
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.06),
                  AppTheme.accent.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.copy_rounded,
                    color: Colors.grey.shade400, size: 18),
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
