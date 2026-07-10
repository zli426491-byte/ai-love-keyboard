class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────────────────
  static const String appName = 'LoveKey';
  static const String bundleId = 'com.ailovekeyboard.app';
  static const String appVersion = '1.0.0';
  static const String appStoreUrl = 'https://apps.apple.com/app/id6764681086';
  static const String appStoreReviewUrl =
      'https://apps.apple.com/app/id6764681086?action=write-review';

  // ── AI Backend Proxy ───────────────────────────────────────────────────
  // Inject at build time:
  // flutter build ipa --dart-define=AI_PROXY_URL=https://your-worker.workers.dev
  static const String aiProxyBaseUrl = String.fromEnvironment('AI_PROXY_URL');
  static const String aiProxyChatPath = '/v1/chat/completions';
  // Daily limit for heavy model usage in the client UI. The server still owns
  // the real API key and server-side rate limits.
  static const int heavyModelDailyLimit = 20;

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

  // Inject the LoveKey iOS Public SDK Key at build time. Keeping this empty
  // makes a misconfigured release fail closed instead of loading another
  // RevenueCat project's products.
  static const String revenueCatIosPublicKey = String.fromEnvironment(
    'REVENUECAT_IOS_PUBLIC_KEY',
  );
  static const String proEntitlementId = 'pro';
  static const bool reviewFreeMode = false;

  // ── Free Tier ─────────────────────────────────────────────────────────
  static const int freeDailyLimit = 3;

  // ── Subscription Product IDs ──────────────────────────────────────────
  static const String weeklyProductId = 'com.ailovekeyboard.pro.weekly';
  static const String yearlyProductId = 'com.ailovekeyboard.pro.yearly';
  static const String lifetimeProductId = 'com.ailovekeyboard.pro.lifetime';
  static const int freeTrialDays = 3;
  static const String weeklyPriceDisplay = r'$9.99';
  static const String yearlyPriceDisplay = r'$39.99';
  static const String lifetimePriceDisplay = r'$59.99';
  static const double weeklyPriceUsd = 9.99;
  static const double yearlyPriceUsd = 39.99;
  static const double lifetimePriceUsd = 59.99;

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
