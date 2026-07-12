import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_love_keyboard/utils/constants.dart';

/// The authenticated LoveKey account returned by the account provider.
class AccountUser {
  final String id;
  final String email;

  const AccountUser({required this.id, required this.email});
}

/// Small Supabase Auth REST client used so the app and keyboard share one
/// stable account ID without putting a service-role key in the app.
///
/// SUPABASE_URL and SUPABASE_ANON_KEY are public client configuration. The
/// access/refresh tokens are stored in platform secure storage; the access
/// token is copied to the keyboard's app group only when the user explicitly
/// signs in, because the native keyboard must attach it to API requests.
class AccountService extends ChangeNotifier {
  AccountService._();

  static final AccountService instance = AccountService._();
  static const _accessTokenKey = 'lovekey_account_access_token';
  static const _refreshTokenKey = 'lovekey_account_refresh_token';
  static const _userIdKey = 'lovekey_account_user_id';
  static const _emailKey = 'lovekey_account_email';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const Duration _requestTimeout = Duration(seconds: 15);

  AccountUser? _user;
  String? _accessToken;
  String? _refreshToken;
  String? _errorMessage;
  bool _loading = false;

  bool get isConfigured =>
      AppConstants.supabaseUrl.trim().isNotEmpty &&
      AppConstants.supabaseAnonKey.trim().isNotEmpty;
  bool get isSignedIn => _user != null && _accessToken != null;
  bool get isLoading => _loading;
  String? get accessToken => _accessToken;
  String? get userId => _user?.id;
  String? get email => _user?.email;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    if (!isConfigured) return;

    _accessToken = await _read(_accessTokenKey);
    _refreshToken = await _read(_refreshTokenKey);
    final id = await _read(_userIdKey);
    final email = await _read(_emailKey);
    if (id != null && id.isNotEmpty && email != null && email.isNotEmpty) {
      _user = AccountUser(id: id, email: email);
    }

    if (_accessToken != null && _user == null) {
      await _loadCurrentUser();
    } else if (_accessToken != null) {
      // Refresh the user record and recover from expired access tokens.
      final loaded = await _loadCurrentUser();
      if (!loaded && _refreshToken != null) {
        await refreshSession();
      }
    }
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    return _authenticate(
      '/auth/v1/token?grant_type=password',
      email: email,
      password: password,
    );
  }

  Future<bool> signUp({required String email, required String password}) async {
    return _authenticate('/auth/v1/signup', email: email, password: password);
  }

  Future<bool> refreshSession() async {
    final refreshToken = _refreshToken;
    if (!isConfigured || refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    _setLoading(true);
    try {
      final response = await http
          .post(
            _uri('/auth/v1/token?grant_type=refresh_token'),
            headers: _headers(),
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await signOut();
        return false;
      }
      await _saveSession(jsonDecode(response.body) as Map<String, dynamic>);
      await _loadCurrentUser();
      return isSignedIn;
    } catch (_) {
      _setError('登入狀態更新失敗，請重新登入');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      final token = _accessToken;
      if (token != null && isConfigured) {
        await http
            .post(
              _uri('/auth/v1/logout'),
              headers: {..._headers(), 'Authorization': 'Bearer $token'},
            )
            .timeout(_requestTimeout);
      }
    } catch (_) {
      // Local sign-out must still complete when the network is unavailable.
    } finally {
      await _clearSession();
      _setLoading(false);
    }
  }

  /// Permanently deletes the authenticated account through the Worker. A
  /// Supabase service-role key is required on the server and is never shipped
  /// to the client.
  Future<bool> deleteAccount() async {
    final token = _accessToken;
    final baseUrl = AppConstants.aiProxyBaseUrl.trim().replaceFirst(
      RegExp(r'/+$'),
      '',
    );
    if (!isSignedIn || token == null || baseUrl.isEmpty) {
      _setError('請先登入並完成帳號服務設定');
      return false;
    }

    _setLoading(true);
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/v1/account/delete'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _setError('帳號刪除失敗，請稍後再試');
        return false;
      }
      await _clearSession();
      return true;
    } on TimeoutException {
      _setError('帳號刪除逾時，請稍後再試');
      return false;
    } catch (_) {
      _setError('帳號刪除失敗，請稍後再試');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _authenticate(
    String path, {
    required String email,
    required String password,
  }) async {
    if (!isConfigured) {
      _setError('帳號服務尚未設定，請先完成 Supabase build 設定');
      return false;
    }
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.length < 8) {
      _setError('請輸入有效信箱，密碼至少 8 個字元');
      return false;
    }

    _setLoading(true);
    try {
      final response = await http
          .post(
            _uri(path),
            headers: _headers(),
            body: jsonEncode({'email': normalizedEmail, 'password': password}),
          )
          .timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _setError(_errorFromResponse(response));
        return false;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      await _saveSession(body);
      if (_accessToken == null) {
        _setError('註冊成功，請先到信箱完成驗證');
        return false;
      }
      await _loadCurrentUser();
      return isSignedIn;
    } catch (_) {
      _setError('帳號服務連線失敗，請稍後再試');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _loadCurrentUser() async {
    final token = _accessToken;
    if (!isConfigured || token == null || token.isEmpty) return false;

    try {
      final response = await http
          .get(
            _uri('/auth/v1/user'),
            headers: {..._headers(), 'Authorization': 'Bearer $token'},
          )
          .timeout(_requestTimeout);
      if (response.statusCode == 401) return false;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _setError('帳號狀態讀取失敗');
        return false;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final id = body['id'] as String?;
      final email = body['email'] as String?;
      if (id == null || email == null || id.isEmpty || email.isEmpty) {
        return false;
      }
      _user = AccountUser(id: id, email: email);
      await _write(_userIdKey, id);
      await _write(_emailKey, email);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveSession(Map<String, dynamic> body) async {
    _accessToken = body['access_token'] as String?;
    _refreshToken = body['refresh_token'] as String? ?? _refreshToken;
    if (_accessToken != null) await _write(_accessTokenKey, _accessToken!);
    if (_refreshToken != null) await _write(_refreshTokenKey, _refreshToken!);

    final user = body['user'];
    if (user is Map<String, dynamic>) {
      final id = user['id'] as String?;
      final email = user['email'] as String?;
      if (id != null && email != null) {
        _user = AccountUser(id: id, email: email);
        await _write(_userIdKey, id);
        await _write(_emailKey, email);
      }
    }
  }

  Uri _uri(String path) {
    final base = AppConstants.supabaseUrl.trim().replaceFirst(
      RegExp(r'/+$'),
      '',
    );
    return Uri.parse('$base$path');
  }

  Map<String, String> _headers() => {
    'apikey': AppConstants.supabaseAnonKey,
    'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
    'Content-Type': 'application/json',
  };

  String _errorFromResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message =
          body['msg'] ?? body['message'] ?? body['error_description'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    } catch (_) {
      // Use the stable fallback below.
    }
    return response.statusCode == 400 ? '信箱或密碼不正確' : '帳號操作失敗，請稍後再試';
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
    return _secureStorage.read(key: key);
  }

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  Future<void> _clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    _errorMessage = null;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_emailKey);
    } else {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _userIdKey);
      await _secureStorage.delete(key: _emailKey);
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
}
