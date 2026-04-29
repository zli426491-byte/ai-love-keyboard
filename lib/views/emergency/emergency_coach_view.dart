import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/models/coin_system.dart';
import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/coin_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';

class EmergencyCoachView extends StatefulWidget {
  const EmergencyCoachView({super.key});

  @override
  State<EmergencyCoachView> createState() => _EmergencyCoachViewState();
}

class _EmergencyCoachViewState extends State<EmergencyCoachView> {
  final _chatController = TextEditingController();
  String? _analysisResult;
  bool _isAnalyzing = false;
  bool _showResult = false;

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先貼上完整的聊天紀錄')),
      );
      return;
    }

    final coinService = context.read<CoinService>();
    if (!coinService.hasEnoughCoins(CoinCost.emergencyCoach)) {
      _showCoinDialog();
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _showResult = false;
      _analysisResult = null;
    });

    final ai = context.read<AiService>();
    try {
      final result = await ai.analyzeEmergency(text);
      final consumed = await coinService.spendCoins(
          CoinCost.emergencyCoach, '緊急求助 AI 教練');
      if (mounted && consumed) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
          _showResult = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _showCoinDialog() {
    final coinService = context.read<CoinService>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text(
          '金幣不足',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '需要 ${CoinCost.emergencyCoach} \u{1FA99}',
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '目前餘額：${coinService.balance} \u{1FA99}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '使用最強 AI 模型深度分析整段對話，'
              '給你精確的回覆建議和戀愛策略。',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/coin-store');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold,
            ),
            child: const Text('前往金幣商店'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('緊急求助'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<CoinService>(
            builder: (_, coinSvc, child) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/coin-store'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      '\u{1FA99} ${coinSvc.balance}',
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _showResult && _analysisResult != null
          ? _buildResultView()
          : _buildInputView(),
    );
  }

  Widget _buildInputView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: const Column(
              children: [
                Text(
                  '\u{1F6A8}',
                  style: TextStyle(fontSize: 40),
                ),
                SizedBox(height: 8),
                Text(
                  '緊急戀愛教練',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '貼上完整對話，AI 深度分析幫你化解危機',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: const Duration(milliseconds: 400)),

          const SizedBox(height: AppTheme.spacingLg),

          // Instructions
          Text(
            '貼上完整聊天紀錄',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            '包含雙方的所有對話，越完整分析越精準',
            style: TextStyle(
              color: AppTheme.textHint,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // Text input
          TextField(
            controller: _chatController,
            maxLines: 12,
            maxLength: 5000,
            decoration: const InputDecoration(
              hintText: '在此貼上聊天紀錄...\n\n例如：\n我：今天天氣好好\n她：對啊好想出去走走\n我：那我們一起去啊\n她：哈哈再說吧',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Analyze button
          GestureDetector(
            onTap: _isAnalyzing ? null : _startAnalysis,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: _isAnalyzing
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
                      ),
                color: _isAnalyzing ? Colors.grey.shade700 : null,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: _isAnalyzing
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFFEF4444)
                              .withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Center(
                child: _isAnalyzing
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            '正在深度分析...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        '開始深度分析 ${CoinCost.emergencyCoach} \u{1FA99}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Info chips
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.psychology, label: '最強 AI 模型'),
              _InfoChip(icon: Icons.analytics, label: '深度心理分析'),
              _InfoChip(icon: Icons.message, label: '精確回覆建議'),
              _InfoChip(icon: Icons.timer, label: '時機策略'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expert report header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: const Column(
              children: [
                Icon(Icons.verified_rounded, color: Colors.white, size: 32),
                SizedBox(height: 8),
                Text(
                  '專家分析報告',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '由 AI 戀愛教練深度分析',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ).animate().fadeIn(duration: const Duration(milliseconds: 400)),

          const SizedBox(height: AppTheme.spacingMd),

          // Analysis result
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: SelectableText(
              _analysisResult!,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                height: 1.8,
              ),
            ),
          ).animate().fadeIn(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 500),
              ),

          const SizedBox(height: AppTheme.spacingMd),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: _analysisResult!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已複製分析報告')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('複製報告'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showResult = false;
                      _analysisResult = null;
                      _chatController.clear();
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('再次分析'),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgCardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
