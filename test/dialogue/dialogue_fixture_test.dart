import 'dart:convert';
import 'dart:io';

import 'package:ai_love_keyboard/services/prompt_templates.dart';
import 'package:ai_love_keyboard/services/reply_quality_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> fixture;
  late List<Map<String, dynamic>> cases;

  setUpAll(() {
    fixture =
        jsonDecode(File('test/fixtures/dialogue_cases.json').readAsStringSync())
            as Map<String, dynamic>;
    cases = (fixture['cases'] as List<dynamic>).cast<Map<String, dynamic>>();
  });

  test('fixture is explicitly mock-only and has at least 50 unique cases', () {
    expect(fixture['evaluation_mode'], 'mock_static');
    expect(fixture['model'], startsWith('mock-'));
    expect(cases.length, greaterThanOrEqualTo(50));
    expect(cases.map((item) => item['id']).toSet().length, cases.length);
  });

  test('fixture covers every required dialogue and failure category', () {
    final categories = cases.map((item) => item['category']).toSet();
    expect(
      categories,
      containsAll({
        'normal',
        'insufficient_data',
        'contradiction',
        'negation',
        'long_context',
        'multi_turn',
        'repeated_question',
        'similar_names',
        'gender_title',
        'date_time',
        'numbers_money',
        'emoji_symbols',
        'blank_short',
        'overlong',
        'api_timeout',
        'api_empty',
        'api_malformed',
        'network_offline',
        'model_refusal',
        'sensitive_high_risk',
      }),
    );
  });

  test('all mock outputs satisfy deterministic expectations', () {
    const artifactTerms = [
      '以下是高情商',
      '高情商的回覆',
      '可以這樣回',
      '作為 AI',
      'TypeError',
      'Exception:',
    ];

    for (final item in cases) {
      final id = item['id'] as String;
      final kind = item['kind'] as String? ?? 'reply';
      final output = (item['mock_output'] as String).trim();
      final expected = (item['must_contain_any'] as List<dynamic>)
          .cast<String>();
      final maxLength = item['max_length'] as int;

      expect(output, isNotEmpty, reason: '$id returned an empty mock output');
      expect(
        output.length,
        lessThanOrEqualTo(maxLength),
        reason: '$id exceeded its UI length budget',
      );
      expect(
        expected.any(output.contains),
        isTrue,
        reason: '$id did not preserve its required context',
      );
      expect(
        artifactTerms.any(output.contains),
        isFalse,
        reason: '$id leaked a model or implementation artifact',
      );
      if (kind == 'reply') {
        expect(
          ReplyQualityValidator.isUsable(output),
          isTrue,
          reason: '$id produced an unusable chat reply',
        );
      }
    }
  });

  test('every mock case has a passing seven-dimension semantic review', () {
    final reviewFixture =
        jsonDecode(
              File(
                'test/fixtures/dialogue_semantic_scores.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final rubric = (reviewFixture['rubric'] as List<dynamic>).cast<String>();
    final threshold = reviewFixture['pass_threshold'] as int;
    final reviews = (reviewFixture['reviews'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final caseIds = cases.map((item) => item['id'] as String).toSet();

    expect(reviewFixture['evaluation_mode'], 'mock_static_human_review');
    expect(rubric.length, 7);
    expect(reviews.length, cases.length);
    expect(reviews.map((item) => item['id'] as String).toSet(), caseIds);

    for (final review in reviews) {
      final id = review['id'] as String;
      final scores = (review['scores'] as List<dynamic>).cast<int>();
      expect(scores.length, rubric.length, reason: '$id rubric mismatch');
      expect(
        scores.every((score) => score >= threshold && score <= 5),
        isTrue,
        reason: '$id has a semantic score below the pass threshold',
      );
      expect(review['failure_reason'], isNull, reason: id);
      expect(review['reproducible'], isTrue, reason: id);
    }
  });

  test('reply prompts retain platform, goal, output, and safety contracts', () {
    for (final item in cases.where(
      (entry) => (entry['kind'] as String? ?? 'reply') == 'reply',
    )) {
      final platform = item['platform'] as String;
      final platformExpectation = switch (platform) {
        'IG' => 'Instagram',
        _ => platform,
      };
      final prompt = PromptTemplates.withSafety(
        PromptTemplates.replyGeneration(
          item['style'] as String,
          platform: platform,
          goal: item['goal'] as String,
        ),
      );

      expect(prompt, contains('安全規則（最高優先級）'), reason: item['id'] as String);
      expect(prompt, contains('只生成 1 則'), reason: item['id'] as String);
      expect(prompt, contains('JSON 格式'), reason: item['id'] as String);
      expect(
        prompt,
        contains(item['goal'] as String),
        reason: item['id'] as String,
      );
      expect(
        prompt,
        contains(platformExpectation),
        reason: item['id'] as String,
      );
      expect(prompt, contains('不要提到 AI'), reason: item['id'] as String);
    }
  });
}
