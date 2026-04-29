import 'package:ai_love_keyboard/models/reply_style.dart';

class AiReply {
  final String id;
  final String text;
  final ReplyStyle style;
  final DateTime createdAt;

  AiReply({
    required this.id,
    required this.text,
    required this.style,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AiReply.fromJson(Map<String, dynamic> json, ReplyStyle style) {
    return AiReply(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] as String,
      style: style,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'style': style.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
