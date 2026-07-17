class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────────────────
  static const String appName = 'LoveKey';
  static const String bundleId = 'com.ailovekeyboard.app';
  static const String appVersion = '1.0.4';
  static const String appStoreUrl = 'https://apps.apple.com/app/id6764681086';
  static const String appStoreReviewUrl =
      'https://apps.apple.com/app/id6764681086?action=write-review';

  // ── AI Backend Proxy ───────────────────────────────────────────────────
  // Inject at build time:
  // flutter build ipa --dart-define=AI_PROXY_URL=https://your-worker.workers.dev
  static const String aiProxyBaseUrl = String.fromEnvironment('AI_PROXY_URL');
  static const String aiProxyChatPath = '/v1/chat/completions';

  // Optional cross-platform account service. Values are injected at build
  // time and are safe to ship as public client configuration.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  // OAuth client configuration. These are public client IDs, not secrets.
  // Inject them at build time; never put Google/Apple private keys in the app.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  static const String authRedirectUri = String.fromEnvironment(
    'AUTH_REDIRECT_URI',
    defaultValue: 'com.ailovekeyboard.app://login-callback',
  );
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

  // Inject the platform-specific LoveKey Public SDK Keys at build time.
  // Keeping either empty makes a misconfigured native release fail closed
  // instead of loading another RevenueCat project's products.
  static const String revenueCatIosPublicKey = String.fromEnvironment(
    'REVENUECAT_IOS_PUBLIC_KEY',
  );
  static const String revenueCatAndroidPublicKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_PUBLIC_KEY',
  );
  static const String proEntitlementId = 'pro';
  static const bool reviewFreeMode = false;

  // Production uses a paid-only Worker. A separate staging build can opt in
  // to the limited free tier without making the release UI promise access
  // that the production backend will reject.
  static const bool allowFreeTier = bool.fromEnvironment(
    'ALLOW_FREE_TIER',
    defaultValue: false,
  );

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
