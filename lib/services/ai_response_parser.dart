import 'dart:convert';

/// Parses the OpenAI-compatible response returned by the LoveKey Worker.
///
/// Keeping this logic outside [AiService] makes malformed and empty backend
/// responses deterministic to test without issuing a paid model request.
class AiResponseParser {
  AiResponseParser._();

  static String extractContent(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map) {
      throw const FormatException('AI response must be an object');
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('AI response has no choices');
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map) {
      throw const FormatException('AI choice must be an object');
    }
    final message = firstChoice['message'];
    if (message is! Map) {
      throw const FormatException('AI choice has no message');
    }

    final content = message['content'];
    if (content is String && content.trim().isNotEmpty) {
      return content;
    }
    if (content is List) {
      final text = content
          .whereType<Map>()
          .map((block) => block['text'])
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .join('\n');
      if (text.isNotEmpty) return text;
    }

    throw const FormatException('AI message content is empty or invalid');
  }

  static Map<String, dynamic> decodeJsonObject(String content) {
    var jsonText = content.trim();
    if (jsonText.startsWith('```')) {
      jsonText = jsonText.replaceAll(RegExp(r'^```\w*\n?'), '');
      jsonText = jsonText.replaceAll(RegExp(r'\n?```$'), '');
    }
    final decoded = jsonDecode(jsonText.trim());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('AI JSON response must be an object');
    }
    return decoded;
  }
}
