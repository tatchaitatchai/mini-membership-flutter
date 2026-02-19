import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../../../common/services/api_client.dart';
import '../domain/order.dart';
import 'models/order_models.dart';

class OrderRepository {
  final ApiClient _apiClient;

  OrderRepository(this._apiClient);

  Future<CreateOrderResponse?> createOrderApi({
    int? customerId,
    required List<OrderItemRequest> items,
    required double subtotal,
    required double discountTotal,
    required double totalPrice,
    required List<PaymentRequest> payments,
    required double changeAmount,
    int? promotionId,
    List<File>? slipImages,
  }) async {
    if (slipImages != null && slipImages.isNotEmpty) {
      return _createOrderWithSlip(
        customerId: customerId,
        items: items,
        subtotal: subtotal,
        discountTotal: discountTotal,
        totalPrice: totalPrice,
        payments: payments,
        changeAmount: changeAmount,
        promotionId: promotionId,
        slipImages: slipImages,
      );
    }

    final request = CreateOrderRequest(
      customerId: customerId,
      items: items,
      subtotal: subtotal,
      discountTotal: discountTotal,
      totalPrice: totalPrice,
      payments: payments,
      changeAmount: changeAmount,
      promotionId: promotionId,
    );

    final response = await _apiClient.post<CreateOrderResponse>(
      '/api/v2/orders',
      body: request.toJson(),
      requireAuth: true,
      fromJson: CreateOrderResponse.fromJson,
    );

    if (response.isSuccess && response.data != null) {
      return response.data;
    }
    return null;
  }

  Future<CreateOrderResponse?> _createOrderWithSlip({
    int? customerId,
    required List<OrderItemRequest> items,
    required double subtotal,
    required double discountTotal,
    required double totalPrice,
    required List<PaymentRequest> payments,
    required double changeAmount,
    int? promotionId,
    required List<File> slipImages,
  }) async {
    try {
      final sessionToken = await _apiClient.getSessionToken();
      if (sessionToken == null) {
        return null;
      }

      final baseUrl = _apiClient.baseUrl;
      final uri = Uri.parse('$baseUrl/api/v2/orders/with-slip');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $sessionToken';

      // Add order data as JSON string
      final orderData = {
        'customer_id': customerId,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'discount_total': discountTotal,
        'total_price': totalPrice,
        'payments': payments.map((p) => p.toJson()).toList(),
        'change_amount': changeAmount,
        if (promotionId != null) 'promotion_id': promotionId,
      };
      request.fields['order_data'] = jsonEncode(orderData);

      // Add multiple slip images
      for (var slipImage in slipImages) {
        // Detect content type from file extension
        final isWebP = slipImage.path.toLowerCase().endsWith('.webp');
        request.files.add(
          await http.MultipartFile.fromPath(
            'slip_images',
            slipImage.path,
            contentType: MediaType('image', isWebP ? 'webp' : 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return CreateOrderResponse.fromJson(jsonData);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Order>> getAllOrders() async {
    final response = await _apiClient.get<ListOrdersResponse>(
      '/api/v2/orders',
      requireAuth: true,
      fromJson: ListOrdersResponse.fromJson,
    );

    if (response.isSuccess && response.data != null) {
      return response.data!.orders
          .map(
            (o) => Order(
              id: o.id.toString(),
              customerId: o.customerId?.toString() ?? 'guest',
              customerName: o.customerName ?? 'Guest',
              items: o.items
                  .map(
                    (i) => OrderItem(
                      productId: i.productId.toString(),
                      productName: i.productName,
                      price: i.price,
                      quantity: i.quantity,
                      total: i.total,
                    ),
                  )
                  .toList(),
              subtotal: o.subtotal,
              discount: o.discountTotal,
              total: o.totalPrice,
              cashReceived: 0,
              transferAmount: 0,
              change: o.changeAmount,
              status: _parseOrderStatus(o.status),
              createdAt: o.createdAt,
              createdBy: o.createdBy,
            ),
          )
          .toList();
    }
    return [];
  }

  OrderStatus _parseOrderStatus(String status) {
    switch (status) {
      case 'PAID':
        return OrderStatus.completed;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'PENDING':
        return OrderStatus.pending;
      default:
        return OrderStatus.completed;
    }
  }

  Future<Order?> getOrderById(String id) async {
    final response = await _apiClient.get<OrderInfoResponse>(
      '/api/v2/orders/$id',
      requireAuth: true,
      fromJson: OrderInfoResponse.fromJson,
    );

    if (response.isSuccess && response.data != null) {
      final o = response.data!;
      return Order(
        id: o.id.toString(),
        customerId: o.customerId?.toString() ?? 'guest',
        customerName: o.customerName ?? 'Guest',
        items: o.items
            .map(
              (i) => OrderItem(
                productId: i.productId.toString(),
                productName: i.productName,
                price: i.price,
                quantity: i.quantity,
                total: i.total,
              ),
            )
            .toList(),
        subtotal: o.subtotal,
        discount: o.discountTotal,
        total: o.totalPrice,
        cashReceived: 0,
        transferAmount: 0,
        change: o.changeAmount,
        status: _parseOrderStatus(o.status),
        createdAt: o.createdAt,
        createdBy: o.createdBy,
      );
    }
    return null;
  }

  Future<bool> cancelOrderApi(int orderId, String reason, String staffPin) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/v2/orders/$orderId/cancel',
      body: {'reason': reason, 'staff_pin': staffPin},
      requireAuth: true,
      fromJson: (json) => json,
    );
    return response.isSuccess;
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  throw UnimplementedError('OrderRepository must be initialized in main');
});
