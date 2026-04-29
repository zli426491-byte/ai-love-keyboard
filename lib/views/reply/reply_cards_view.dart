import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:ai_love_keyboard/models/reply_style.dart';
import 'package:ai_love_keyboard/services/ai_service.dart';
import 'package:ai_love_keyboard/services/usage_service.dart';
import 'package:ai_love_keyboard/utils/app_theme.dart';
import 'package:ai_love_keyboard/views/components/particle_background.dart';

class ReplyCardsView extends StatelessWidget {
  final String originalMessage;
  final ReplyStyle style;

  const ReplyCardsView({
    super.key,
    required this.originalMessage,
    required this.style,
  });

  Future<void> _regenerate(BuildContext context) async {
    final usage = context.read<UsageService>();
    if (!usage.canUse) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('今日免費次數已用完，請升級 PRO')),
      );
      return;
    }

    final ai = context.read<AiService>();
    final replies = await ai.generateReplies(originalMessage, style);
    if (replies.isNotEmpty) {
      await usage.recordUsage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiService>();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AI 回覆結果',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // ── Background gradient ─────────────────────────────────
          Positioned(
            top: -80,
            left: -50,
            right: -50,
            height: 250,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    Color(0x30AB47BC),
                    Color(0x15FF80AB),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const ParticleBackground(particleCount: 12),

          Column(
            children: [
              // ── Original message bubble ─────────────────────────
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(AppTheme.spacingMd),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '對方的訊息',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textHint,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      originalMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

              // ── Reply cards ─────────────────────────────────────
              Expanded(
                child: ai.isLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                                color: AppTheme.accent),
                            const SizedBox(height: 16),
                            Text(
                              'AI 正在思考最佳回覆...',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMd),
                        itemCount: ai.replies.length,
                        itemBuilder: (context, index) {
                          final reply = ai.replies[index];
                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: AppTheme.spacingMd),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusLg),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha: 0.07),
                                    borderRadius:
                                        BorderRadius.circular(
                                            AppTheme.radiusLg),
                                    border: Border.all(
                                      color: reply.style.color
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(
                                      AppTheme.spacingMd),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Style badge + copy button
                                      Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 10,
                                                    vertical: 4),
                                            decoration: BoxDecoration(
                                              color: reply.style.color
                                                  .withValues(
                                                      alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppTheme
                                                          .radiusFull),
                                            ),
                                            child: Text(
                                              reply.style.displayName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color:
                                                    reply.style.color,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () {
                                              Clipboard.setData(
                                                  ClipboardData(
                                                      text:
                                                          reply.text));
                                              ScaffoldMessenger.of(
                                                      context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: const Text(
                                                      '已複製到剪貼簿'),
                                                  backgroundColor:
                                                      AppTheme.primary,
                                                  behavior:
                                                      SnackBarBehavior
                                                          .floating,
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                                AppTheme
                                                                    .radiusMd),
                                                  ),
                                                  duration:
                                                      const Duration(
                                                          seconds: 1),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                gradient: AppTheme
                                                    .romanticGradient,
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                            AppTheme
                                                                .radiusFull),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme
                                                        .accent
                                                        .withValues(
                                                            alpha:
                                                                0.3),
                                                    blurRadius: 8,
                                                  ),
                                                ],
                                              ),
                                              child: const Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.copy_rounded,
                                                    size: 14,
                                                    color:
                                                        Colors.white,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '複製',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.white,
                                                      fontWeight:
                                                          FontWeight
                                                              .w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                          height: AppTheme.spacingMd),
                                      Text(
                                        reply.text,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: AppTheme.textPrimary,
                                          height: 1.6,
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
                                      milliseconds: index * 150))
                              .fadeIn()
                              .slideY(
                                begin: 0.15,
                                duration:
                                    const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                              );
                        },
                      ),
              ),

              // ── Regenerate button ───────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: ai.isLoading
                          ? null
                          : () => _regenerate(context),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFEC4899),
                              Color(0xFFAB47BC),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEC4899)
                                  .withValues(alpha: 0.4),
                              blurRadius: 16,
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
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            else
                              const Icon(Icons.refresh_rounded,
                                  color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              '重新生成',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '換一種方式，讓他更好的答案',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
