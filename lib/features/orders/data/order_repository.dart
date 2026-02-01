import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/services/api_client.dart';
import '../domain/order.dart';
import 'models/order_models.dart';

class OrderRepository {
  final ApiClient _apiClient;
  final List<Order> _orders = [];

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
  }) async {
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

  Future<void> createOrder(Order order) async {
    _orders.add(order);
  }

  Future<List<Order>> getAllOrders() async {
    return List.from(_orders.reversed);
  }

  Future<Order?> getOrderById(String id) async {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> cancelOrder(String orderId, String managerName, String reason) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status: OrderStatus.cancelled,
        cancelledBy: managerName,
        cancelledAt: DateTime.now(),
        cancellationReason: reason,
      );
    }
  }

  List<Order> getCompletedOrders() {
    return _orders.where((o) => o.status == OrderStatus.completed).toList();
  }

  double getTotalSalesAmount() {
    return _orders.where((o) => o.status == OrderStatus.completed).fold(0.0, (sum, order) => sum + order.total);
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  throw UnimplementedError('OrderRepository must be initialized in main');
});
