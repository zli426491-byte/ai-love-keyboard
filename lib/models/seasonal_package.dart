import 'package:flutter/material.dart';

class SeasonalPackage {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final double price;
  final List<String> features;
  final String productId;
  final DateTime startDate;
  final DateTime endDate;

  const SeasonalPackage({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.price,
    required this.features,
    required this.productId,
    required this.startDate,
    required this.endDate,
  });

  /// Whether this package is currently active based on dates.
  bool get isActive {
    final now = DateTime.now();
    // Compare using month/day only (year-agnostic)
    final nowMd = now.month * 100 + now.day;
    final startMd = startDate.month * 100 + startDate.day;
    final endMd = endDate.month * 100 + endDate.day;

    if (startMd <= endMd) {
      return nowMd >= startMd && nowMd <= endMd;
    } else {
      // Wraps around year (e.g., Dec 1 - Feb 15)
      return nowMd >= startMd || nowMd <= endMd;
    }
  }

  /// Days remaining until this package ends. Returns 0 if not active.
  int get daysRemaining {
    if (!isActive) return 0;
    final now = DateTime.now();
    // Build an end date in the current year (or next if wrapping)
    var end = DateTime(now.year, endDate.month, endDate.day, 23, 59, 59);
    if (end.isBefore(now)) {
      end = DateTime(now.year + 1, endDate.month, endDate.day, 23, 59, 59);
    }
    return end.difference(now).inDays + 1;
  }

  /// Whether this package is upcoming (hasn't started yet this cycle).
  bool get isUpcoming {
    if (isActive) return false;
    final now = DateTime.now();
    final nowMd = now.month * 100 + now.day;
    final startMd = startDate.month * 100 + startDate.day;
    final endMd = endDate.month * 100 + endDate.day;

    if (startMd <= endMd) {
      return nowMd < startMd;
    } else {
      // For wrapping ranges, upcoming if after end and before start
      return nowMd > endMd && nowMd < startMd;
    }
  }

  /// Theme colors for each seasonal package.
  Color get primaryColor {
    switch (id) {
      case 'christmas':
        return const Color(0xFFC62828);
      case 'valentine':
        return const Color(0xFFE91E63);
      case 'halloween':
        return const Color(0xFFFF6F00);
      case 'lunar_new_year':
        return const Color(0xFFD32F2F);
      case 'summer':
        return const Color(0xFF0097A7);
      case 'white_valentine':
        return const Color(0xFFEC407A);
      default:
        return const Color(0xFFAB47BC);
    }
  }

  Color get secondaryColor {
    switch (id) {
      case 'christmas':
        return const Color(0xFF2E7D32);
      case 'valentine':
        return const Color(0xFFFF80AB);
      case 'halloween':
        return const Color(0xFF4A148C);
      case 'lunar_new_year':
        return const Color(0xFFFFD54F);
      case 'summer':
        return const Color(0xFF4DD0E1);
      case 'white_valentine':
        return const Color(0xFFF8BBD0);
      default:
        return const Color(0xFFFF80AB);
    }
  }

  LinearGradient get gradient => LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // ── Pre-defined seasonal packages ─────────────────────────────────────

  static final List<SeasonalPackage> allPackages = [
    SeasonalPackage(
      id: 'christmas',
      name: '聖誕告白包',
      emoji: '\u{1F384}',
      description: '聖誕節限定！最浪漫的告白時刻',
      price: 4.99,
      features: [
        '聖誕告白話術',
        '浪漫約會方案',
        '聖誕禮物建議',
      ],
      productId: 'com.ailovekeyboard.seasonal.christmas',
      startDate: DateTime(2024, 12, 1),
      endDate: DateTime(2024, 12, 31),
    ),
    SeasonalPackage(
      id: 'valentine',
      name: '情人節必勝包',
      emoji: '\u{1F339}',
      description: '情人節必備！從告白到約會全包',
      price: 6.99,
      features: [
        'AI 情書生成',
        '禮物建議',
        '約會全規劃',
        '表白時機分析',
      ],
      productId: 'com.ailovekeyboard.seasonal.valentine',
      startDate: DateTime(2024, 2, 1),
      endDate: DateTime(2024, 2, 28),
    ),
    SeasonalPackage(
      id: 'halloween',
      name: '萬聖節搭訕包',
      emoji: '\u{1F383}',
      description: '派對搭訕神器！創意破冰話術',
      price: 3.99,
      features: [
        '創意搭訕話術',
        '派對話題',
        'cosplay 約會建議',
      ],
      productId: 'com.ailovekeyboard.seasonal.halloween',
      startDate: DateTime(2024, 10, 15),
      endDate: DateTime(2024, 10, 31),
    ),
    SeasonalPackage(
      id: 'lunar_new_year',
      name: '過年脫單包',
      emoji: '\u{1F9E7}',
      description: '過年回家不再被催婚！',
      price: 4.99,
      features: [
        '應對親戚催婚話術',
        '相親必勝攻略',
        '新年告白方案',
      ],
      productId: 'com.ailovekeyboard.seasonal.lunarnewyear',
      startDate: DateTime(2024, 1, 15),
      endDate: DateTime(2024, 2, 15),
    ),
    SeasonalPackage(
      id: 'summer',
      name: '暑假戀愛包',
      emoji: '\u{1F3D6}\uFE0F',
      description: '夏日限定！把握暑假黃金期',
      price: 4.99,
      features: [
        '夏日約會方案',
        '海邊搭訕話術',
        '旅行告白攻略',
      ],
      productId: 'com.ailovekeyboard.seasonal.summer',
      startDate: DateTime(2024, 6, 15),
      endDate: DateTime(2024, 8, 31),
    ),
    SeasonalPackage(
      id: 'white_valentine',
      name: '白色情人節包',
      emoji: '\u{1F36B}',
      description: '回禮加分！讓關係更進一步',
      price: 4.99,
      features: [
        '回禮建議',
        '感謝話術',
        '關係升級策略',
      ],
      productId: 'com.ailovekeyboard.seasonal.whitevalentine',
      startDate: DateTime(2024, 3, 1),
      endDate: DateTime(2024, 3, 14),
    ),
  ];

  /// Returns only currently active seasonal packages.
  static List<SeasonalPackage> get activePackages =>
      allPackages.where((p) => p.isActive).toList();

  /// Returns upcoming packages (not yet active).
  static List<SeasonalPackage> get upcomingPackages =>
      allPackages.where((p) => p.isUpcoming).toList();

  /// Returns past packages (already ended for this cycle).
  static List<SeasonalPackage> get pastPackages =>
      allPackages.where((p) => !p.isActive && !p.isUpcoming).toList();
}
