import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/secondary_button.dart';
import '../../../../common/widgets/money_text_field.dart';
import '../../../../common/utils/formatters.dart';
import '../../../customers/domain/customer.dart';
import '../../../customers/data/customer_repository.dart';
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
  final _cashAmountController = TextEditingController();
  final _transferAmountController = TextEditingController();
  final _last4Controller = TextEditingController();
  File? _slipImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _cashAmountController.dispose();
    _transferAmountController.dispose();
    _last4Controller.dispose();
    super.dispose();
  }

  double get _cashAmount => double.tryParse(_cashAmountController.text) ?? 0;
  double get _transferAmount => double.tryParse(_transferAmountController.text) ?? 0;
  double get _totalReceived => _cashAmount + _transferAmount;
  double get _change => _cashAmount > 0 ? (_totalReceived - _total).clamp(0, _cashAmount) : 0;

  Widget _buildPlaceholderImage({double size = 56}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
      child: Icon(Icons.inventory_2, color: Colors.grey.shade400, size: size * 0.5),
    );
  }

  Future<void> _pickSlipImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกรูปสลิป'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ถ่ายรูป'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกจากคลังรูป'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => _slipImage = File(pickedFile.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ไม่สามารถเปิดกล้องได้: $e')));
    }
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
    if (_cashAmountController.text.isEmpty && _transferAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกจำนวนเงิน')));
      return;
    }

    if (_totalReceived < _total) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เงินไม่เพียงพอ')));
      return;
    }

    if (_transferAmount > 0 && _slipImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาถ่ายรูปสลิปโอนเงิน')));
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
      cashReceived: _cashAmount,
      transferAmount: _transferAmount,
      change: _change,
      promotionId: _selectedPromotion?.id,
      attachedSlipUrl: _slipImage?.path,
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
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: product.imageUrl != null
                                  ? Image.network(
                                      product.imageUrl!,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                                    )
                                  : _buildPlaceholderImage(),
                            ),
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
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: product.imageUrl != null
                                        ? Image.network(
                                            product.imageUrl!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _buildPlaceholderImage(size: 40),
                                          )
                                        : _buildPlaceholderImage(size: 40),
                                  ),
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
    final remaining = _total - _totalReceived;
    final isPaymentComplete = remaining <= 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
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
            const Text('ช่องทางชำระเงิน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: MoneyTextField(
                    controller: _cashAmountController,
                    label: 'เงินสด',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: MoneyTextField(
                    controller: _transferAmountController,
                    label: 'โอนเงิน',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_transferAmount > 0) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('สลิปโอนเงิน', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (_slipImage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_slipImage!, height: 200, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickSlipImage,
                              icon: const Icon(Icons.camera_alt),
                              label: Text(_slipImage == null ? 'ถ่ายรูปสลิป' : 'ถ่ายใหม่'),
                            ),
                          ),
                          if (_slipImage != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => setState(() => _slipImage = null),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              color: isPaymentComplete ? Colors.green.shade50 : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryRow('รับเงินสด', Formatters.formatMoney(_cashAmount)),
                    _buildSummaryRow('รับโอน', Formatters.formatMoney(_transferAmount)),
                    const Divider(),
                    _buildSummaryRow('รวมรับ', Formatters.formatMoney(_totalReceived), isTotal: true),
                    if (!isPaymentComplete)
                      _buildSummaryRow('ยังขาดอีก', Formatters.formatMoney(remaining), isTotal: true)
                    else if (_change > 0)
                      _buildSummaryRow('เงินทอน', Formatters.formatMoney(_change), isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'ชำระเงินเสร็จสิ้น',
              onPressed: isPaymentComplete ? _completeOrder : null,
              isLoading: _isLoading,
              fullWidth: true,
            ),
          ],
        ),
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
