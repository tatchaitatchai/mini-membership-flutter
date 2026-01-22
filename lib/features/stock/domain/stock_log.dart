class StockLog {
  final String id;
  final StockLogType type;
  final String productId;
  final String productName;
  final int quantity;
  final String staffName;
  final String? deliveredBy;
  final String? sourceBranch;
  final String? reason;
  final DateTime createdAt;

  const StockLog({
    required this.id,
    required this.type,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.staffName,
    this.deliveredBy,
    this.sourceBranch,
    this.reason,
    required this.createdAt,
  });
}

enum StockLogType { receive, withdraw, adjust }

class StockAdjustment {
  final String productId;
  final int quantity;
  final AdjustmentType type;
  final String reason;

  const StockAdjustment({required this.productId, required this.quantity, required this.type, required this.reason});
}

enum AdjustmentType { broken, lost, damaged, other }
