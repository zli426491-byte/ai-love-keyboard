import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/models/reply_style.dart';
import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/analysis/chat_analysis_view.dart';
import 'package:ai_love_keyboard/views/components/style_selector.dart';
import 'package:ai_love_keyboard/views/components/usage_indicator.dart';
import 'package:ai_love_keyboard/views/opener/opener_view.dart';
import 'package:ai_love_keyboard/views/paywall/paywall_view.dart';
import 'package:ai_love_keyboard/views/reply/reply_cards_view.dart';
import 'package:ai_love_keyboard/views/settings/settings_view.dart';
import 'package:ai_love_keyboard/views/topics/topic_suggestions_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _messageController = TextEditingController();
  ReplyStyle _selectedStyle = ReplyStyle.humorous;
  String _selectedPlatform = '交友App';
  static const _platforms = ['交友App', 'LINE', 'IG'];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _generateReplies() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先輸入對方的訊息')),
      );
      return;
    }

    final usage = context.read<UsageService>();
    if (!usage.canUse) {
      _showPaywall();
      return;
    }

    final ai = context.read<AiService>();
    final replies = await ai.generateReplies(text, _selectedStyle);

    if (replies.isNotEmpty) {
      await usage.recordUsage();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReplyCardsView(
              originalMessage: text,
              style: _selectedStyle,
            ),
          ),
        );
      }
    }
  }

  void _showPaywall() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiService>();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd,
                  AppTheme.spacingMd,
                  AppTheme.spacingMd,
                  0,
                ),
                child: Row(
                  children: [
                    Text(
                      '💜 ${AppConstants.appName}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    const UsageIndicator(),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsView()),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Platform Selector ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd,
                  AppTheme.spacingMd,
                  AppTheme.spacingMd,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '情境模式',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Row(
                      children: _platforms.map((platform) {
                        final isSelected = platform == _selectedPlatform;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              platform == '交友App'
                                  ? '💘 交友App'
                                  : platform == 'LINE'
                                      ? '💬 LINE'
                                      : '📸 IG',
                            ),
                            selected: isSelected,
                            selectedColor: AppTheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : null,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) =>
                                setState(() => _selectedPlatform = platform),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: const Duration(milliseconds: 400)),
            ),

            // ── Message Input ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '對方傳了什麼？',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextField(
                      controller: _messageController,
                      maxLines: 4,
                      maxLength: AppConstants.maxInputLength,
                      decoration: const InputDecoration(
                        hintText: '貼上對方的訊息...',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: const Duration(milliseconds: 500)),
              ),
            ),

            // ── Style Selector ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd),
                    child: Text(
                      '選擇回覆風格',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  StyleSelector(
                    selected: _selectedStyle,
                    onSelected: (s) => setState(() => _selectedStyle = s),
                  ),
                ],
              ),
            ),

            // ── Generate Button ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: _GradientButton(
                  onTap: ai.isLoading ? null : _generateReplies,
                  isLoading: ai.isLoading,
                  label: '生成回覆 ✨',
                ),
              ),
            ),

            // ── Error Message ───────────────────────────────────────
            if (ai.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ai.error!,
                            style: const TextStyle(
                                color: AppTheme.error, fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: ai.clearError,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Quick Actions ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '更多功能',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // ── Row 1: Analysis features ───────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.thermostat_rounded,
                            label: '聊天溫度計',
                            subtitle: '分析對方興趣度',
                            color: const Color(0xFFEC4899),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ChatAnalysisView()),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.psychology_rounded,
                            label: '她到底什麼意思',
                            subtitle: '解讀曖昧訊息',
                            color: const Color(0xFF8B5CF6),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ChatAnalysisView(
                                        initialTab: 1,
                                      )),
                            ),
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(
                          delay: const Duration(milliseconds: 300),
                          duration: const Duration(milliseconds: 500),
                        ),

                    const SizedBox(height: AppTheme.spacingMd),

                    // ── Row 2: Conversation starters ───────────────
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.chat_bubble_outline,
                            label: '破冰開場白',
                            subtitle: '打破沉默',
                            color: const Color(0xFF6366F1),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const OpenerView()),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.lightbulb_outline,
                            label: '話題建議',
                            subtitle: '聊什麼好？',
                            color: AppTheme.accent,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const TopicSuggestionsView()),
                            ),
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(
                          delay: const Duration(milliseconds: 400),
                          duration: const Duration(milliseconds: 500),
                        ),
                  ],
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingXl),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gradient Button ─────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final String label;

  const _GradientButton({
    required this.onTap,
    required this.isLoading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: onTap != null ? AppTheme.primaryGradient : null,
          color: onTap == null ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Quick Action Card ───────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
