import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/utils/formatters.dart';
import '../../../customers/domain/customer.dart';
import '../../../products/data/product_repository.dart';
import '../../../promotions/domain/promotion.dart';
import '../../domain/order.dart';
import '../../data/order_repository.dart';
import '../../../auth/data/auth_repository.dart';
import '../widgets/customer_step_widget.dart';
import '../widgets/products_step_widget.dart';
import '../widgets/promotion_step_widget.dart';
import '../widgets/payment_step_widget.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  int _step = 0;
  Customer? _selectedCustomer;
  final Map<String, int> _cart = {};
  Promotion? _selectedPromotion;
  bool _isLoading = false;

  double get _subtotal {
    double total = 0;
    for (var entry in _cart.entries) {
      final product = ref.read(productRepositoryProvider).getProductById(entry.key);
      if (product != null) {
        total += product.price * entry.value;
      }
    }
    return total;
  }

  double get _discount {
    if (_selectedPromotion == null) return 0;
    return _selectedPromotion!.calculateDiscount(_subtotal);
  }

  double get _total => _subtotal - _discount;

  Future<void> _completeOrder(double cashAmount, double transferAmount, File? slipImage) async {
    setState(() => _isLoading = true);

    final change = cashAmount > 0 ? ((cashAmount + transferAmount) - _total).clamp(0.0, cashAmount) : 0.0;

    final items = <OrderItem>[];
    for (var entry in _cart.entries) {
      final product = ref.read(productRepositoryProvider).getProductById(entry.key)!;
      items.add(
        OrderItem(
          productId: product.id,
          productName: product.name,
          price: product.price,
          quantity: entry.value,
          total: product.price * entry.value,
        ),
      );
      await ref.read(productRepositoryProvider).reduceStock(product.id, entry.value);
    }

    final order = Order(
      id: 'ORD_${DateTime.now().millisecondsSinceEpoch}',
      customerId: _selectedCustomer?.id ?? 'guest',
      customerName: _selectedCustomer?.fullName ?? 'Guest',
      items: items,
      subtotal: _subtotal,
      discount: _discount,
      total: _total,
      cashReceived: cashAmount,
      transferAmount: transferAmount,
      change: change,
      promotionId: _selectedPromotion?.id,
      attachedSlipUrl: slipImage?.path,
      status: OrderStatus.completed,
      createdAt: DateTime.now(),
      createdBy: ref.read(authRepositoryProvider).getCurrentStaffName() ?? 'Staff',
    );

    await ref.read(orderRepositoryProvider).createOrder(order);

    if (!mounted) return;

    _showOrderSuccessDialog(order);
  }

  void _showOrderSuccessDialog(Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('ออร์เดอร์สำเร็จ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('หมายเลขออร์เดอร์: ${order.id}'),
            const SizedBox(height: 8),
            Text('ยอดรวม: ${Formatters.formatMoney(order.total)}'),
            if (order.cashReceived > 0) Text('เงินสด: ${Formatters.formatMoney(order.cashReceived)}'),
            if (order.transferAmount > 0) Text('โอนเงิน: ${Formatters.formatMoney(order.transferAmount)}'),
            if (order.change > 0) Text('เงินทอน: ${Formatters.formatMoney(order.change)}'),
          ],
        ),
        actions: [
          PrimaryButton(
            text: 'เสร็จสิ้น',
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
          ),
        ],
      ),
    );
  }

  void _handleCartChanged(String productId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cart.remove(productId);
      } else {
        _cart[productId] = quantity;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างออร์เดอร์'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
      ),
      body: _buildStepContent(),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return CustomerStepWidget(
          onCustomerSelected: (customer) {
            setState(() {
              _selectedCustomer = customer;
              _step = 1;
            });
          },
        );
      case 1:
        return ProductsStepWidget(
          selectedCustomer: _selectedCustomer,
          cart: _cart,
          subtotal: _subtotal,
          discount: _discount,
          total: _total,
          onBack: () => setState(() => _step = 0),
          onNext: () => setState(() => _step = 2),
          onCartChanged: _handleCartChanged,
        );
      case 2:
        return PromotionStepWidget(
          selectedPromotion: _selectedPromotion,
          onBack: () => setState(() => _step = 1),
          onNext: () => setState(() => _step = 3),
          onPromotionSelected: (promotion) => setState(() => _selectedPromotion = promotion),
        );
      case 3:
        return PaymentStepWidget(
          subtotal: _subtotal,
          discount: _discount,
          total: _total,
          onBack: () => setState(() => _step = 2),
          onCompleteOrder: _completeOrder,
          isLoading: _isLoading,
        );
      default:
        return const SizedBox();
    }
  }
}
