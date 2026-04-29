import 'package:flutter/material.dart';

enum ReplyStyle {
  humorous(
    label: '幽默',
    emoji: '😄',
    description: '用幽默感拉近距離，讓對話充滿笑聲',
    color: Color(0xFFFBBF24),
  ),
  romantic(
    label: '浪漫',
    emoji: '💕',
    description: '溫柔浪漫的語氣，讓對方感受到你的心意',
    color: Color(0xFFEC4899),
  ),
  flirty(
    label: '撩人',
    emoji: '🔥',
    description: '大膽撩人的回覆，快速升溫關係',
    color: Color(0xFFEF4444),
  ),
  cool(
    label: '高冷',
    emoji: '😎',
    description: '保持神祕感，用反差吸引對方注意',
    color: Color(0xFF6366F1),
  );

  const ReplyStyle({
    required this.label,
    required this.emoji,
    required this.description,
    required this.color,
  });

  final String label;
  final String emoji;
  final String description;
  final Color color;

  String get displayName => '$emoji $label';
}
