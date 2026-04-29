enum UserGender {
  male(
    label: '男生',
    emoji: '👨',
    description: '我是男生，想追女生',
    promptHint: '你是一位幫助男生追求女生的戀愛顧問。回覆要展現男性魅力，自信但不油膩。',
  ),
  female(
    label: '女生',
    emoji: '👩',
    description: '我是女生，想吸引男生',
    promptHint: '你是一位幫助女生吸引男生的戀愛顧問。回覆要展現女性魅力，可愛但有個性。',
  );

  const UserGender({
    required this.label,
    required this.emoji,
    required this.description,
    required this.promptHint,
  });

  final String label;
  final String emoji;
  final String description;
  final String promptHint;

  String get displayName => '$emoji $label';
}
