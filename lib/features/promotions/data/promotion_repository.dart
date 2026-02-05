import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/services/api_client.dart';
import '../domain/promotion.dart';

class PromotionRepository {
  final ApiClient _apiClient;

  PromotionRepository(this._apiClient);

  Future<List<Promotion>> getActivePromotions() async {
    final response = await _apiClient.getList<Promotion>(
      '/api/v2/promotions',
      requireAuth: true,
      fromJson: Promotion.fromJson,
    );
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    return [];
  }

  Future<CalculateDiscountResponse?> calculateDiscount({
    required int promotionId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
  }) async {
    final response = await _apiClient.post<CalculateDiscountResponse>(
      '/api/v2/promotions/calculate',
      body: {'promotion_id': promotionId, 'items': items, 'subtotal': subtotal},
      requireAuth: true,
      fromJson: CalculateDiscountResponse.fromJson,
    );
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    return null;
  }

  Future<List<DetectedPromotion>> detectPromotions({required List<Map<String, dynamic>> items}) async {
    try {
      final response = await _apiClient.postList<DetectedPromotion>(
        '/api/v2/promotions/detect',
        body: {'items': items},
        requireAuth: true,
        fromJson: DetectedPromotion.fromJson,
      );
      if (response.isSuccess && response.data != null) {
        return response.data!;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Promotion? getById(int id, List<Promotion> promotions) {
    try {
      return promotions.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

final promotionRepositoryProvider = Provider<PromotionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PromotionRepository(apiClient);
});
