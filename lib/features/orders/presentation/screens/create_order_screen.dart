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
import '../../data/models/order_models.dart';
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
  Map<String, int> _cart = {};
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
    return _calculatePromotionDiscount(_selectedPromotion!, _subtotal);
  }

  double _calculatePromotionDiscount(Promotion promo, double subtotal) {
    final config = promo.config;
    if (promo.isBillLevel) {
      if (config.percentDiscount != null) {
        return subtotal * (config.percentDiscount! / 100);
      }
      if (config.bahtDiscount != null) {
        return config.bahtDiscount!;
      }
    }
    // For product-level promotions, calculate based on matching products
    if (config.percentDiscount != null) {
      final matchingTotal = _getMatchingProductsTotal(promo);
      return matchingTotal * (config.percentDiscount! / 100);
    }
    if (config.bahtDiscount != null) {
      final matchingQty = _getMatchingProductsQty(promo);
      return config.bahtDiscount! * matchingQty;
    }
    if (config.totalPriceSetDiscount != null && config.oldPriceSet != null) {
      if (_hasAllSetProducts(promo)) {
        return config.oldPriceSet! - config.totalPriceSetDiscount!;
      }
    }
    return 0;
  }

  double _getMatchingProductsTotal(Promotion promo) {
    final productIds = promo.products.map((p) => p.productId).toSet();
    double total = 0;
    for (var entry in _cart.entries) {
      final product = ref.read(productRepositoryProvider).getProductById(entry.key);
      if (product != null && productIds.contains(int.tryParse(product.id))) {
        total += product.price * entry.value;
      }
    }
    return total;
  }

  int _getMatchingProductsQty(Promotion promo) {
    final productIds = promo.products.map((p) => p.productId).toSet();
    int qty = 0;
    for (var entry in _cart.entries) {
      final product = ref.read(productRepositoryProvider).getProductById(entry.key);
      if (product != null && productIds.contains(int.tryParse(product.id))) {
        qty += entry.value;
      }
    }
    return qty;
  }

  bool _hasAllSetProducts(Promotion promo) {
    final requiredIds = promo.products.map((p) => p.productId).toSet();
    for (var entry in _cart.entries) {
      final product = ref.read(productRepositoryProvider).getProductById(entry.key);
      if (product != null && entry.value > 0) {
        requiredIds.remove(int.tryParse(product.id));
      }
    }
    return requiredIds.isEmpty;
  }

  double get _total => _subtotal - _discount;

  Future<void> _completeOrder(double cashAmount, double transferAmount, File? slipImage) async {
    setState(() => _isLoading = true);

    final change = cashAmount > 0 ? ((cashAmount + transferAmount) - _total).clamp(0.0, cashAmount) : 0.0;

    // Build API request items
    final apiItems = <OrderItemRequest>[];
    final orderItems = <OrderItem>[];
    for (var entry in _cart.entries) {
      final product = ref.read(productRepositoryProvider).getProductById(entry.key)!;
      apiItems.add(OrderItemRequest(productId: int.parse(product.id), quantity: entry.value, price: product.price));
      orderItems.add(
        OrderItem(
          productId: product.id,
          productName: product.name,
          price: product.price,
          quantity: entry.value,
          total: product.price * entry.value,
        ),
      );
    }

    // Build payments
    final payments = <PaymentRequest>[];
    if (cashAmount > 0) {
      payments.add(PaymentRequest(method: 'CASH', amount: cashAmount));
    }
    if (transferAmount > 0) {
      payments.add(PaymentRequest(method: 'TRANSFER', amount: transferAmount));
    }

    // Call API to create order
    final orderRepo = ref.read(orderRepositoryProvider);
    final apiResponse = await orderRepo.createOrderApi(
      customerId: _selectedCustomer?.id != 'guest' ? int.tryParse(_selectedCustomer?.id ?? '') : null,
      items: apiItems,
      subtotal: _subtotal,
      discountTotal: _discount,
      totalPrice: _total,
      payments: payments,
      changeAmount: change,
      promotionId: _selectedPromotion?.id,
    );

    if (!mounted) return;

    if (apiResponse != null) {
      // Update local stock cache
      for (var entry in _cart.entries) {
        await ref.read(productRepositoryProvider).reduceStock(entry.key, entry.value);
      }

      final order = Order(
        id: apiResponse.orderId.toString(),
        customerId: _selectedCustomer?.id ?? 'guest',
        customerName: _selectedCustomer?.fullName ?? 'Guest',
        items: orderItems,
        subtotal: _subtotal,
        discount: _discount,
        total: _total,
        cashReceived: cashAmount,
        transferAmount: transferAmount,
        change: change,
        promotionId: _selectedPromotion?.id.toString(),
        attachedSlipUrl: slipImage?.path,
        status: OrderStatus.completed,
        createdAt: apiResponse.createdAt,
        createdBy: ref.read(authRepositoryProvider).getCurrentStaffName() ?? 'Staff',
      );

      _showOrderSuccessDialog(order);
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่สามารถสร้างออร์เดอร์ได้ กรุณาลองใหม่')));
    }
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
      // Create new Map to trigger widget rebuild
      final newCart = Map<String, int>.from(_cart);
      if (quantity <= 0) {
        newCart.remove(productId);
      } else {
        newCart[productId] = quantity;
      }
      _cart = newCart;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างออร์เดอร์'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
      ),
      body: SafeArea(child: _buildStepContent()),
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
          subtotal: _subtotal,
          cart: _cart,
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
