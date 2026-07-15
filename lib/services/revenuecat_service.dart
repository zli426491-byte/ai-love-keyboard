import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:ai_love_keyboard/utils/constants.dart';

class SubscriptionPlan {
  final String id;
  final String title;
  final String subtitle;
  final String fallbackPrice;
  final String badge;
  final Package? package;

  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.fallbackPrice,
    required this.badge,
    this.package,
  });

  String get price => package?.storeProduct.priceString ?? fallbackPrice;
  double get amount => package?.storeProduct.price ?? 0;
  String get currency => package?.storeProduct.currencyCode ?? 'USD';
  bool get isAvailable => package != null;
}

class RevenueCatService extends ChangeNotifier {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();
  static const MethodChannel _subscriptionChannel = MethodChannel(
    'com.ailovekeyboard.app/subscription',
  );

  bool _configured = false;
  bool _loading = false;
  bool _subscribed = false;
  bool _customerInfoSynced = false;
  String? _errorMessage;
  Offering? _currentOffering;

  bool get isLoading => _loading;
  bool get isConfigured => _configured;
  bool get isSubscribed => _subscribed;
  bool get customerInfoSynced => _customerInfoSynced;
  String? get errorMessage => _errorMessage;
  bool get hasProducts => plans.any((plan) => plan.isAvailable);

