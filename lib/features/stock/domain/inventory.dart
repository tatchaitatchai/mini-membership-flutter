class InventoryMovement {
  final int id;
  final int productId;
  final String productName;
  final String movementType;
  final int quantityChange;
  final int? fromStockCount;
  final int? toStockCount;
  final String? reason;
  final String? note;
  final String? changedByName;
  final DateTime createdAt;

  const InventoryMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.movementType,
    required this.quantityChange,
    this.fromStockCount,
    this.toStockCount,
    this.reason,
    this.note,
    this.changedByName,
    required this.createdAt,
  });

  factory InventoryMovement.fromJson(Map<String, dynamic> json) {
    return InventoryMovement(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      movementType: json['movement_type'] as String,
      quantityChange: json['quantity_change'] as int,
      fromStockCount: json['from_stock_count'] as int?,
      toStockCount: json['to_stock_count'] as int?,
      reason: json['reason'] as String?,
      note: json['note'] as String?,
      changedByName: json['changed_by_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get movementTypeDisplay {
    switch (movementType) {
      case 'SALE':
        return 'ขาย';
      case 'CANCEL_SALE':
        return 'ยกเลิกขาย';
      case 'RECEIVE':
        return 'รับเข้า';
      case 'ISSUE':
        return 'เบิกออก';
      case 'ADJUST':
        return 'ปรับสต็อก';
      case 'TRANSFER_IN':
        return 'โอนเข้า';
      case 'TRANSFER_OUT':
        return 'โอนออก';
      case 'DAMAGE':
        return 'ชำรุด/เสียหาย';
      default:
        return movementType;
    }
  }

  bool get isPositive => quantityChange > 0;
}

class LowStockItem {
  final int productId;
  final String productName;
  final String categoryName;
  final int onStock;
  final int reorderLevel;
  final int price;

  const LowStockItem({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.onStock,
    required this.reorderLevel,
    required this.price,
  });

  factory LowStockItem.fromJson(Map<String, dynamic> json) {
    return LowStockItem(
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      categoryName: json['category_name'] as String,
      onStock: json['on_stock'] as int,
      reorderLevel: json['reorder_level'] as int,
      price: json['price'] as int,
    );
  }

  bool get isCritical => onStock == 0;
  bool get isLow => onStock > 0 && onStock <= reorderLevel;
}

class LowStockResponse {
  final List<LowStockItem> items;
  final int totalCount;

  const LowStockResponse({
    required this.items,
    required this.totalCount,
  });

  factory LowStockResponse.fromJson(Map<String, dynamic> json) {
    return LowStockResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => LowStockItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['total_count'] as int? ?? 0,
    );
  }
}
