class ProductInfo {
  final int id;
  final String productName;
  final String? categoryName;
  final double basePrice;
  final String? imagePath;
  final int onStock;

  ProductInfo({
    required this.id,
    required this.productName,
    this.categoryName,
    required this.basePrice,
    this.imagePath,
    required this.onStock,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id'] as int,
      productName: json['product_name'] as String,
      categoryName: json['category_name'] as String?,
      basePrice: (json['base_price'] as num).toDouble(),
      imagePath: json['image_path'] as String?,
      onStock: json['on_stock'] as int,
    );
  }
}

class ListProductsResponse {
  final List<ProductInfo> products;

  ListProductsResponse({required this.products});

  factory ListProductsResponse.fromJson(Map<String, dynamic> json) {
    return ListProductsResponse(
      products: (json['products'] as List).map((e) => ProductInfo.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class CustomerInfo {
  final int id;
  final String customerCode;
  final String fullName;
  final String phoneLast4;

  CustomerInfo({required this.id, required this.customerCode, required this.fullName, required this.phoneLast4});

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      id: json['id'] as int,
      customerCode: json['customer_code'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phoneLast4: json['phone_last4'] as String? ?? '',
    );
  }
}

class SearchCustomersResponse {
  final List<CustomerInfo> customers;

  SearchCustomersResponse({required this.customers});

  factory SearchCustomersResponse.fromJson(Map<String, dynamic> json) {
    return SearchCustomersResponse(
      customers: (json['customers'] as List).map((e) => CustomerInfo.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class OrderItemRequest {
  final int productId;
  final int quantity;
  final double price;

  OrderItemRequest({required this.productId, required this.quantity, required this.price});

  Map<String, dynamic> toJson() {
    return {'product_id': productId, 'quantity': quantity, 'price': price};
  }
}

class PaymentRequest {
  final String method;
  final double amount;

  PaymentRequest({required this.method, required this.amount});

  Map<String, dynamic> toJson() {
    return {'method': method, 'amount': amount};
  }
}

class CreateOrderRequest {
  final int? customerId;
  final List<OrderItemRequest> items;
  final double subtotal;
  final double discountTotal;
  final double totalPrice;
  final List<PaymentRequest> payments;
  final double changeAmount;
  final int? promotionId;

  CreateOrderRequest({
    this.customerId,
    required this.items,
    required this.subtotal,
    required this.discountTotal,
    required this.totalPrice,
    required this.payments,
    required this.changeAmount,
    this.promotionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'discount_total': discountTotal,
      'total_price': totalPrice,
      'payments': payments.map((e) => e.toJson()).toList(),
      'change_amount': changeAmount,
      'promotion_id': promotionId,
    };
  }
}

class CreateOrderResponse {
  final int orderId;
  final String status;
  final double totalPrice;
  final double changeAmount;
  final DateTime createdAt;

  CreateOrderResponse({
    required this.orderId,
    required this.status,
    required this.totalPrice,
    required this.changeAmount,
    required this.createdAt,
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) {
    return CreateOrderResponse(
      orderId: json['order_id'] as int,
      status: json['status'] as String,
      totalPrice: (json['total_price'] as num).toDouble(),
      changeAmount: (json['change_amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
