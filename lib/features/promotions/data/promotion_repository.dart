import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/promotion.dart';

class PromotionRepository {
  final List<Promotion> _promotions = const [
    Promotion(
      id: 'PROMO001',
      name: '10% Off',
      description: 'Get 10% off your entire order',
      type: PromotionType.percentage,
      value: 10,
    ),
    Promotion(
      id: 'PROMO002',
      name: '20% Off',
      description: 'Get 20% off your entire order',
      type: PromotionType.percentage,
      value: 20,
    ),
    Promotion(
      id: 'PROMO003',
      name: '\$5 Off',
      description: 'Get \$5 off your order',
      type: PromotionType.fixedAmount,
      value: 5,
    ),
    Promotion(
      id: 'PROMO004',
      name: 'Buy 2 Get 1',
      description: 'Buy 2 items, get 1 free',
      type: PromotionType.buyXGetY,
      value: 2,
    ),
  ];

  Future<List<Promotion>> getActivePromotions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _promotions.where((p) => p.isActive).toList();
  }

  Promotion? getById(String id) {
    try {
      return _promotions.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

final promotionRepositoryProvider = Provider<PromotionRepository>((ref) {
  return PromotionRepository();
});