  /// RevenueCat app user ids are identifiers, not secrets. The Worker uses
  /// this value to verify the active entitlement server-side.
  Future<String?> get appUserId async {
    if (!_configured || !_supportsStoreBilling) {
      return null;
    }
    try {
      final value = (await Purchases.appUserID).trim();
      return value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  Future<void> _syncIdentityToKeyboard({String? accountAccessToken}) async {
    if (!_supportsStoreBilling) return;
    try {
      final arguments = <String, dynamic>{
        'isSubscribed': _subscribed,
        'revenueCatAppUserID': await appUserId,
      };
      if (accountAccessToken != null) {
        arguments['accountAccessToken'] = accountAccessToken;
      }
      await _subscriptionChannel.invokeMethod<void>(
        'setSubscriptionStatus',
        arguments,
      );
    } on PlatformException catch (error) {
      debugPrint('Unable to sync RevenueCat identity: ${error.code}');
    } on MissingPluginException {
      debugPrint('RevenueCat keyboard bridge is unavailable on this build.');
    }
  }

  /// Refreshes the access token copied to the native keyboard without
  /// changing the RevenueCat customer identity. Supabase can rotate this
  /// token while the app is running, so the extension must receive each new
  /// value instead of waiting for the next full login.
  Future<void> syncAccountAccessToken(String? accessToken) async {
    await _syncIdentityToKeyboard(accountAccessToken: accessToken ?? '');
  }

  List<SubscriptionPlan> get plans {
    final lifetime = _findPackage(AppConstants.lifetimeProductId);
    final yearly = _findPackage(AppConstants.yearlyProductId);
    final weekly = _findPackage(AppConstants.weeklyProductId);

    return [
      SubscriptionPlan(
        id: AppConstants.lifetimeProductId,
        title: '永久會員',
        subtitle: '一次解鎖，長期使用最省',
        fallbackPrice: AppConstants.lifetimePriceDisplay,
        badge: '',
        package: lifetime,
      ),
      SubscriptionPlan(
        id: AppConstants.yearlyProductId,
        title: '年度會員',
        subtitle: '一年完整使用，推薦長期聊天',
        fallbackPrice: AppConstants.yearlyPriceDisplay,
        badge: '最划算',
        package: yearly,
      ),
      SubscriptionPlan(
        id: AppConstants.weeklyProductId,
        title: '週會員',
        subtitle: '短期彈性使用，隨時可取消',
        fallbackPrice: AppConstants.weeklyPriceDisplay,
        badge: '',
        package: weekly,
      ),
    ];
  }

  Future<bool> init() async {
    if (!_supportsStoreBilling) {
      // Keep web/desktop previews clean. Real purchases are validated on the
      // native stores.
      _errorMessage = null;
      notifyListeners();
      return false;
    }

    final publicKey = _publicKeyForCurrentPlatform;
    if (publicKey.isEmpty) {
      _errorMessage = 'RevenueCat $_platformLabel 金鑰尚未設定';
      notifyListeners();
      return false;
    }

    try {
      if (!_configured) {
        await Purchases.configure(PurchasesConfiguration(publicKey));
        _configured = true;
      }
      await refreshCustomerInfo();
      await loadOfferings();
      return _subscribed;
    } catch (_) {
      _errorMessage = 'RevenueCat 初始化失敗';
      notifyListeners();
      return false;
    }
  }

  Future<void> loadOfferings() async {
    if (!_supportsStoreBilling) {
      _errorMessage = null;
      notifyListeners();
      return;
    }

    if (!_configured) {
      await init();
      return;
    }

    _setLoading(true);
    try {
      final offerings = await Purchases.getOfferings();
      _currentOffering = offerings.current;
      final missingProduct = plans.any((plan) => !plan.isAvailable);
      _errorMessage = _currentOffering == null || missingProduct
          ? '訂閱方案設定不完整，請檢查三個 LoveKey 商品'
          : null;
    } catch (_) {
      _errorMessage = '訂閱方案載入失敗，請檢查 RevenueCat 產品設定';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> refreshCustomerInfo() async {
    if (!_configured) {
      return false;
    }

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _subscribed = _hasActiveEntitlement(customerInfo);
      _customerInfoSynced = true;
      _errorMessage = null;
      await _syncIdentityToKeyboard();
      notifyListeners();
      return _subscribed;
    } catch (_) {
      _customerInfoSynced = false;
      _errorMessage = '訂閱狀態同步失敗';
      notifyListeners();
      return _subscribed;
    }
  }

  /// Binds the store customer to the same account ID on iOS and Android.
  /// The access token is also passed to the native keyboard bridge so the
  /// keyboard can satisfy the Worker auth gate without trusting a local Pro
  /// boolean.
  Future<bool> bindAccount(String accountId, String accessToken) async {
    final normalizedId = accountId.trim();
    final token = accessToken.trim();
    if (normalizedId.isEmpty || token.isEmpty) return false;

    if (_supportsStoreBilling && !_configured) {
      await init();
    }

    try {
      if (_configured) {
        final result = await Purchases.logIn(normalizedId);
        _subscribed = _hasActiveEntitlement(result.customerInfo);
        _customerInfoSynced = true;
      }
      await _syncIdentityToKeyboard(accountAccessToken: token);
      notifyListeners();
      return true;
    } on PlatformException catch (_) {
      _errorMessage = '會員帳號綁定失敗，請稍後再試';
      notifyListeners();
      return false;
    }
  }

  Future<void> unbindAccount() async {
    try {
      if (_configured) await Purchases.logOut();
    } on PlatformException catch (_) {
      // Local account sign-out still needs to complete.
    }
    _subscribed = false;
    _customerInfoSynced = false;
    await _syncIdentityToKeyboard(accountAccessToken: '');
    notifyListeners();
  }

  Future<bool> purchase(SubscriptionPlan plan) async {
    if (!_supportsStoreBilling) {
      _errorMessage = '此平台尚未啟用商店購買';
      notifyListeners();
      return false;
    }

    final package = plan.package;
    if (package == null) {
      throw StateError('RevenueCat 產品尚未設定');
    }

    _setLoading(true);
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _subscribed = _hasActiveEntitlement(result.customerInfo);
      _customerInfoSynced = true;
      _errorMessage = null;
      await _syncIdentityToKeyboard();
      notifyListeners();
      return _subscribed;
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        _errorMessage = '購買失敗，請稍後再試';
      }
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> restore() async {
    if (!_supportsStoreBilling) {
      _errorMessage = '此平台尚未啟用商店恢復購買';
      notifyListeners();
      return false;
    }

    if (!_configured) {
      await init();
    }

    _setLoading(true);
    try {
      final customerInfo = await Purchases.restorePurchases();
      _subscribed = _hasActiveEntitlement(customerInfo);
      _customerInfoSynced = true;
      await _syncIdentityToKeyboard();
      _errorMessage = _subscribed ? null : '沒有找到可恢復的訂閱';
      notifyListeners();
      return _subscribed;
    } catch (_) {
      _errorMessage = '恢復購買失敗';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Package? _findPackage(String productId) {
    final packages = _currentOffering?.availablePackages ?? const <Package>[];
    for (final package in packages) {
      if (package.storeProduct.identifier == productId) {
        return package;
      }
    }
    return null;
  }

  bool _hasActiveEntitlement(CustomerInfo customerInfo) {
    return customerInfo.entitlements.active.containsKey(
      AppConstants.proEntitlementId,
    );
  }

  bool get _supportsStoreBilling =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;

  String get _publicKeyForCurrentPlatform => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => AppConstants.revenueCatIosPublicKey.trim(),
    TargetPlatform.android => AppConstants.revenueCatAndroidPublicKey.trim(),
    _ => '',
  };

  String get _platformLabel =>
      defaultTargetPlatform == TargetPlatform.android ? 'Android' : 'iOS';

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
