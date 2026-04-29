import 'package:ai_love_keyboard/utils/constants.dart';

enum SituationType {
  argument,
  breakup,
  confession,
  escalation,
  leftOnRead,
}

class SituationPackage {
  final SituationType type;
  final String name;
  final String emoji;
  final String description;
  final double price;
  final List<String> features;
  final String productId;
  final int totalUses;

  const SituationPackage({
    required this.type,
    required this.name,
    required this.emoji,
    required this.description,
    required this.price,
    required this.features,
    required this.productId,
    required this.totalUses,
  });

  static const List<SituationPackage> allPackages = [
    SituationPackage(
      type: SituationType.argument,
      name: '吵架急救包',
      emoji: '\u{1F54A}\uFE0F',
      description: '化解衝突、修復關係的專業工具包',
      price: 4.99,
      features: [
        '5 次深度和好分析',
        '道歉信模板',
        '專業和好話術',
      ],
      productId: AppConstants.argumentPackageId,
      totalUses: 5,
    ),
    SituationPackage(
      type: SituationType.breakup,
      name: '挽回禮包',
      emoji: '\u{1F494}',
      description: '科學挽回策略，重新贏回對方的心',
      price: 9.99,
      features: [
        '10 次挽回策略分析',
        '冷靜期教練指導',
        '復合話術生成',
      ],
      productId: AppConstants.breakupPackageId,
      totalUses: 10,
    ),
    SituationPackage(
      type: SituationType.confession,
      name: '表白禮包',
      emoji: '\u{1F498}',
      description: '完美表白方案，提升成功率',
      price: 3.99,
      features: [
        '5 種表白方案設計',
        '時機分析建議',
        '被拒備案策略',
      ],
      productId: AppConstants.confessionPackageId,
      totalUses: 5,
    ),
    SituationPackage(
      type: SituationType.escalation,
      name: '升溫禮包',
      emoji: '\u{1F525}',
      description: '從曖昧到確認關係的進階攻略',
      price: 3.99,
      features: [
        '進階撩人話術',
        '約會邀請生成',
        '關係推進策略',
      ],
      productId: AppConstants.escalationPackageId,
      totalUses: 5,
    ),
    SituationPackage(
      type: SituationType.leftOnRead,
      name: '已讀不回急救',
      emoji: '\u{1F198}',
      description: '專業破冰，重新開啟對話',
      price: 2.99,
      features: [
        '3 次專業分析',
        '破冰重啟話術',
        '最佳重發時機建議',
      ],
      productId: AppConstants.leftOnReadPackageId,
      totalUses: 3,
    ),
  ];

  static SituationPackage getPackage(SituationType type) {
    return allPackages.firstWhere((p) => p.type == type);
  }
}
