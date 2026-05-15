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
  bool get isAvailable => package != null;
}

class RevenueCatService extends ChangeNotifier {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  bool _configured = false;
  bool _loading = false;
  bool _subscribed = false;
  String? _errorMessage;
  Offering? _currentOffering;

  bool get isLoading => _loading;
  bool get isConfigured => _configured;
  bool get isSubscribed => _subscribed;
  String? get errorMessage => _errorMessage;
  bool get hasProducts => plans.any((plan) => plan.isAvailable);

  List<SubscriptionPlan> get plans {
    final monthly = _findPackage(
      AppConstants.monthlyProductId,
      PackageType.monthly,
    );
    final quarterly = _findPackage(
      AppConstants.quarterlyProductId,
      PackageType.threeMonth,
    );
    final yearly = _findPackage(
      AppConstants.yearlyProductId,
      PackageType.annual,
    );

    return [
      SubscriptionPlan(
        id: AppConstants.monthlyProductId,
        title: 'Monthly',
        subtitle: '每月彈性使用',
        fallbackPrice: AppConstants.monthlyPriceDisplay,
        badge: '',
        package: monthly,
      ),
      SubscriptionPlan(
        id: AppConstants.quarterlyProductId,
        title: 'Quarterly',
        subtitle: '3 個月，最適合測試成效',
        fallbackPrice: AppConstants.quarterlyPriceDisplay,
        badge: '推薦',
        package: quarterly,
      ),
      SubscriptionPlan(
        id: AppConstants.yearlyProductId,
        title: 'Yearly',
        subtitle: '一年完整使用，單月成本最低',
        fallbackPrice: AppConstants.yearlyPriceDisplay,
        badge: '最划算',
        package: yearly,
      ),
    ];
  }

  Future<bool> init() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      _errorMessage = 'RevenueCat 目前只在 iOS 啟用';
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
    if (!_configured) {
      await init();
      return;
    }

    _setLoading(true);
    try {
      final offerings = await Purchases.getOfferings();
      _currentOffering = offerings.current;
      _errorMessage = null;
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
      _errorMessage = null;
      notifyListeners();
      return _subscribed;
    } catch (_) {
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

  Package? _findPackage(String productId, PackageType packageType) {
    final packages = _currentOffering?.availablePackages ?? const <Package>[];
    for (final package in packages) {
      if (package.storeProduct.identifier == productId) {
        return package;
      }
    }
    for (final package in packages) {
      if (package.packageType == packageType) {
        return package;
      }
    }
    return null;
  }

  bool _hasActiveEntitlement(CustomerInfo customerInfo) {
    if (customerInfo.entitlements.active.containsKey(
      AppConstants.proEntitlementId,
    )) {
      return true;
    }
    return customerInfo.entitlements.active.isNotEmpty;
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
