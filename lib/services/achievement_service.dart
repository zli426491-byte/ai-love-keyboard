import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/models/achievement.dart';

class AchievementService extends ChangeNotifier {
  static const String _prefKey = 'achievements_data';
  static const String _prefStreakKey = 'achievement_streak';
  static const String _prefStreakDateKey = 'achievement_streak_date';
  static const String _prefStylesUsedKey = 'achievement_styles_used';

  List<Achievement> _achievements = [];
  bool _initialized = false;

  /// Most recently unlocked achievement (for celebration UI).
  Achievement? _recentlyUnlocked;

  bool get initialized => _initialized;
  List<Achievement> get achievements => List.unmodifiable(_achievements);
  Achievement? get recentlyUnlocked => _recentlyUnlocked;

  /// Number of unclaimed/recently unlocked achievements.
  int get unclaimedCount =>
      _achievements.where((a) => a.isComplete && !a.isUnlocked).length;

  /// Total unlocked achievements.
  int get unlockedCount => _achievements.where((a) => a.isUnlocked).length;

  Future<void> init() async {
    _achievements = Achievement.allAchievements();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      for (final item in decoded) {
        final json = item as Map<String, dynamic>;
        final id = json['id'] as String?;
        if (id == null) continue;
        final match = _achievements.where((a) => a.id == id);
        if (match.isNotEmpty) {
          match.first.loadFromJson(json);
        }
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _achievements.map((a) => a.toJson()).toList();
    await prefs.setString(_prefKey, jsonEncode(data));
  }

  /// Clear the recently unlocked achievement after showing celebration.
  void clearRecentlyUnlocked() {
    _recentlyUnlocked = null;
  }

  /// Record a reply generation event.
  Future<void> recordReplyGenerated() async {
    await _incrementProgress('chat_beginner', 1);
    await _incrementProgress('reply_master', 1);
    await _checkStreak();
    await _checkLoveMaster();
  }

  /// Record a chat analysis event.
  Future<void> recordAnalysisUsed() async {
    await _incrementProgress('analysis_expert', 1);
    await _checkLoveMaster();
  }

  /// Record a date invitation event.
  Future<void> recordDateInvitationUsed() async {
    await _incrementProgress('date_success', 1);
    await _checkLoveMaster();
  }

  /// Record a translation event.
  Future<void> recordTranslateUsed() async {
    await _incrementProgress('international', 1);
    await _checkLoveMaster();
  }

  /// Record a style being used.
  Future<void> recordStyleUsed(String styleName) async {
    final prefs = await SharedPreferences.getInstance();
    final stylesUsed =
        prefs.getStringList(_prefStylesUsedKey)?.toSet() ?? <String>{};
    stylesUsed.add(styleName);
    await prefs.setStringList(_prefStylesUsedKey, stylesUsed.toList());

    final styleAchievement =
        _achievements.where((a) => a.id == 'style_master');
    if (styleAchievement.isNotEmpty) {
      styleAchievement.first.progress = stylesUsed.length;
      if (styleAchievement.first.isComplete &&
          !styleAchievement.first.isUnlocked) {
        _recentlyUnlocked = styleAchievement.first;
      }
      await _save();
      notifyListeners();
    }
    await _checkLoveMaster();
  }

  /// Unlock an achievement (claim reward).
  Future<void> unlockAchievement(String achievementId) async {
    final match = _achievements.where((a) => a.id == achievementId);
    if (match.isEmpty) return;

    final achievement = match.first;
    if (!achievement.isComplete) return;

    achievement.isUnlocked = true;
    await _save();
    notifyListeners();
    await _checkLoveMaster();
  }

  /// Get unlocked achievements.
  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();

  /// Check daily streak.
  Future<void> _checkStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString(_prefStreakDateKey) ?? '';
    var streak = prefs.getInt(_prefStreakKey) ?? 0;

    if (lastDate == today) {
      // Already recorded today
      return;
    }

    final lastDateTime = lastDate.isNotEmpty ? DateTime.parse(lastDate) : null;
    final todayDate = DateTime.parse(today);

    if (lastDateTime != null &&
        todayDate.difference(lastDateTime).inDays == 1) {
      // Consecutive day
      streak++;
    } else if (lastDateTime == null ||
        todayDate.difference(lastDateTime).inDays > 1) {
      // Streak broken or first time
      streak = 1;
    }

    await prefs.setString(_prefStreakDateKey, today);
    await prefs.setInt(_prefStreakKey, streak);

    final streakAchievement =
        _achievements.where((a) => a.id == 'streak_7');
    if (streakAchievement.isNotEmpty) {
      streakAchievement.first.progress = streak.clamp(0, 7);
      if (streakAchievement.first.isComplete &&
          !streakAchievement.first.isUnlocked) {
        _recentlyUnlocked = streakAchievement.first;
      }
      await _save();
      notifyListeners();
    }
  }

  /// Check if all other achievements are complete for "love_master".
  Future<void> _checkLoveMaster() async {
    final otherAchievements =
        _achievements.where((a) => a.id != 'love_master');
    final completedCount =
        otherAchievements.where((a) => a.isUnlocked).length;

    final loveMaster =
        _achievements.where((a) => a.id == 'love_master');
    if (loveMaster.isNotEmpty) {
      loveMaster.first.progress = completedCount;
      if (loveMaster.first.isComplete && !loveMaster.first.isUnlocked) {
        _recentlyUnlocked = loveMaster.first;
      }
      await _save();
      notifyListeners();
    }
  }

  Future<void> _incrementProgress(String achievementId, int amount) async {
    final match = _achievements.where((a) => a.id == achievementId);
    if (match.isEmpty) return;

    final achievement = match.first;
    if (achievement.isUnlocked && achievement.id != 'reply_master') return;

    achievement.progress =
        (achievement.progress + amount).clamp(0, achievement.maxProgress);

    if (achievement.isComplete && !achievement.isUnlocked) {
      _recentlyUnlocked = achievement;
    }

    await _save();
    notifyListeners();
  }
}
