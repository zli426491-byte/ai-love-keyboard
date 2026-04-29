/// Coin package available for purchase.
class CoinPackage {
  final String id;
  final int coins;
  final double price;
  final int bonusCoins;
  final String productId;
  final bool isPopular;
  final bool isBestValue;

  const CoinPackage({
    required this.id,
    required this.coins,
    required this.price,
    this.bonusCoins = 0,
    required this.productId,
    this.isPopular = false,
    this.isBestValue = false,
  });

  int get totalCoins => coins + bonusCoins;

  static const List<CoinPackage> allPackages = [
    CoinPackage(
      id: 'coins_10',
      coins: 10,
      price: 0.99,
      productId: 'com.ailovekeyboard.coins.10',
    ),
    CoinPackage(
      id: 'coins_30',
      coins: 30,
      price: 2.49,
      bonusCoins: 5,
      productId: 'com.ailovekeyboard.coins.30',
      isPopular: true,
    ),
    CoinPackage(
      id: 'coins_60',
      coins: 60,
      price: 4.49,
      bonusCoins: 15,
      productId: 'com.ailovekeyboard.coins.60',
    ),
    CoinPackage(
      id: 'coins_100',
      coins: 100,
      price: 6.99,
      bonusCoins: 30,
      productId: 'com.ailovekeyboard.coins.100',
      isBestValue: true,
    ),
  ];
}

/// Coin costs for each feature.
class CoinCost {
  CoinCost._();

  static const int emergencyCoach = 3;
  static const int argumentPackage = 5;
  static const int breakupAnalysis = 8;
  static const int confessionPlan = 3;
  static const int leftOnRead = 2;

  /// Daily login reward.
  static const int dailyLogin = 1;

  /// Watch ad reward (future).
  static const int watchAd = 2;

  /// Invite friend reward.
  static const int inviteFriend = 5;
}
