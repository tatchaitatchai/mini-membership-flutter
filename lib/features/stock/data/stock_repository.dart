import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/services/api_client.dart';
import '../domain/stock_log.dart';
import '../domain/stock_transfer.dart';

class StockRepository {
  final ApiClient _apiClient;
  final List<StockLog> _logs = [];

  StockRepository(this._apiClient);

  Future<void> receiveGoods({
    required String productId,
    required String productName,
    required int quantity,
    required String staffName,
    required String deliveredBy,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final log = StockLog(
      id: 'LOG_${DateTime.now().millisecondsSinceEpoch}',
      type: StockLogType.receive,
      productId: productId,
      productName: productName,
      quantity: quantity,
      staffName: staffName,
      deliveredBy: deliveredBy,
      createdAt: DateTime.now(),
    );

    _logs.add(log);
  }

  Future<void> withdrawGoodsLocal({
    required String productId,
    required String productName,
    required int quantity,
    required String staffName,
    String? sourceBranch,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final log = StockLog(
      id: 'LOG_${DateTime.now().millisecondsSinceEpoch}',
      type: StockLogType.withdraw,
      productId: productId,
      productName: productName,
      quantity: quantity,
      staffName: staffName,
      sourceBranch: sourceBranch,
      createdAt: DateTime.now(),
    );

    _logs.add(log);
  }

  Future<void> adjustStock({
    required String productId,
    required String productName,
    required int quantity,
    required String staffName,
    required AdjustmentType type,
    required String reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final log = StockLog(
      id: 'LOG_${DateTime.now().millisecondsSinceEpoch}',
      type: StockLogType.adjust,
      productId: productId,
      productName: productName,
      quantity: quantity,
      staffName: staffName,
      reason: '${type.name}: $reason',
      createdAt: DateTime.now(),
    );

    _logs.add(log);
  }

  Future<List<StockLog>> getAllLogs() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_logs.reversed);
  }

  Future<List<StockLog>> getLogsByType(StockLogType type) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _logs.where((log) => log.type == type).toList().reversed.toList();
  }

  // API-based methods for stock transfers
  Future<StockTransfer?> withdrawGoods({required List<Map<String, dynamic>> items, String? note}) async {
    final response = await _apiClient.post<StockTransfer>(
      '/api/v2/stock-transfers/withdraw',
      body: {'items': items, 'note': note},
      requireAuth: true,
      fromJson: StockTransfer.fromJson,
    );
    return response.data;
  }

  Future<StockTransferListResponse?> getTransfers({int limit = 20, int offset = 0}) async {
    final response = await _apiClient.get<StockTransferListResponse>(
      '/api/v2/stock-transfers?limit=$limit&offset=$offset',
      requireAuth: true,
      fromJson: StockTransferListResponse.fromJson,
    );
    return response.data;
  }

  Future<StockTransfer?> getTransferById(int id) async {
    final response = await _apiClient.get<StockTransfer>(
      '/api/v2/stock-transfers/$id',
      requireAuth: true,
      fromJson: StockTransfer.fromJson,
    );
    return response.data;
  }

  Future<List<StockTransfer>> getPendingTransfers() async {
    final response = await _apiClient.getList<StockTransfer>(
      '/api/v2/stock-transfers/pending',
      requireAuth: true,
      fromJson: StockTransfer.fromJson,
    );
    return response.data ?? [];
  }

  Future<bool> receiveTransfer({required int transferId, required List<Map<String, dynamic>> items}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/v2/stock-transfers/$transferId/receive',
      body: {'items': items},
      requireAuth: true,
      fromJson: (json) => json,
    );
    return response.isSuccess;
  }
}

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepository(ref.read(apiClientProvider));
});
