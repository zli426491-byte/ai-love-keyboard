import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/utils/constants.dart';

/// Service layer that prepares for backend proxy.
///
/// Currently wraps direct DeepSeek calls. When [useProxy] is true,
/// routes requests through our backend server instead.
class ApiProxyService {
  ApiProxyService._();
  static final ApiProxyService instance = ApiProxyService._();

  /// Toggle: false = direct DeepSeek, true = via our backend.
  bool useProxy = false;

  /// Backend URL (used when [useProxy] is true).
  // TODO: Replace with actual backend URL before production.
  String backendUrl = 'https://api.ailovekeyboard.com/v1';

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
    return (maxRequestsPerHour - _requestTimestamps.length)
        .clamp(0, maxRequestsPerHour);
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

    // TODO: Replace with actual JWT token from auth service.
    final jwtToken = 'Bearer placeholder_jwt_token';

    return {
      'X-Device-Fingerprint': _deviceFingerprint ?? 'unknown',
      'X-Request-Timestamp': timestamp,
      'X-Request-Nonce': nonce,
      'X-Request-Signature': _sign(timestamp, nonce),
      'Authorization': jwtToken,
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

  /// Makes a chat completion request, either directly to OpenAI or
  /// through our proxy backend.
  Future<http.Response> chatCompletion({
    required String systemPrompt,
    required String userMessage,
    int maxTokens = 1024,
    double temperature = 0.8,
  }) async {
    // Rate limit check
    if (isRateLimited()) {
      throw Exception('已達到每小時請求上限（$maxRequestsPerHour 次），請稍後再試。');
    }

    _recordRequest();

    if (useProxy) {
      return _callViaProxy(
        systemPrompt: systemPrompt,
        userMessage: userMessage,
        maxTokens: maxTokens,
        temperature: temperature,
      );
    } else {
      return _callDirectDeepSeek(
        systemPrompt: systemPrompt,
        userMessage: userMessage,
        maxTokens: maxTokens,
        temperature: temperature,
      );
    }
  }

  Future<http.Response> _callDirectDeepSeek({
    required String systemPrompt,
    required String userMessage,
    required int maxTokens,
    required double temperature,
  }) async {
    return http.post(
      Uri.parse(AppConstants.deepSeekApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConstants.deepSeekApiKey}',
      },
      body: jsonEncode({
        'model': AppConstants.deepSeekModelLight,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'max_tokens': maxTokens,
        'temperature': temperature,
      }),
    );
  }

  /// TODO: Implement actual backend proxy endpoint.
  /// The backend should:
  /// 1. Validate JWT token
  /// 2. Verify device fingerprint
  /// 3. Check request signature to prevent replays
  /// 4. Enforce server-side rate limiting
  /// 5. Forward to DeepSeek with server-held API key
  /// 6. Log usage for billing
  Future<http.Response> _callViaProxy({
    required String systemPrompt,
    required String userMessage,
    required int maxTokens,
    required double temperature,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      ..._generateRequestHeaders(),
    };

    return http.post(
      Uri.parse('$backendUrl/chat/completions'),
      headers: headers,
      body: jsonEncode({
        'system_prompt': systemPrompt,
        'user_message': userMessage,
        'max_tokens': maxTokens,
        'temperature': temperature,
      }),
    );
  }
}
