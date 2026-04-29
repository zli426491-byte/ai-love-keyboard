import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles install attribution from ad platforms.
///
/// On first launch this service checks the attribution source (Apple Search
/// Ads on iOS, Adjust on both platforms) and persists the data locally so it
/// can be sent to a backend for ROAS calculation.
class AttributionService {
  AttributionService._internal();
  static final AttributionService instance = AttributionService._internal();
  factory AttributionService() => instance;

  static const _prefKeySource = 'attr_source';
  static const _prefKeyCampaign = 'attr_campaign';
  static const _prefKeyAdGroup = 'attr_ad_group';
  static const _prefKeyCreative = 'attr_creative';
  static const _prefKeyAttributed = 'attr_attributed';

  /// Cached attribution data — null until [init] completes.
  AttributionData? _data;
  AttributionData? get data => _data;

  // ── Initialisation ───────────────────────────────────────────────────

  /// Call once at app startup. Checks attribution sources and persists the
  /// result so we only query once.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // If we already stored attribution, load from prefs.
    if (prefs.getBool(_prefKeyAttributed) == true) {
      _data = AttributionData(
        source: prefs.getString(_prefKeySource) ?? 'unknown',
        campaign: prefs.getString(_prefKeyCampaign),
        adGroup: prefs.getString(_prefKeyAdGroup),
        creative: prefs.getString(_prefKeyCreative),
      );
      _debugLog('Attribution loaded from cache: $_data');
      return;
    }

    // First launch — try to determine attribution source.
    _data = await _fetchAttribution();
    await _persist(prefs, _data!);
    _debugLog('Attribution resolved: $_data');
  }

  // ── Attribution Fetching ─────────────────────────────────────────────

  Future<AttributionData> _fetchAttribution() async {
    // Try Apple Search Ads first (iOS only).
    final asaData = await _checkAppleSearchAds();
    if (asaData != null) return asaData;

    // TODO: Check Adjust attribution
    //   final adjustAttribution = await Adjust.getAttribution();
    //   if (adjustAttribution != null) {
    //     return AttributionData(
    //       source: adjustAttribution.network ?? 'adjust',
    //       campaign: adjustAttribution.campaign,
    //       adGroup: adjustAttribution.adgroup,
    //       creative: adjustAttribution.creative,
    //     );
    //   }

    return const AttributionData(source: 'organic');
  }

  Future<AttributionData?> _checkAppleSearchAds() async {
    // TODO: Implement Apple Search Ads attribution (iOS only)
    //   try {
    //     final data = await AppleSearchAds.attributionData();
    //     if (data['iad-attribution'] == 'true') {
    //       return AttributionData(
    //         source: 'apple_search_ads',
    //         campaign: data['iad-campaign-name'],
    //         adGroup: data['iad-adgroup-name'],
    //         creative: data['iad-creative-set-name'],
    //       );
    //     }
    //   } catch (e) {
    //     _debugLog('Apple Search Ads check failed: $e');
    //   }
    return null;
  }

  // ── Backend Sync ─────────────────────────────────────────────────────

  /// Send attribution data to our backend for ROAS dashboards.
  Future<void> sendToBackend() async {
    if (_data == null) return;

    // TODO: POST attribution to backend
    //   final response = await http.post(
    //     Uri.parse('$backendUrl/api/attribution'),
    //     body: jsonEncode(_data!.toJson()),
    //   );

    _debugLog('Attribution sent to backend (stub)');
  }

  // ── Persistence ──────────────────────────────────────────────────────

  Future<void> _persist(SharedPreferences prefs, AttributionData data) async {
    await prefs.setBool(_prefKeyAttributed, true);
    await prefs.setString(_prefKeySource, data.source);
    if (data.campaign != null) {
      await prefs.setString(_prefKeyCampaign, data.campaign!);
    }
    if (data.adGroup != null) {
      await prefs.setString(_prefKeyAdGroup, data.adGroup!);
    }
    if (data.creative != null) {
      await prefs.setString(_prefKeyCreative, data.creative!);
    }
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[Attribution] $message');
    }
  }
}

/// Immutable attribution data model.
class AttributionData {
  final String source;
  final String? campaign;
  final String? adGroup;
  final String? creative;

  const AttributionData({
    required this.source,
    this.campaign,
    this.adGroup,
    this.creative,
  });

  Map<String, String?> toJson() => {
        'source': source,
        'campaign': campaign,
        'ad_group': adGroup,
        'creative': creative,
      };

  @override
  String toString() =>
      'AttributionData(source: $source, campaign: $campaign, '
      'adGroup: $adGroup, creative: $creative)';
}
