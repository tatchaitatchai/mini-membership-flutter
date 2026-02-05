import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/services/api_client.dart';
import '../domain/inventory.dart';

class InventoryRepository {
  final ApiClient _apiClient;

  InventoryRepository(this._apiClient);

  Future<bool> adjustStock({
    required int productId,
    required int quantity,
    required String reason,
    String? note,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/v2/inventory/adjust',
      body: {
        'product_id': productId,
        'quantity': quantity,
        'reason': reason,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      requireAuth: true,
      fromJson: (json) => json,
    );
    return response.isSuccess;
  }

  Future<List<InventoryMovement>> getMovements({int limit = 20, int offset = 0}) async {
    final response = await _apiClient.getList<InventoryMovement>(
      '/api/v2/inventory/movements?limit=$limit&offset=$offset',
      requireAuth: true,
      fromJson: InventoryMovement.fromJson,
    );
    return response.data ?? [];
  }

  Future<LowStockResponse?> getLowStockItems() async {
    final response = await _apiClient.get<LowStockResponse>(
      '/api/v2/inventory/low-stock',
      requireAuth: true,
      fromJson: LowStockResponse.fromJson,
    );
    return response.data;
  }
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.read(apiClientProvider));
});
