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
  ),
  warm(
    label: '暖男',
    emoji: '🤗',
    description: '溫柔體貼，讓對方感受到被在乎',
    color: Color(0xFFF97316),
  ),
  intellectual(
    label: '知性',
    emoji: '🧠',
    description: '聰明有深度，展現你的內涵',
    color: Color(0xFF0EA5E9),
  ),
  naughty(
    label: '壞壞的',
    emoji: '😈',
    description: '調皮挑逗，帶點小壞增加吸引力',
    color: Color(0xFFA855F7),
  ),
  cute(
    label: '可愛',
    emoji: '🌸',
    description: '軟萌撒嬌，讓對方覺得你超可愛',
    color: Color(0xFFF472B6),
  ),
  mature(
    label: '成熟',
    emoji: '💼',
    description: '穩重有安全感，展現大人的魅力',
    color: Color(0xFF64748B),
  ),
  contrast(
    label: '反差萌',
    emoji: '🎭',
    description: '正經中帶幽默，意想不到的可愛反差',
    color: Color(0xFF14B8A6),
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
