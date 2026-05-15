class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────────────────
  static const String appName = 'LoveKey';
  static const String bundleId = 'com.ailovekeyboard.app';
  static const String appVersion = '1.0.0';

  // ── DeepSeek API ────────────────────────────────────────────────────────
  static const String deepSeekApiUrl =
      'https://api.deepseek.com/chat/completions';
  // Light model for most features (cheap: ~$0.00014/request)
  static const String deepSeekModelLight = 'deepseek-chat';
  // Heavy model for deep analysis (reasoning model)
  static const String deepSeekModelHeavy = 'deepseek-reasoner';
  // Daily limit for heavy model usage
  static const int heavyModelDailyLimit = 20;
  // TODO: Move API key to backend server before production release
  static const String deepSeekApiKey = 'sk-437fa831454e4b42a62a7bdde01d5d07';

  // ── Situation Package Product IDs ────────────────────────────────────
  static const String argumentPackageId = 'com.ailovekeyboard.pack.argument';
  static const String breakupPackageId = 'com.ailovekeyboard.pack.breakup';
  static const String confessionPackageId =
      'com.ailovekeyboard.pack.confession';
  static const String escalationPackageId =
      'com.ailovekeyboard.pack.escalation';
  static const String leftOnReadPackageId =
      'com.ailovekeyboard.pack.leftonread';

  // ── Keyboard Extension ────────────────────────────────────────────────
  static const String appGroupId = 'group.com.ailovekeyboard.app';
  static const String keyboardBundleId = 'com.ailovekeyboard.app.keyboard';
  static const String keyboardDisplayName = 'LoveKey';

  static const String revenueCatIosPublicKey =
      'appl_nttijTbdotLvIoxrLhTiTPmTivA';
  static const String proEntitlementId = 'pro';
  static const bool reviewFreeMode = false;

  // ── Free Tier ─────────────────────────────────────────────────────────
  static const int freeDailyLimit = 3;

  // ── Subscription Product IDs ──────────────────────────────────────────
  static const String monthlyProductId = 'com.ailovekeyboard.pro.monthly';
  static const String quarterlyProductId = 'com.ailovekeyboard.pro.quarterly';
  static const String yearlyProductId = 'com.ailovekeyboard.pro.yearly';
  static const int freeTrialDays = 3;
  static const String monthlyPriceDisplay = r'$9.99';
  static const String quarterlyPriceDisplay = r'$19.99';
  static const String yearlyPriceDisplay = r'$39.99';
  static const double monthlyPriceUsd = 9.99;
  static const double quarterlyPriceUsd = 19.99;
  static const double yearlyPriceUsd = 39.99;

  // ── SharedPreferences Keys ────────────────────────────────────────────
  static const String prefOnboardingComplete = 'onboarding_complete';
  static const String prefDailyUsageCount = 'daily_usage_count';
  static const String prefLastUsageDate = 'last_usage_date';
  static const String prefIsSubscribed = 'is_subscribed';
  static const String prefUserGender = 'user_gender'; // male / female

  // ── AI Defaults ───────────────────────────────────────────────────────
  static const int defaultReplyCount = 1;
  static const int defaultOpenerCount = 5;
  static const int defaultTopicCount = 5;
  static const int maxInputLength = 2000;
}
