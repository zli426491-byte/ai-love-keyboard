import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:ai_love_keyboard/services/analytics_service.dart';

/// Handles deep links from ad campaigns.
///
/// Parses UTM parameters, routes users to the appropriate feature, and
/// tracks deep-link conversions.
class DeepLinkService {
  DeepLinkService._internal();
  static final DeepLinkService instance = DeepLinkService._internal();
  factory DeepLinkService() => instance;

  /// Cached UTM params from the most recent deep link.
  UtmParameters? _lastUtm;
  UtmParameters? get lastUtm => _lastUtm;

  // ── Initialisation ───────────────────────────────────────────────────

  /// Call once at app startup to begin listening for incoming deep links.
  Future<void> init() async {
    // TODO: Listen for deep links with uni_links / app_links package
    //   // Handle link that launched the app (cold start).
    //   try {
    //     final initialUri = await getInitialUri();
    //     if (initialUri != null) _handleDeepLink(initialUri);
    //   } catch (_) {}
    //
    //   // Handle links while app is running (warm start).
    //   uriLinkStream.listen((uri) {
    //     if (uri != null) _handleDeepLink(uri);
    //   });

    _debugLog('DeepLinkService initialised');
  }

  // ── Deep Link Handling ───────────────────────────────────────────────

  /// Parse a URI and extract UTM parameters + route info.
  void handleDeepLink(Uri uri) {
    _lastUtm = UtmParameters.fromUri(uri);

    _debugLog('Deep link received: $uri');
    _debugLog('UTM params: $_lastUtm');

    // Track the deep link event
    AnalyticsService.instance.trackFeatureUsed(feature: 'deep_link');

    // TODO: Forward UTM data to Adjust / Facebook for attribution
    //   Adjust.appWillOpenUrl(uri);
  }

  /// Route the user based on the deep link path.
  ///
  /// Call this after the app's navigation is ready.
  void routeIfPending(BuildContext context) {
    if (_lastUtm == null) return;

    final route = _lastUtm!.content; // use utm_content as route hint
    if (route == null || route.isEmpty) return;

    // Map deep link routes to named routes or push specific pages.
    // TODO: Expand route mapping as features grow.
    switch (route) {
      case 'opener':
        Navigator.pushNamed(context, '/opener');
        break;
      case 'paywall':
        Navigator.pushNamed(context, '/paywall');
        break;
      case 'analysis':
        Navigator.pushNamed(context, '/analysis');
        break;
      default:
        _debugLog('Unknown deep link route: $route');
    }

    // Clear after routing so we don't re-route.
    _lastUtm = null;
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[DeepLink] $message');
    }
  }
}

/// Parsed UTM parameters from an ad click URL.
class UtmParameters {
  final String? source;
  final String? medium;
  final String? campaign;
  final String? term;
  final String? content;

  const UtmParameters({
    this.source,
    this.medium,
    this.campaign,
    this.term,
    this.content,
  });

  factory UtmParameters.fromUri(Uri uri) {
    return UtmParameters(
      source: uri.queryParameters['utm_source'],
      medium: uri.queryParameters['utm_medium'],
      campaign: uri.queryParameters['utm_campaign'],
      term: uri.queryParameters['utm_term'],
      content: uri.queryParameters['utm_content'],
    );
  }

  Map<String, String?> toJson() => {
        'utm_source': source,
        'utm_medium': medium,
        'utm_campaign': campaign,
        'utm_term': term,
        'utm_content': content,
      };

  @override
  String toString() =>
      'UtmParameters(source: $source, medium: $medium, '
      'campaign: $campaign, term: $term, content: $content)';
}
