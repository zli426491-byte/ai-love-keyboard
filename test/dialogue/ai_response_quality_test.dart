import 'dart:convert';

import 'package:ai_love_keyboard/services/ai_response_parser.dart';
import 'package:ai_love_keyboard/services/reply_quality_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiResponseParser', () {
    test('extracts string content from a valid chat response', () {
      final body = jsonEncode({
        'choices': [
          {
            'message': {'content': '{"replies": ["晚點再慢慢聊。"]}'},
          },
        ],
      });

      expect(AiResponseParser.extractContent(body), '{"replies": ["晚點再慢慢聊。"]}');
    });

    test('joins text blocks returned as structured content', () {
      final body = jsonEncode({
        'choices': [
          {
            'message': {
              'content': [
                {'type': 'text', 'text': '第一段'},
                {'type': 'text', 'text': '第二段'},
              ],
            },
          },
        ],
      });

      expect(AiResponseParser.extractContent(body), '第一段\n第二段');
    });

    test('reports missing choices as a format error', () {
      expect(
        () => AiResponseParser.extractContent('{"choices": []}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('reports empty content as a format error', () {
      expect(
        () => AiResponseParser.extractContent(
          '{"choices":[{"message":{"content":""}}]}',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('decodes fenced JSON objects', () {
      expect(
        AiResponseParser.decodeJsonObject('```json\n{"replies": []}\n```'),
        {'replies': <dynamic>[]},
      );
    });

    test('rejects a JSON array when an object is required', () {
      expect(
        () => AiResponseParser.decodeJsonObject('[]'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ReplyQualityValidator', () {
    test('accepts a natural concise reply', () {
      expect(ReplyQualityValidator.isUsable('笑成這樣，剛剛想到什麼了？'), isTrue);
    });

    test('rejects template and model artifacts', () {
      for (final value in [
        '以下是高情商的回覆：你今天過得好嗎？',
        'AI 建議：先關心她。',
        '可以這樣回：辛苦了。',
        '作為 AI，我建議你先冷靜。',
      ]) {
        expect(ReplyQualityValidator.isUsable(value), isFalse, reason: value);
      }
    });

    test('rejects placeholders, JSON wrappers, and oversized replies', () {
      expect(ReplyQualityValidator.isUsable('回覆內容'), isFalse);
      expect(ReplyQualityValidator.isUsable('{"replies":["你好"]}'), isFalse);
      expect(ReplyQualityValidator.isUsable('哈' * 241), isFalse);
    });
  });
}
