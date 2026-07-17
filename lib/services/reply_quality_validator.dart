/// Fast client-side gate for a generated reply before it reaches the UI.
///
/// The backend prompt remains the primary quality control. This gate only
/// rejects structurally unusable output and must not rewrite user content.
class ReplyQualityValidator {
  ReplyQualityValidator._();

  static const _templateArtifacts = <String>[
    '以下是高情商',
    '高情商的回覆',
    'AI 建議',
    'AI 回覆',
    '建議回覆如下',
    '回覆如下',
    '可以這樣回',
    '作為 AI',
  ];

  static bool isUsable(String text) {
    final value = text.trim();
    if (value.isEmpty || value.length > 240) return false;
    if (value == '回覆內容' || value == 'actual message') return false;
    if (value.startsWith('```') ||
        (value.startsWith('{') && value.endsWith('}'))) {
      return false;
    }

    final compact = value.replaceAll(RegExp(r'\s+'), ' ');
    if (_templateArtifacts.any(compact.contains)) return false;
    return true;
  }
}
