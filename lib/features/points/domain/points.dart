class CustomerPointsInfo {
  final int customerId;
  final String customerName;
  final String customerCode;
  final List<CustomerProductPoints> products;

  const CustomerPointsInfo({
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.products,
  });

  factory CustomerPointsInfo.fromJson(Map<String, dynamic> json) {
    return CustomerPointsInfo(
      customerId: json['customer_id'] as int,
      customerName: json['customer_name'] as String? ?? '',
      customerCode: json['customer_code'] as String? ?? '',
      products:
          (json['products'] as List<dynamic>?)
              ?.map((e) => CustomerProductPoints.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CustomerProductPoints {
  final int productId;
  final String productName;
  final String? categoryName;
  final String? imagePath;
  final int points;
  final int totalPoints;
  final int pointsToRedeem;
  final bool canRedeem;

  const CustomerProductPoints({
    required this.productId,
    required this.productName,
    this.categoryName,
    this.imagePath,
    required this.points,
    required this.totalPoints,
    required this.pointsToRedeem,
    required this.canRedeem,
  });

  factory CustomerProductPoints.fromJson(Map<String, dynamic> json) {
    return CustomerProductPoints(
      productId: json['product_id'] as int,
      productName: json['product_name'] as String? ?? '',
      categoryName: json['category_name'] as String?,
      imagePath: json['image_path'] as String?,
      points: json['points'] as int? ?? 0,
      totalPoints: json['total_points'] as int? ?? 0,
      pointsToRedeem: json['points_to_redeem'] as int? ?? 0,
      canRedeem: json['can_redeem'] as bool? ?? false,
    );
  }
}

class RedeemableProduct {
  final int id;
  final String productName;
  final String? categoryName;
  final String? imagePath;
  final int pointsToRedeem;
  final int onStock;

  const RedeemableProduct({
    required this.id,
    required this.productName,
    this.categoryName,
    this.imagePath,
    required this.pointsToRedeem,
    required this.onStock,
  });

  factory RedeemableProduct.fromJson(Map<String, dynamic> json) {
    return RedeemableProduct(
      id: json['id'] as int,
      productName: json['product_name'] as String,
      categoryName: json['category_name'] as String?,
      imagePath: json['image_path'] as String?,
      pointsToRedeem: json['points_to_redeem'] as int,
      onStock: json['on_stock'] as int? ?? 0,
    );
  }
}

class RedeemableProductsResponse {
  final List<RedeemableProduct> products;

  const RedeemableProductsResponse({required this.products});

  factory RedeemableProductsResponse.fromJson(Map<String, dynamic> json) {
    return RedeemableProductsResponse(
      products:
          (json['products'] as List<dynamic>?)
              ?.map((e) => RedeemableProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class RedeemPointsRequest {
  final int customerId;
  final int productId;
  final int quantity;

  const RedeemPointsRequest({required this.customerId, required this.productId, required this.quantity});

  Map<String, dynamic> toJson() => {'customer_id': customerId, 'product_id': productId, 'quantity': quantity};
}

class RedeemPointsResponse {
  final int redemptionId;
  final int pointsUsed;
  final int remainingPoints;
  final String productName;
  final int quantity;
  final String message;

  const RedeemPointsResponse({
    required this.redemptionId,
    required this.pointsUsed,
    required this.remainingPoints,
    required this.productName,
    required this.quantity,
    required this.message,
  });

  factory RedeemPointsResponse.fromJson(Map<String, dynamic> json) {
    return RedeemPointsResponse(
      redemptionId: json['redemption_id'] as int,
      pointsUsed: json['points_used'] as int,
      remainingPoints: json['remaining_points'] as int,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      message: json['message'] as String,
    );
  }
}

class PointHistoryItem {
  final int id;
  final String transactionType;
  final int pointsChange;
  final String? productName;
  final String? note;
  final DateTime createdAt;

  const PointHistoryItem({
    required this.id,
    required this.transactionType,
    required this.pointsChange,
    this.productName,
    this.note,
    required this.createdAt,
  });

  factory PointHistoryItem.fromJson(Map<String, dynamic> json) {
    return PointHistoryItem(
      id: json['id'] as int,
      transactionType: json['transaction_type'] as String,
      pointsChange: json['points_change'] as int,
      productName: json['product_name'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class PointHistoryResponse {
  final int customerId;
  final List<PointHistoryItem> history;
  final int total;

  const PointHistoryResponse({required this.customerId, required this.history, required this.total});

  factory PointHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PointHistoryResponse(
      customerId: json['customer_id'] as int,
      history:
          (json['history'] as List<dynamic>?)
              ?.map((e) => PointHistoryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
    );
  }
}
