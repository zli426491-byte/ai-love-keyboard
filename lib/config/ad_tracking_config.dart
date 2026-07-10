/// Ad tracking configuration and event name constants.
///
/// SDK keys/IDs are injected at build time when a real ad stack is enabled.
library;

class AdTrackingConfig {
  AdTrackingConfig._();

  // ── SDK Keys (replace with real values) ──────────────────────────────

  /// Facebook App ID — set with --dart-define=FACEBOOK_APP_ID=...
  /// The native Info.plist / AndroidManifest values must also match.
  static const String facebookAppId = String.fromEnvironment('FACEBOOK_APP_ID');

  /// Adjust App Token for attribution.
  static const String adjustAppToken = String.fromEnvironment(
    'ADJUST_APP_TOKEN',
  );

  /// Adjust environment: 'sandbox' for dev, 'production' for release.
  static const String adjustEnvironment = String.fromEnvironment(
    'ADJUST_ENVIRONMENT',
    defaultValue: 'sandbox',
  );

  /// TikTok Pixel ID for TikTok Events API.
  static const String tiktokPixelId = String.fromEnvironment('TIKTOK_PIXEL_ID');

  static const bool hasFacebookConfig = facebookAppId.length > 0;
  static const bool hasAdjustConfig = adjustAppToken.length > 0;
  static const bool hasTikTokConfig = tiktokPixelId.length > 0;

  /// Firebase project configuration is handled via google-services.json
  /// (Android) and GoogleService-Info.plist (iOS). No code constant needed.

  // ── Event Name Constants ─────────────────────────────────────────────

  static const String eventAppOpen = 'app_open';
  static const String eventOnboardingComplete = 'onboarding_complete';
  static const String eventGenderSelected = 'gender_selected';
  static const String eventLocaleSelected = 'locale_selected';
  static const String eventReplyGenerated = 'reply_generated';
  static const String eventReplyCopied = 'reply_copied';
  static const String eventFeatureUsed = 'feature_used';
  static const String eventKeyboardEnabled = 'keyboard_enabled';
  static const String eventPaywallShown = 'paywall_shown';
  static const String eventPaywallClosed = 'paywall_closed';
  static const String eventPlanSelected = 'plan_selected';
  static const String eventPurchaseStarted = 'purchase_started';
  static const String eventFreeTrialStarted = 'free_trial_started';
  static const String eventSubscriptionStarted = 'subscription_started';
  static const String eventSubscriptionRenewed = 'subscription_renewed';
  static const String eventShareApp = 'share_app';
  static const String eventRateApp = 'rate_app';

  // ── Revenue Event Names ──────────────────────────────────────────────

  static const String eventPurchase = 'purchase';

  // ── User Property Keys ───────────────────────────────────────────────

  static const String propGender = 'gender';
  static const String propLocale = 'locale';
  static const String propSubscriptionStatus = 'subscription_status';
  static const String propDaysSinceInstall = 'days_since_install';

  // ── Conversion Event Mappings ────────────────────────────────────────
  //
  // Which events are forwarded to which ad platforms for optimisation.
  // Key = our internal event name, value = list of platforms to send to.

  static const Map<String, List<String>> conversionEventPlatforms = {
    eventPurchaseStarted: ['facebook', 'google', 'tiktok', 'adjust'],
    eventFreeTrialStarted: ['facebook', 'google', 'tiktok', 'adjust'],
    eventSubscriptionStarted: ['facebook', 'google', 'tiktok', 'adjust'],
    eventSubscriptionRenewed: ['facebook', 'google', 'adjust'],
    eventPurchase: ['facebook', 'google', 'tiktok', 'adjust'],
    eventOnboardingComplete: ['facebook', 'tiktok'],
    eventKeyboardEnabled: ['facebook'],
  };

  // ── Feature Name Constants ───────────────────────────────────────────

  static const String featureTranslate = 'translate';
  static const String featureTiming = 'timing';
  static const String featureEmoji = 'emoji';
  static const String featureDate = 'date';
  static const String featureArgument = 'argument';
  static const String featureGreeting = 'greeting';
  static const String featureScore = 'score';
  static const String featureAnalysis = 'analysis';
  static const String featureOpener = 'opener';
  static const String featureTopic = 'topic';
  static const String featureCulture = 'culture';
  static const String featureInterpret = 'interpret';
}
