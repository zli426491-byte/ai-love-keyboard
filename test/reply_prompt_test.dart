import 'package:ai_love_keyboard/services/prompt_templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reply prompt carries platform and goal context', () {
    final prompt = PromptTemplates.replyGeneration(
      '溫柔',
      platform: 'LINE',
      goal: '安慰',
    );

    expect(prompt, contains('情境平台：LINE'));
    expect(prompt, contains('回覆目的：安慰'));
    expect(prompt, contains('有沒有回應對方真正說的內容'));
    expect(prompt, contains('不要捏造不存在的餐廳'));
  });
}
