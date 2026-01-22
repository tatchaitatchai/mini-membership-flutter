import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/stock_log.dart';

class StockRepository {
  final List<StockLog> _logs = [];

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

  Future<void> withdrawGoods({
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
}

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepository();
});
