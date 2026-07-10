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
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      // Keep web/desktop previews clean. Real purchases are validated on iOS.
      _errorMessage = null;
      notifyListeners();
      return false;
    }

    if (AppConstants.revenueCatIosPublicKey.trim().isEmpty) {
      _errorMessage = 'RevenueCat iOS 金鑰尚未設定';
      notifyListeners();
      return false;
    }

    try {
      if (!_configured) {
        await Purchases.configure(
          PurchasesConfiguration(AppConstants.revenueCatIosPublicKey),
        );
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
    if (defaultTargetPlatform != TargetPlatform.iOS) {
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
      notifyListeners();
      return _subscribed;
    } catch (_) {
      _customerInfoSynced = false;
      _errorMessage = '訂閱狀態同步失敗';
      notifyListeners();
      return _subscribed;
    }
  }

  Future<bool> purchase(SubscriptionPlan plan) async {
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
    if (!_configured) {
      await init();
    }

    _setLoading(true);
    try {
      final customerInfo = await Purchases.restorePurchases();
      _subscribed = _hasActiveEntitlement(customerInfo);
      _customerInfoSynced = true;
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

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
