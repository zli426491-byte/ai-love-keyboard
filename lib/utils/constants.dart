class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────────────────
  static const String appName = 'AI 戀愛鍵盤';
  static const String bundleId = 'com.ailovekeyboard.app';
  static const String appVersion = '1.0.0';

  // ── Claude API ────────────────────────────────────────────────────────
  static const String claudeApiUrl =
      'https://api.anthropic.com/v1/messages';
  static const String claudeModel = 'claude-sonnet-4-20250514';
  static const String claudeApiVersion = '2023-06-01';
  // TODO: Move API key to backend server before production release
  static const String claudeApiKey = 'YOUR_API_KEY_HERE';

  // ── Free Tier ─────────────────────────────────────────────────────────
  static const int freeDailyLimit = 3;

  // ── Subscription Product IDs ──────────────────────────────────────────
  static const String weeklyProductId = 'com.ailovekeyboard.pro.weekly';
  static const String monthlyProductId = 'com.ailovekeyboard.pro.monthly';
  static const String lifetimeProductId = 'com.ailovekeyboard.pro.lifetime';
  static const int freeTrialDays = 7;
  static const String weeklyPriceDisplay = 'NT\$309/週';
  static const String monthlyPriceDisplay = 'NT\$929/月';
  static const String lifetimePriceDisplay = 'NT\$2,490 (一次買斷)';
  static const double weeklyPriceUsd = 9.99;
  static const double monthlyPriceUsd = 29.99;
  static const double lifetimePriceUsd = 79.99;

  // ── SharedPreferences Keys ────────────────────────────────────────────
  static const String prefOnboardingComplete = 'onboarding_complete';
  static const String prefDailyUsageCount = 'daily_usage_count';
  static const String prefLastUsageDate = 'last_usage_date';
  static const String prefIsSubscribed = 'is_subscribed';

  // ── AI Defaults ───────────────────────────────────────────────────────
  static const int defaultReplyCount = 3;
  static const int defaultOpenerCount = 5;
  static const int defaultTopicCount = 5;
  static const int maxInputLength = 2000;
}
