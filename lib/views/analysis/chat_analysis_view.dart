import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/paywall/paywall_view.dart';

class ChatAnalysisView extends StatefulWidget {
  final int initialTab;

  const ChatAnalysisView({super.key, this.initialTab = 0});

  @override
  State<ChatAnalysisView> createState() => _ChatAnalysisViewState();
}

class _ChatAnalysisViewState extends State<ChatAnalysisView>
    with SingleTickerProviderStateMixin {
  final _chatLogController = TextEditingController();
  final _singleMsgController = TextEditingController();
  late TabController _tabController;

  // Local state for message interpretation
  String? _interpretation;
  bool _isInterpreting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _chatLogController.dispose();
    _singleMsgController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
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

    final ai = context.read<AiService>();
    final result = await ai.analyzeChat(text);
    if (result != null) {
      await usage.recordUsage();
    }
  }

  Future<void> _interpretMessage() async {
    final text = _singleMsgController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先輸入對方的訊息')),
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

    setState(() => _isInterpreting = true);

    final ai = context.read<AiService>();
    final result = await ai.interpretMessage(text);
    if (result != null) {
      await usage.recordUsage();
      if (mounted) {
        setState(() => _interpretation = result);
      }
    }
    if (mounted) {
      setState(() => _isInterpreting = false);
    }
  }

  Color _interestColor(int level) {
    // Cold blue → warm orange → hot red
    if (level <= 3) return const Color(0xFF3B82F6); // blue
    if (level <= 5) return const Color(0xFFFBBF24); // amber
    if (level <= 7) return const Color(0xFFF97316); // orange
    return const Color(0xFFEF4444); // red
  }

  String _interestLabel(int level) {
    if (level <= 2) return '冰冷';
    if (level <= 4) return '微溫';
    if (level <= 6) return '溫暖';
    if (level <= 8) return '火熱';
    return '沸騰';
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiService>();
    final analysis = ai.chatAnalysis;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 聊天分析'),
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
            Tab(text: '🌡️ 聊天溫度計'),
            Tab(text: '🤔 她到底什麼意思'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Chat Thermometer ─────────────────────────────
          _buildThermometerTab(context, ai, analysis),

          // ── Tab 2: Message Interpreter ──────────────────────────
          _buildInterpreterTab(context, ai),
        ],
      ),
    );
  }

  Widget _buildThermometerTab(
      BuildContext context, AiService ai, dynamic analysis) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('貼上聊天紀錄',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          TextField(
            controller: _chatLogController,
            maxLines: 8,
            maxLength: AppConstants.maxInputLength,
            decoration: const InputDecoration(
              hintText:
                  '把你們的聊天紀錄貼在這裡...\n\n例如：\n我：今天天氣真好\n她：對啊，好想出去走走',
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ── Analyze Button ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: ai.isLoading ? null : _analyze,
              icon: ai.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.thermostat_rounded),
              label: Text(ai.isLoading ? '分析中...' : '開始分析'),
            ),
          ),

          if (ai.error != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Text(ai.error!,
                style: const TextStyle(color: AppTheme.error)),
          ],

          // ── Analysis Results ──────────────────────────────────
          if (analysis != null) ...[
            const SizedBox(height: AppTheme.spacingXl),

            // Visual Thermometer
            _buildVisualThermometer(context, analysis.interestLevel)
                .animate()
                .fadeIn()
                .scale(begin: const Offset(0.8, 0.8)),

            const SizedBox(height: AppTheme.spacingLg),

            // Attitude
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('對方態度',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(analysis.attitude,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 200)),

            const SizedBox(height: AppTheme.spacingMd),

            // Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('分析摘要',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(analysis.summary,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.6)),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 300)),

            const SizedBox(height: AppTheme.spacingMd),

            // Recommended Next Actions
            Text('建議的下一步',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSm),
            ...analysis.suggestions.asMap().entries.map(
                  (e) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                          color:
                              AppTheme.accent.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${e.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(
                          delay: Duration(
                              milliseconds: 400 + (e.key as int) * 100))
                      .fadeIn()
                      .slideX(begin: 0.15),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildInterpreterTab(BuildContext context, AiService ai) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header illustration
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  const Color(0xFFEC4899).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              children: [
                const Icon(Icons.psychology_rounded,
                    size: 48, color: Color(0xFF8B5CF6)),
                const SizedBox(height: 8),
                Text(
                  '她到底什麼意思？',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '貼上對方的曖昧訊息，AI 幫你解讀真實含義',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ).animate().fadeIn(),

          const SizedBox(height: AppTheme.spacingMd),

          Text('對方的訊息',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),
          TextField(
            controller: _singleMsgController,
            maxLines: 4,
            maxLength: AppConstants.maxInputLength,
            decoration: const InputDecoration(
              hintText: '例如：「我最近都好忙喔」\n「你人很好耶」\n「改天再約吧」',
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isInterpreting ? null : _interpretMessage,
              icon: _isInterpreting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.psychology_rounded),
              label: Text(_isInterpreting ? '解讀中...' : '解讀訊息'),
            ),
          ),

          if (ai.error != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Text(ai.error!,
                style: const TextStyle(color: AppTheme.error)),
          ],

          // ── Interpretation Result ──────────────────────────────
          if (_interpretation != null) ...[
            const SizedBox(height: AppTheme.spacingXl),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                    const Color(0xFFEC4899).withValues(alpha: 0.08),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(
                  color: const Color(0xFF8B5CF6)
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_rounded,
                          color: Color(0xFF8B5CF6), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'AI 解讀',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _interpretation!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.7),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn()
                .slideY(begin: 0.1),
          ],
        ],
      ),
    );
  }

  Widget _buildVisualThermometer(BuildContext context, int level) {
    final color = _interestColor(level);
    final label = _interestLabel(level);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.03),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('聊天溫度計',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          // Thermometer visualization
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Thermometer bar
                SizedBox(
                  width: 40,
                  height: 180,
                  child: CustomPaint(
                    painter: _ThermometerPainter(
                      level: level,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Level display
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$level',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1,
                      ),
                    ),
                    Text(
                      '/10',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: color.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Color scale legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xFF3B82F6), '冰冷'),
              const SizedBox(width: 12),
              _legendDot(const Color(0xFFFBBF24), '微溫'),
              const SizedBox(width: 12),
              _legendDot(const Color(0xFFF97316), '溫暖'),
              const SizedBox(width: 12),
              _legendDot(const Color(0xFFEF4444), '火熱'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

// ── Thermometer Painter ─────────────────────────────────────────────────
class _ThermometerPainter extends CustomPainter {
  final int level;
  final Color color;

  _ThermometerPainter({required this.level, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF3B82F6),
          const Color(0xFFFBBF24),
          const Color(0xFFF97316),
          const Color(0xFFEF4444),
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final tubeWidth = size.width * 0.5;
    final bulbRadius = size.width * 0.5;
    final tubeLeft = (size.width - tubeWidth) / 2;
    final tubeTop = 0.0;
    final tubeBottom = size.height - bulbRadius;
    final tubeHeight = tubeBottom - tubeTop;

    // Background tube
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tubeLeft, tubeTop, tubeWidth, tubeHeight),
      Radius.circular(tubeWidth / 2),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Background bulb
    canvas.drawCircle(
      Offset(size.width / 2, tubeBottom),
      bulbRadius,
      bgPaint,
    );

    // Fill level
    final fillHeight = (tubeHeight * level / 10).clamp(0.0, tubeHeight);
    final fillTop = tubeBottom - fillHeight;

    // Fill tube
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tubeLeft, fillTop, tubeWidth, fillHeight),
      Radius.circular(tubeWidth / 2),
    );
    canvas.drawRRect(fillRect, fillPaint);

    // Fill bulb (always filled)
    canvas.drawCircle(
      Offset(size.width / 2, tubeBottom),
      bulbRadius,
      fillPaint,
    );

    // Level marks
    final markPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    for (int i = 1; i <= 10; i++) {
      final y = tubeBottom - (tubeHeight * i / 10);
      final markLeft = tubeLeft - 4;
      final markRight = tubeLeft;
      canvas.drawLine(
        Offset(markLeft, y),
        Offset(markRight, y),
        markPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ThermometerPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.color != color;
  }
}
