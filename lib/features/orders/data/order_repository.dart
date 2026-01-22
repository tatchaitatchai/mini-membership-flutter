import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/order.dart';

class OrderRepository {
  final List<Order> _orders = [];

  Future<void> createOrder(Order order) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _orders.add(order);
  }

  Future<List<Order>> getAllOrders() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_orders.reversed);
  }

  Future<Order?> getOrderById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> cancelOrder(String orderId, String managerName, String reason) async {
    await Future.delayed(const Duration(milliseconds: 500));
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
  return OrderRepository();
});
