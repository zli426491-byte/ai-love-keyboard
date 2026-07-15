import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
  static const Duration _oauthTimeout = Duration(minutes: 2);

  AccountUser? _user;
  String? _accessToken;
  String? _refreshToken;
  String? _errorMessage;
  bool _loading = false;
  bool _supabaseInitialized = false;
  bool _googleInitialized = false;
  StreamSubscription<AuthState>? _authSubscription;

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

    await _initializeSupabase();
    _listenForSupabaseAuthChanges();

    // Supabase persists OAuth sessions for us. Mirror the current session into
    // the same secure token store used by the REST auth flow so the keyboard
    // and Worker continue to use one account identity.
    final supabaseSession = _supabaseClient?.auth.currentSession;
    if (supabaseSession != null) {
      await _saveSupabaseSession(supabaseSession);
    }

    _accessToken = await _read(_accessTokenKey);
    _refreshToken = await _read(_refreshTokenKey);
    final id = await _read(_userIdKey);
    final email = await _read(_emailKey);
    if (id != null && id.isNotEmpty && email != null && email.isNotEmpty) {
      _user = AccountUser(id: id, email: email);
    }

    if (_supabaseClient?.auth.currentSession == null &&
        _refreshToken != null &&
        _refreshToken!.isNotEmpty) {
      await _restoreSupabaseSessionFromStoredTokens();
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

  /// Signs in with the native Google SDK on iOS/Android, then exchanges the
  /// Google ID token for a Supabase session. On web, Supabase's hosted OAuth
  /// flow is used instead.
  Future<bool> signInWithGoogle({bool linkIdentity = false}) async {
    if (!await _ensureSupabase()) return false;
    if (linkIdentity && _supabaseClient?.auth.currentSession == null) {
      _setError('請先登入 LoveKey，再綁定 Google。');
      return false;
    }

    if (kIsWeb) {
      return _signInWithOAuth(OAuthProvider.google);
    }
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.android) {
      _setError('此裝置不支援 Google 快速登入。');
      return false;
    }
    if (AppConstants.googleWebClientId.trim().isEmpty) {
      _setError('尚未設定 Google Web Client ID，請完成 Supabase/Google 設定。');
      return false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        AppConstants.googleIosClientId.trim().isEmpty) {
      _setError('尚未設定 Google iOS Client ID，請完成 iOS 設定。');
      return false;
    }

    _setLoading(true);
    try {
      final google = GoogleSignIn.instance;
      if (!_googleInitialized) {
        await google.initialize(
          clientId: defaultTargetPlatform == TargetPlatform.iOS
              ? AppConstants.googleIosClientId
              : null,
          serverClientId: AppConstants.googleWebClientId,
        );
        _googleInitialized = true;
      }

      // The plugin recommends signing out before a new interactive account
      // selection so a tester can switch Google accounts reliably.
      await google.signOut();
      final googleAccount = await google.authenticate();
      final authorization = await googleAccount.authorizationClient
          .authorizationForScopes(const <String>[]);
      final idToken = googleAccount.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        _setError('Google 未提供有效的登入 Token。');
        return false;
      }

      final response = linkIdentity
          ? await _supabaseClient!.auth.linkIdentityWithIdToken(
              provider: OAuthProvider.google,
              idToken: idToken,
              accessToken: authorization?.accessToken,
            )
          : await _supabaseClient!.auth.signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: idToken,
              accessToken: authorization?.accessToken,
            );
      return await _completeSupabaseAuth(response);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        _setError('已取消 Google 登入。');
      } else {
        _setError('Google 登入失敗，請確認 OAuth Client 設定。');
      }
      return false;
    } on AuthException catch (_) {
      _setError('Google 登入驗證失敗，請確認 Supabase Google Provider 設定。');
      return false;
    } catch (_) {
      _setError('Google 登入失敗，請稍後再試。');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Signs in with native Sign in with Apple on iOS. Android and web use the
  /// Supabase Apple OAuth flow because Apple native credentials are iOS-only.
  Future<bool> signInWithApple({bool linkIdentity = false}) async {
    if (!await _ensureSupabase()) return false;
    if (linkIdentity && _supabaseClient?.auth.currentSession == null) {
      _setError('請先登入 LoveKey，再綁定 Apple。');
      return false;
    }

    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
      return linkIdentity
          ? _linkIdentityWithOAuth(OAuthProvider.apple)
          : _signInWithOAuth(OAuthProvider.apple);
    }
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      _setError('此裝置不支援 Apple 快速登入。');
      return false;
    }

    _setLoading(true);
    try {
      final rawNonce = _supabaseClient!.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        _setError('Apple 未提供有效的登入 Token。');
        return false;
      }

      final response = linkIdentity
          ? await _supabaseClient!.auth.linkIdentityWithIdToken(
              provider: OAuthProvider.apple,
              idToken: idToken,
              nonce: rawNonce,
            )
          : await _supabaseClient!.auth.signInWithIdToken(
              provider: OAuthProvider.apple,
              idToken: idToken,
              nonce: rawNonce,
            );
      return await _completeSupabaseAuth(response);
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        _setError('已取消 Apple 登入。');
      } else {
        _setError('Apple 登入失敗，請確認 Apple Developer 設定。');
      }
      return false;
    } on AuthException catch (_) {
      _setError('Apple 登入驗證失敗，請確認 Supabase Apple Provider 設定。');
      return false;
    } catch (_) {
      _setError('Apple 登入失敗，請稍後再試。');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> linkGoogleIdentity() => signInWithGoogle(linkIdentity: true);

  Future<bool> linkAppleIdentity() => signInWithApple(linkIdentity: true);

  SupabaseClient? get _supabaseClient =>
      _supabaseInitialized ? Supabase.instance.client : null;

  Future<void> _initializeSupabase() async {
    if (_supabaseInitialized) return;
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
    );
    _supabaseInitialized = true;
  }

  void _listenForSupabaseAuthChanges() {
    if (_authSubscription != null || _supabaseClient == null) return;
    _authSubscription = _supabaseClient!.auth.onAuthStateChange.listen((state) {
      final session = state.session;
      if (session != null) {
        unawaited(_saveSupabaseSession(session));
      } else if (state.event == AuthChangeEvent.signedOut) {
        unawaited(_clearSession());
      }
    });
  }

  Future<bool> _ensureSupabase() async {
    if (!isConfigured) {
      _setError('登入服務尚未設定，請在 build 時提供 Supabase 設定。');
      return false;
    }
    try {
      await _initializeSupabase();
      _listenForSupabaseAuthChanges();
      return true;
    } catch (_) {
      _setError('登入服務暫時無法使用，請稍後再試。');
      return false;
    }
  }

  Future<bool> _completeSupabaseAuth(AuthResponse response) async {
    final session = response.session;
    if (session == null) {
      _setError('登入成功但沒有取得工作階段，請稍後再試。');
      return false;
    }
    await _saveSupabaseSession(session);
    return isSignedIn;
  }

  Future<bool> _signInWithOAuth(OAuthProvider provider) async {
    final client = _supabaseClient;
    if (client == null) return false;

    _setLoading(true);
    try {
      final started = await client.auth.signInWithOAuth(
        provider,
        redirectTo: kIsWeb ? null : AppConstants.authRedirectUri,
      );
      if (!started) {
        _setError('無法開啟登入頁面，請稍後再試。');
        return false;
      }
      // Native deep-link callbacks are handled by supabase_flutter and the
      // auth-state listener above. Wait here so the caller can bind RevenueCat
      // only after a real Supabase session exists.
      final deadline = DateTime.now().add(_oauthTimeout);
      while (!isSignedIn && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      if (!isSignedIn) {
        _setError('登入頁面已開啟，完成授權後請返回 LoveKey。');
      }
      return isSignedIn;
    } on AuthException catch (_) {
      _setError('第三方登入驗證失敗，請確認 Supabase Provider 設定。');
      return false;
    } catch (_) {
      _setError('第三方登入失敗，請稍後再試。');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _linkIdentityWithOAuth(OAuthProvider provider) async {
    final client = _supabaseClient;
    if (client == null || client.auth.currentSession == null) return false;

    _setLoading(true);
    StreamSubscription<AuthState>? subscription;
    try {
      final response = await client.auth.getLinkIdentityUrl(
        provider,
        redirectTo: kIsWeb ? null : AppConstants.authRedirectUri,
      );
      final launched = await launchUrl(
        Uri.parse(response.url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _setError('無法開啟綁定頁面，請稍後再試。');
        return false;
      }

      final completer = Completer<bool>();
      subscription = client.auth.onAuthStateChange.listen((state) {
        if (state.event == AuthChangeEvent.userUpdated ||
            state.event == AuthChangeEvent.signedIn) {
          if (!completer.isCompleted) completer.complete(true);
        }
      });
      final linked = await Future.any<bool>([
        completer.future,
        Future<bool>.delayed(_oauthTimeout, () => false),
      ]);
      if (!linked) {
        _setError('綁定頁面已開啟，完成授權後請返回 LoveKey。');
      }
      return linked;
    } on AuthException catch (_) {
      _setError('第三方綁定失敗，請確認 Supabase Provider 設定。');
      return false;
    } catch (_) {
      _setError('第三方綁定失敗，請稍後再試。');
      return false;
    } finally {
      await subscription?.cancel();
      _setLoading(false);
    }
  }

  Future<void> _saveSupabaseSession(Session session) async {
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    final email = session.user.email ?? '';
    _user = AccountUser(id: session.user.id, email: email);
    await _write(_accessTokenKey, session.accessToken);
    if (session.refreshToken != null && session.refreshToken!.isNotEmpty) {
      await _write(_refreshTokenKey, session.refreshToken!);
    }
    await _write(_userIdKey, session.user.id);
    if (email.isNotEmpty) await _write(_emailKey, email);
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _restoreSupabaseSessionFromStoredTokens() async {
    final client = _supabaseClient;
    final refreshToken = _refreshToken;
    final accessToken = _accessToken;
    if (client == null || refreshToken == null || refreshToken.isEmpty) return;
    try {
      final response = await client.auth.setSession(
        refreshToken,
        accessToken: accessToken,
      );
      final session = response.session;
      if (session != null) await _saveSupabaseSession(session);
    } catch (_) {
      // The REST session remains usable; linking can be retried after a fresh
      // login if Supabase cannot restore it here.
    }
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
      await _restoreSupabaseSessionFromStoredTokens();
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
      if (_supabaseClient != null &&
          _supabaseClient!.auth.currentSession != null) {
        await _supabaseClient!.auth.signOut();
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
      if (_supabaseClient?.auth.currentSession != null) {
        await _supabaseClient!.auth.signOut();
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
      await _restoreSupabaseSessionFromStoredTokens();
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
