class Order {
  final String id;
  final String customerId;
  final String customerName;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final double cashReceived;
  final double transferAmount;
  final double change;
  final String? promotionId;
  final String? attachedSlipUrl;
  final OrderStatus status;
  final DateTime createdAt;
  final String createdBy;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  const Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.cashReceived,
    this.transferAmount = 0,
    required this.change,
    this.promotionId,
    this.attachedSlipUrl,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.cancelledBy,
    this.cancelledAt,
    this.cancellationReason,
  });

  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    List<OrderItem>? items,
    double? subtotal,
    double? discount,
    double? total,
    double? cashReceived,
    double? transferAmount,
    double? change,
    String? promotionId,
    String? attachedSlipUrl,
    OrderStatus? status,
    DateTime? createdAt,
    String? createdBy,
    String? cancelledBy,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      cashReceived: cashReceived ?? this.cashReceived,
      transferAmount: transferAmount ?? this.transferAmount,
      change: change ?? this.change,
      promotionId: promotionId ?? this.promotionId,
      attachedSlipUrl: attachedSlipUrl ?? this.attachedSlipUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double total;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
  });
}

enum OrderStatus { pending, completed, cancelled }
