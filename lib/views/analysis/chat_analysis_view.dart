import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/utils/constants.dart';
import 'package:ai_love_keyboard/views/paywall/paywall_view.dart';
import 'package:ai_love_keyboard/views/components/particle_background.dart';

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
    if (level <= 3) return const Color(0xFF3B82F6);
    if (level <= 5) return const Color(0xFFFBBF24);
    if (level <= 7) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  String _interestLabel(int level) {
    if (level <= 2) return '\u{1F9CA} 冰冷';
    if (level <= 4) return '\u{2600}\u{FE0F} 微溫';
    if (level <= 6) return '\u{1F525} 溫暖';
    if (level <= 8) return '\u{1F525} 火熱';
    return '\u{1F4A5} 沸騰';
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiService>();
    final analysis = ai.chatAnalysis;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '\u{1F4CA} 聊天分析',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textHint,
          tabs: const [
            Tab(text: '\u{1F321}\u{FE0F} 聊天溫度計'),
            Tab(text: '\u{1F914} 她到底什麼意思'),
          ],
        ),
      ),
      body: Stack(
        children: [
          const ParticleBackground(particleCount: 12),
          TabBarView(
            controller: _tabController,
            children: [
              _buildThermometerTab(context, ai, analysis),
              _buildInterpreterTab(context, ai),
            ],
          ),
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
          // Glassmorphism text field
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: TextField(
                  controller: _chatLogController,
                  maxLines: 8,
                  maxLength: AppConstants.maxInputLength,
                  style:
                      const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText:
                        '把你們的聊天紀錄貼在這裡...\n\n例如：\n我：今天天氣真好\n她：對啊，好想出去走走',
                    hintStyle:
                        const TextStyle(color: AppTheme.textHint),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Analyze button
          GestureDetector(
            onTap: ai.isLoading ? null : _analyze,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFAB47BC)],
                ),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899)
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (ai.isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  else
                    const Icon(Icons.thermostat_rounded,
                        color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    ai.isLoading ? '分析中...' : '開始分析',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (ai.error != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Text(ai.error!,
                style: const TextStyle(color: AppTheme.error)),
          ],

          // ── Analysis Results ────────────────────────────────
          if (analysis != null) ...[
            const SizedBox(height: AppTheme.spacingXl),

            // Circular gauge
            _buildCircularGauge(context, analysis.interestLevel)
                .animate()
                .fadeIn()
                .scale(begin: const Offset(0.8, 0.8)),

            const SizedBox(height: AppTheme.spacingLg),

            // Attitude card
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusLg),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(
                        AppTheme.radiusLg),
                    border: Border.all(
                      color:
                          Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text('態度分析',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          )),
                      const SizedBox(height: 4),
                      Text(analysis.attitude,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                            height: 1.5,
                          )),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(
                delay: const Duration(milliseconds: 200)),

            const SizedBox(height: AppTheme.spacingMd),

            // Summary
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusLg),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(
                        AppTheme.radiusLg),
                    border: Border.all(
                      color:
                          Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text('分析摘要',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          )),
                      const SizedBox(height: 4),
                      Text(analysis.summary,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.6,
                          )),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(
                delay: const Duration(milliseconds: 300)),

            const SizedBox(height: AppTheme.spacingLg),

            // Suggestions
            const Text('建議的下一步',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                )),
            const SizedBox(height: AppTheme.spacingSm),
            ...analysis.suggestions.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                          AppTheme.radiusLg),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: 8, sigmaY: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.06),
                            borderRadius:
                                BorderRadius.circular(
                                    AppTheme.radiusLg),
                            border: Border.all(
                              color: AppTheme.accent
                                  .withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  gradient: AppTheme
                                      .romanticGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${e.key + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w700,
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
                                    color:
                                        AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate(
                          delay: Duration(
                              milliseconds:
                                  400 + (e.key as int) * 100))
                      .fadeIn()
                      .slideX(begin: 0.15),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircularGauge(BuildContext context, int level) {
    final color = _interestColor(level);
    final label = _interestLabel(level);

    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gauge ring
            CustomPaint(
              size: const Size(200, 200),
              painter: _CircularGaugePainter(
                level: level,
                color: color,
              ),
            ),
            // Center text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$level',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
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
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterpreterTab(BuildContext context, AiService ai) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.psychology_rounded,
                        size: 48, color: Color(0xFF8B5CF6)),
                    const SizedBox(height: 8),
                    const Text(
                      '她到底什麼意思？',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '貼上對方的曖昧訊息，AI 幫你解讀真實含義',
                      style: TextStyle(
                          color: AppTheme.textHint, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(),

          const SizedBox(height: AppTheme.spacingMd),

          Text('對方的訊息',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSm),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: TextField(
                  controller: _singleMsgController,
                  maxLines: 4,
                  maxLength: AppConstants.maxInputLength,
                  style: const TextStyle(
                      color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText:
                        '例如：「我最近都好忙喔」\n「你人很好耶」\n「改天再約吧」',
                    hintStyle: const TextStyle(
                        color: AppTheme.textHint),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          GestureDetector(
            onTap: _isInterpreting ? null : _interpretMessage,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                ),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6)
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isInterpreting)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  else
                    const Icon(Icons.psychology_rounded,
                        color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isInterpreting ? '解讀中...' : '解讀訊息',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (ai.error != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Text(ai.error!,
                style: const TextStyle(color: AppTheme.error)),
          ],

          if (_interpretation != null) ...[
            const SizedBox(height: AppTheme.spacingXl),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusLg),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(
                        AppTheme.radiusLg),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6)
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_rounded,
                              color: Color(0xFF8B5CF6),
                              size: 20),
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
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
          ],
        ],
      ),
    );
  }
}

// ── Circular Gauge Painter ────────────────────────────────────────────
class _CircularGaugePainter extends CustomPainter {
  final int level;
  final Color color;

  _CircularGaugePainter({required this.level, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      bgPaint,
    );

    // Gradient arc
    final sweepAngle = (math.pi * 1.5) * (level / 10.0);

    // Gradient: blue -> yellow -> orange -> red
    final gradientShader = SweepGradient(
      startAngle: math.pi * 0.75,
      endAngle: math.pi * 2.25,
      colors: const [
        Color(0xFF3B82F6),
        Color(0xFFFBBF24),
        Color(0xFFF97316),
        Color(0xFFEF4444),
      ],
      stops: const [0.0, 0.33, 0.66, 1.0],
    ).createShader(
      Rect.fromCircle(center: center, radius: radius),
    );

    final fillPaint = Paint()
      ..shader = gradientShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      sweepAngle,
      false,
      fillPaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      sweepAngle,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.color != color;
  }
}
