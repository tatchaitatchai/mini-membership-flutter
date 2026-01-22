import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/secondary_button.dart';
import '../../../../common/widgets/money_text_field.dart';
import '../../../../common/utils/formatters.dart';
import '../../../customers/domain/customer.dart';
import '../../../customers/data/customer_repository.dart';
import '../../../products/domain/product.dart';
import '../../../products/data/product_repository.dart';
import '../../../promotions/domain/promotion.dart';
import '../../../promotions/data/promotion_repository.dart';
import '../../../orders/domain/order.dart';
import '../../../orders/data/order_repository.dart';
import '../../../auth/data/auth_repository.dart';

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
  final _cashReceivedController = TextEditingController();
  final _last4Controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cashReceivedController.dispose();
    _last4Controller.dispose();
    super.dispose();
  }

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

  Future<void> _searchCustomer() async {
    final last4 = _last4Controller.text.trim();
    if (last4.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรอกตัวเลข 4 หลัก')));
      return;
    }

    setState(() => _isLoading = true);
    final customerRepo = ref.read(customerRepositoryProvider);
    final customers = await customerRepo.findByLast4(last4);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลลูกค้า')));
    } else if (customers.length == 1) {
      setState(() {
        _selectedCustomer = customers.first;
        _step = 1;
      });
    } else {
      _showCustomerSelection(customers);
    }
  }

  void _showCustomerSelection(List<Customer> customers) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกลูกค้า'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: customers.map((customer) {
            return ListTile(
              title: Text(customer.fullName),
              subtitle: Text(customer.code),
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedCustomer = customer;
                  _step = 1;
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _completeOrder() async {
    if (_cashReceivedController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกเงินที่รับมา')));
      return;
    }

    final cashReceived = double.tryParse(_cashReceivedController.text) ?? 0;
    if (cashReceived < _total) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เงินไม่เพียงพอ')));
      return;
    }

    setState(() => _isLoading = true);

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
      cashReceived: cashReceived,
      change: cashReceived - _total,
      promotionId: _selectedPromotion?.id,
      status: OrderStatus.completed,
      createdAt: DateTime.now(),
      createdBy: ref.read(authRepositoryProvider).getCurrentStaffName() ?? 'Staff',
    );

    await ref.read(orderRepositoryProvider).createOrder(order);

    if (!mounted) return;

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
            Text('เงินสด: ${Formatters.formatMoney(order.cashReceived)}'),
            Text('เงินทอน: ${Formatters.formatMoney(order.change)}'),
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
        return _buildCustomerStep();
      case 1:
        return _buildProductsStep();
      case 2:
        return _buildPromotionStep();
      case 3:
        return _buildPaymentStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildCustomerStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ขั้นตอนที่ 1: ระบุลูกค้า', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: _last4Controller,
            decoration: const InputDecoration(labelText: 'รหัสลูกค้า 4 หลักท้าย', hintText: 'กรอก 4 หลัก'),
            keyboardType: TextInputType.number,
            maxLength: 4,
          ),
          const SizedBox(height: 16),
          PrimaryButton(text: 'ค้นหา', onPressed: _searchCustomer, isLoading: _isLoading),
          const SizedBox(height: 16),
          SecondaryButton(
            text: 'ดำเนินการในฐานะแขก',
            onPressed: () {
              setState(() {
                _selectedCustomer = Customer.guest();
                _step = 1;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductsStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ขั้นตอนที่ 2: เลือกสินค้า',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('ลูกค้า: ${_selectedCustomer?.fullName}', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              SecondaryButton(text: 'ย้อนกลับ', onPressed: () => setState(() => _step = 0)),
              const SizedBox(width: 16),
              PrimaryButton(text: 'ถัดไป', onPressed: _cart.isEmpty ? null : () => setState(() => _step = 2)),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: FutureBuilder(
                  future: ref.read(productRepositoryProvider).getAllProducts(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final products = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final inCart = _cart[product.id] ?? 0;
                        final canAdd = product.stock > inCart;

                        return Card(
                          child: ListTile(
                            title: Text(product.name),
                            subtitle: Text('${Formatters.formatMoney(product.price)} • สต็อก: ${product.stock}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (inCart > 0) ...[
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      setState(() {
                                        _cart[product.id] = inCart - 1;
                                        if (_cart[product.id] == 0) {
                                          _cart.remove(product.id);
                                        }
                                      });
                                    },
                                  ),
                                  Text('$inCart', style: const TextStyle(fontSize: 18)),
                                ],
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: canAdd
                                      ? () {
                                          setState(() {
                                            _cart[product.id] = inCart + 1;
                                          });
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                width: 350,
                color: Colors.grey.shade100,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('ตะกร้า', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Expanded(
                      child: _cart.isEmpty
                          ? const Center(child: Text('ไม่มีสินค้า'))
                          : ListView(
                              children: _cart.entries.map((entry) {
                                final product = ref.read(productRepositoryProvider).getProductById(entry.key)!;
                                return ListTile(
                                  title: Text(product.name),
                                  subtitle: Text('${entry.value} x ${Formatters.formatMoney(product.price)}'),
                                  trailing: Text(
                                    Formatters.formatMoney(product.price * entry.value),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const Divider(),
                    _buildSummaryRow('ยอดรวมย่อย', Formatters.formatMoney(_subtotal)),
                    if (_discount > 0) _buildSummaryRow('ส่วนลด', '-${Formatters.formatMoney(_discount)}'),
                    _buildSummaryRow('ยอดรวม', Formatters.formatMoney(_total), isTotal: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ขั้นตอนที่ 3: ใช้โปรโมชั่น (ถ้ามี)',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              SecondaryButton(text: 'ย้อนกลับ', onPressed: () => setState(() => _step = 1)),
              const SizedBox(width: 16),
              PrimaryButton(text: 'ถัดไป', onPressed: () => setState(() => _step = 3)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder(
              future: ref.read(promotionRepositoryProvider).getActivePromotions(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Card(
                        color: _selectedPromotion == null ? Colors.blue.shade50 : null,
                        child: ListTile(
                          title: const Text('ไม่ใช้โปรโมชั่น'),
                          trailing: _selectedPromotion == null ? const Icon(Icons.check, color: Colors.blue) : null,
                          onTap: () {
                            setState(() => _selectedPromotion = null);
                          },
                        ),
                      );
                    }

                    final promotion = snapshot.data![index - 1];
                    return Card(
                      color: _selectedPromotion?.id == promotion.id ? Colors.blue.shade50 : null,
                      child: ListTile(
                        title: Text(promotion.name),
                        subtitle: Text(promotion.description),
                        trailing: _selectedPromotion?.id == promotion.id
                            ? const Icon(Icons.check, color: Colors.blue)
                            : Text(promotion.displayValue),
                        onTap: () {
                          setState(() => _selectedPromotion = promotion);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('ขั้นตอนที่ 4: ชำระเงิน', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              SecondaryButton(text: 'ย้อนกลับ', onPressed: () => setState(() => _step = 2)),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('สรุปออร์เดอร์', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildSummaryRow('ยอดรวมย่อย', Formatters.formatMoney(_subtotal)),
                  if (_discount > 0) _buildSummaryRow('ส่วนลด', '-${Formatters.formatMoney(_discount)}'),
                  _buildSummaryRow('ยอดรวม', Formatters.formatMoney(_total), isTotal: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          MoneyTextField(controller: _cashReceivedController, label: 'เงินที่รับมา', onChanged: (_) => setState(() {})),
          const SizedBox(height: 16),
          if (_cashReceivedController.text.isNotEmpty)
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildSummaryRow(
                  'เงินทอน',
                  Formatters.formatMoney((double.tryParse(_cashReceivedController.text) ?? 0) - _total),
                  isTotal: true,
                ),
              ),
            ),
          const SizedBox(height: 24),
          PrimaryButton(text: 'ชำระเงินเสร็จสิ้น', onPressed: _completeOrder, isLoading: _isLoading, fullWidth: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            value,
            style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
