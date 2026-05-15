import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/utils/constants.dart';

/// Service layer for the backend AI proxy.
///
/// Model vendor API keys must never be shipped in the app. This service only
/// talks to our backend proxy, which owns the real model credentials.
class ApiProxyService {
  ApiProxyService._();
  static final ApiProxyService instance = ApiProxyService._();

  /// Device fingerprint for rate limiting.
  String? _deviceFingerprint;

  /// Rate limiting: timestamps of recent requests.
  final List<DateTime> _requestTimestamps = [];

  /// Max requests per hour per device (paid users).
  static const int maxRequestsPerHour = 500;

  /// Max requests per day (hard limit to prevent abuse).
  static const int maxRequestsPerDay = 5000;

  // ── Init ─────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _ensureDeviceFingerprint();
  }

  // ── Rate limiting ────────────────────────────────────────────────────

  /// Returns true if the device has exceeded the rate limit.
  bool isRateLimited() {
    _cleanOldTimestamps();
    return _requestTimestamps.length >= maxRequestsPerHour;
  }

  /// Returns how many requests remain in the current hour.
  int remainingRequests() {
    _cleanOldTimestamps();
    return (maxRequestsPerHour - _requestTimestamps.length).clamp(
      0,
      maxRequestsPerHour,
    );
  }

  void _cleanOldTimestamps() {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    _requestTimestamps.removeWhere((t) => t.isBefore(oneHourAgo));
  }

  void _recordRequest() {
    _requestTimestamps.add(DateTime.now());
  }

  // ── Device Fingerprint ───────────────────────────────────────────────

  Future<void> _ensureDeviceFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceFingerprint = prefs.getString('device_fingerprint');
    if (_deviceFingerprint == null) {
      _deviceFingerprint = _generateFingerprint();
      await prefs.setString('device_fingerprint', _deviceFingerprint!);
    }
  }

  String _generateFingerprint() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  // ── Request Signing ──────────────────────────────────────────────────

  /// Generate a simple request signature to prevent replay attacks.
  /// Uses timestamp + nonce to create a unique signature per request.
  ///
  /// TODO: Implement HMAC-SHA256 with a shared secret from backend.
  Map<String, String> _generateRequestHeaders() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final nonce = _generateNonce();

    return {
      'X-Device-Fingerprint': _deviceFingerprint ?? 'unknown',
      'X-Request-Timestamp': timestamp,
      'X-Request-Nonce': nonce,
      'X-Request-Signature': _sign(timestamp, nonce),
    };
  }

  String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Simple signature: timestamp + nonce hash.
  /// TODO: Replace with HMAC-SHA256 using server-provided secret.
  String _sign(String timestamp, String nonce) {
    // Placeholder: just concat and base64. Replace with HMAC in production.
    final payload = '$timestamp:$nonce:${_deviceFingerprint ?? ""}';
    return base64Url.encode(utf8.encode(payload));
  }

  // ── API Call ─────────────────────────────────────────────────────────

  /// Makes a chat completion request through our proxy backend.
  Future<http.Response> chatCompletion({
    required String systemPrompt,
    required String userMessage,
    int maxTokens = 1024,
    double temperature = 0.8,
    bool useHeavyModel = false,
    bool responseFormatJson = false,
    bool isPro = true,
  }) async {
    await _ensureDeviceFingerprint();

    // Rate limit check
    if (isRateLimited()) {
      throw Exception('已達到每小時請求上限（$maxRequestsPerHour 次），請稍後再試。');
    }

    _recordRequest();

    return _callViaProxy(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      maxTokens: maxTokens,
      temperature: temperature,
      useHeavyModel: useHeavyModel,
      responseFormatJson: responseFormatJson,
      isPro: isPro,
    );
  }

  Future<http.Response> _callViaProxy({
    required String systemPrompt,
    required String userMessage,
    required int maxTokens,
    required double temperature,
    required bool useHeavyModel,
    required bool responseFormatJson,
    required bool isPro,
  }) async {
    final baseUrl = AppConstants.aiProxyBaseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('AI Proxy 尚未設定，請先部署 Cloudflare Worker。');
    }

    final normalizedBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final headers = {
      'Content-Type': 'application/json',
      ..._generateRequestHeaders(),
    };

    return http.post(
      Uri.parse('$normalizedBase${AppConstants.aiProxyChatPath}'),
      headers: headers,
      body: jsonEncode({
        'user_id': _deviceFingerprint,
        'system_prompt': systemPrompt,
        'user_message': userMessage,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'use_heavy_model': useHeavyModel,
        'is_pro': isPro,
        if (responseFormatJson) 'response_format': {'type': 'json_object'},
      }),
    );
  }
}
