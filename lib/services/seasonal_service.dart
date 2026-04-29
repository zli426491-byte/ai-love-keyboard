import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/models/seasonal_package.dart';

class SeasonalService extends ChangeNotifier {
  static const String _prefPurchasedKey = 'seasonal_purchased';
  static const String _prefBannerDismissedKey = 'seasonal_banner_dismissed';

  Set<String> _purchasedIds = {};
  String? _dismissedBannerId;
  bool _initialized = false;

  bool get initialized => _initialized;

  /// Currently active seasonal packages.
  List<SeasonalPackage> get activePackages => SeasonalPackage.activePackages;

  /// Whether there are active seasonal packages to show.
  bool get hasActivePackages => activePackages.isNotEmpty;

  /// The first active package (for banner display).
  SeasonalPackage? get bannerPackage {
    final active = activePackages;
    if (active.isEmpty) return null;
    // Show the first active package that hasn't been dismissed
    for (final pkg in active) {
      if (_dismissedBannerId != pkg.id) return pkg;
    }
    return null;
  }

  /// Whether a specific package has been purchased.
  bool isPurchased(String packageId) => _purchasedIds.contains(packageId);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefPurchasedKey);
    if (raw != null) {
      _purchasedIds = raw.toSet();
    }
    _dismissedBannerId = prefs.getString(_prefBannerDismissedKey);
    _initialized = true;
    notifyListeners();
  }

  /// Simulate purchasing a seasonal package.
  Future<void> purchasePackage(String packageId) async {
    _purchasedIds.add(packageId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefPurchasedKey, _purchasedIds.toList());
    notifyListeners();
  }

  /// Dismiss the seasonal banner for this session.
  Future<void> dismissBanner(String packageId) async {
    _dismissedBannerId = packageId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefBannerDismissedKey, packageId);
    notifyListeners();
  }

  /// Get all packages sorted: active first, then upcoming, then past.
  List<CategorizedPackage> get categorizedPackages {
    final result = <CategorizedPackage>[];

    for (final pkg in SeasonalPackage.allPackages) {
      final category = pkg.isActive
          ? PackageCategory.active
          : pkg.isUpcoming
              ? PackageCategory.upcoming
              : PackageCategory.past;
      result.add(CategorizedPackage(package: pkg, category: category));
    }

    // Sort: active first, then upcoming, then past
    result.sort((a, b) => a.category.index.compareTo(b.category.index));
    return result;
  }
}

enum PackageCategory { active, upcoming, past }

class CategorizedPackage {
  final SeasonalPackage package;
  final PackageCategory category;

  const CategorizedPackage({
    required this.package,
    required this.category,
  });

  bool get isActive => category == PackageCategory.active;
  bool get isUpcoming => category == PackageCategory.upcoming;
  bool get isPast => category == PackageCategory.past;

  String get statusLabel {
    switch (category) {
      case PackageCategory.active:
        return '限時優惠中';
      case PackageCategory.upcoming:
        return '即將推出';
      case PackageCategory.past:
        return '已結束';
    }
  }
}
