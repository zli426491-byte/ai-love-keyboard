import 'package:flutter/foundation.dart';

import 'package:ai_love_keyboard/config/ad_tracking_config.dart';

/// Singleton analytics service that wraps all ad-tracking / analytics SDKs
/// and provides a single API surface for the rest of the app.
///
/// Current implementation logs to console in debug mode.
/// Each method contains TODO comments marking where real SDK calls go.
class AnalyticsService {
  AnalyticsService._internal();
  static final AnalyticsService instance = AnalyticsService._internal();
  factory AnalyticsService() => instance;

  // ── Initialisation ───────────────────────────────────────────────────

  /// Call once at app startup (before runApp or right after).
  Future<void> init() async {
    // TODO: Initialize Facebook SDK
    //   await FacebookSdk.sdkInit(appId: AdTrackingConfig.facebookAppId);

    // TODO: Initialize Firebase
    //   await Firebase.initializeApp();
    //   _firebaseAnalytics = FirebaseAnalytics.instance;

    // TODO: Initialize Adjust SDK
    //   final adjustConfig = AdjustConfig(
    //     AdTrackingConfig.adjustAppToken,
    //     AdTrackingConfig.adjustEnvironment,
    //   );
    //   Adjust.start(adjustConfig);

    // TODO: Initialize TikTok Events SDK
    //   TikTokSdk.init(pixelId: AdTrackingConfig.tiktokPixelId);

    _debugLog('AnalyticsService initialised');
  }

  // ── Core Event Tracking ──────────────────────────────────────────────

  void trackAppOpen() {
    _trackEvent(AdTrackingConfig.eventAppOpen);
  }

  void trackOnboardingComplete() {
    _trackEvent(AdTrackingConfig.eventOnboardingComplete);
  }

  void trackGenderSelected({required String gender}) {
    _trackEvent(AdTrackingConfig.eventGenderSelected, params: {
      'gender': gender,
    });
    setUserProperty(AdTrackingConfig.propGender, gender);
  }

  void trackLocaleSelected({required String locale}) {
    _trackEvent(AdTrackingConfig.eventLocaleSelected, params: {
      'locale': locale,
    });
    setUserProperty(AdTrackingConfig.propLocale, locale);
  }

  void trackReplyGenerated({
    required String style,
    String? persona,
    int? intimacyLevel,
  }) {
    final params = <String, String>{
      'style': style,
    };
    if (persona != null) params['persona'] = persona;
    if (intimacyLevel != null) {
      params['intimacy_level'] = intimacyLevel.toString();
    }
    _trackEvent(AdTrackingConfig.eventReplyGenerated, params: params);
  }

  void trackReplyCopied() {
    _trackEvent(AdTrackingConfig.eventReplyCopied);
  }

  void trackFeatureUsed({required String feature}) {
    _trackEvent(AdTrackingConfig.eventFeatureUsed, params: {
      'feature': feature,
    });
  }

  void trackKeyboardEnabled() {
    _trackEvent(AdTrackingConfig.eventKeyboardEnabled);
  }

  // ── Paywall / Subscription ───────────────────────────────────────────

  void trackPaywallShown() {
    _trackEvent(AdTrackingConfig.eventPaywallShown);
  }

  void trackPaywallClosed() {
    _trackEvent(AdTrackingConfig.eventPaywallClosed);
  }

  void trackPlanSelected({required String planType}) {
    _trackEvent(AdTrackingConfig.eventPlanSelected, params: {
      'plan_type': planType,
    });
  }

  void trackFreeTrialStarted() {
    _trackEvent(AdTrackingConfig.eventFreeTrialStarted);
  }

  void trackSubscriptionStarted({required String planType}) {
    _trackEvent(AdTrackingConfig.eventSubscriptionStarted, params: {
      'plan_type': planType,
    });
  }

  void trackSubscriptionRenewed({required String planType}) {
    _trackEvent(AdTrackingConfig.eventSubscriptionRenewed, params: {
      'plan_type': planType,
    });
  }

  // ── Revenue Tracking (for ROAS) ──────────────────────────────────────

  void trackRevenue({
    required double amount,
    required String currency,
    required String planType,
  }) {
    _trackEvent(AdTrackingConfig.eventPurchase, params: {
      'value': amount.toString(),
      'currency': currency,
      'plan_type': planType,
    });

    // TODO: Facebook revenue event
    //   FacebookAppEvents.logPurchase(amount: amount, currency: currency);

    // TODO: Adjust revenue event
    //   final event = AdjustEvent('PURCHASE_TOKEN');
    //   event.setRevenue(amount, currency);
    //   Adjust.trackEvent(event);

    // TODO: Firebase revenue
    //   _firebaseAnalytics?.logEvent(
    //     name: 'purchase',
    //     parameters: {'value': amount, 'currency': currency},
    //   );

    _debugLog('Revenue tracked: $amount $currency ($planType)');
  }

  // ── Social ───────────────────────────────────────────────────────────

  void trackShareApp() {
    _trackEvent(AdTrackingConfig.eventShareApp);
  }

  void trackRateApp() {
    _trackEvent(AdTrackingConfig.eventRateApp);
  }

  // ── User Properties ──────────────────────────────────────────────────

  void setUserProperty(String name, String value) {
    // TODO: Firebase Analytics
    //   _firebaseAnalytics?.setUserProperty(name: name, value: value);

    // TODO: Facebook user properties
    //   FacebookAppEvents.setUserData(userData: {name: value});

    _debugLog('User property set: $name = $value');
  }

  void updateSubscriptionStatus(String status) {
    setUserProperty(AdTrackingConfig.propSubscriptionStatus, status);
  }

  void updateDaysSinceInstall(int days) {
    setUserProperty(AdTrackingConfig.propDaysSinceInstall, days.toString());
  }

  // ── Private Helpers ──────────────────────────────────────────────────

  void _trackEvent(String name, {Map<String, String>? params}) {
    // TODO: Facebook App Events
    //   FacebookAppEvents.logEvent(
    //     name: name,
    //     parameters: params,
    //   );

    // TODO: Firebase Analytics
    //   _firebaseAnalytics?.logEvent(
    //     name: name,
    //     parameters: params,
    //   );

    // TODO: Adjust — only for conversion events
    //   if (AdTrackingConfig.conversionEventPlatforms[name]
    //       ?.contains('adjust') == true) {
    //     final adjustEvent = AdjustEvent('TOKEN_FOR_$name');
    //     params?.forEach((k, v) => adjustEvent.addCallbackParameter(k, v));
    //     Adjust.trackEvent(adjustEvent);
    //   }

    // TODO: TikTok Events API
    //   if (AdTrackingConfig.conversionEventPlatforms[name]
    //       ?.contains('tiktok') == true) {
    //     TikTokSdk.track(name, properties: params);
    //   }

    _debugLog('Event: $name${params != null ? ' $params' : ''}');
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[Analytics] $message');
    }
  }
}
