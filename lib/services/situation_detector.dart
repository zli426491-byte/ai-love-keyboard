import 'package:ai_love_keyboard/models/situation_package.dart';

class SituationDetector {
  SituationDetector._();
  static final SituationDetector instance = SituationDetector._();

  static const Map<SituationType, List<String>> _keywords = {
    SituationType.argument: [
      '吵架', '生氣', '不理我', '冷戰', '道歉', '發脾氣', '鬧彆扭', '氣死',
      '很煩', '吵起來', '大吵', '翻臉', '不開心', '惹怒', '賭氣',
      'angry', 'fight', 'mad', 'sorry', 'argue', 'upset',
    ],
    SituationType.breakup: [
      '分手', '分開', '不要了', '結束', '離開', '放手', '算了', '不愛了',
      '復合', '挽回', '前任', '放不下', '割捨', '失戀',
      'breakup', 'break up', 'ex', 'over', 'done', 'leave',
    ],
    SituationType.confession: [
      '告白', '喜歡', '表白', '暗示', '暗戀', '心動', '表明心意', '鼓起勇氣',
      '說出口', '開口', '白月光',
      'confess', 'crush', 'like you', 'feelings',
    ],
    SituationType.escalation: [
      '曖昧', '進一步', '約出來', '牽手', '更近', '發展', '推進',
      '關係升溫', '撩', '進展', '突破', '約會', '深入',
      'flirt', 'next step', 'date', 'closer',
    ],
    SituationType.leftOnRead: [
      '已讀不回', '不回', '消失', '不讀', '不回訊息', '不理', '讀了不回',
      '沒回應', '石沉大海', '失蹤', '人間蒸發',
      'ghost', 'ghosted', 'no reply', 'left on read', 'ignored',
    ],
  };

  /// Analyzes user input text for emotional keywords.
  /// Returns the detected [SituationType] or null if none matched.
  SituationType? detect(String text) {
    final lower = text.toLowerCase();

    // Check each situation type and count keyword matches
    SituationType? bestMatch;
    int bestCount = 0;

    for (final entry in _keywords.entries) {
      int count = 0;
      for (final keyword in entry.value) {
        if (lower.contains(keyword.toLowerCase())) {
          count++;
        }
      }
      if (count > bestCount) {
        bestCount = count;
        bestMatch = entry.key;
      }
    }

    // Require at least one keyword match
    return bestCount > 0 ? bestMatch : null;
  }
}
