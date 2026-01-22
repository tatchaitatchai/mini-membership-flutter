import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/money_text_field.dart';
import '../../../../common/utils/formatters.dart';
import '../../data/auth_repository.dart';
import '../../../shift/data/shift_repository.dart';
import '../../../shift/domain/shift.dart';
import '../../../orders/data/order_repository.dart';
import '../../../products/data/product_repository.dart';

class EndShiftScreen extends ConsumerStatefulWidget {
  const EndShiftScreen({super.key});

  @override
  ConsumerState<EndShiftScreen> createState() => _EndShiftScreenState();
}

class _EndShiftScreenState extends ConsumerState<EndShiftScreen> {
  final _actualCashController = TextEditingController();
  final Map<String, TextEditingController> _stockControllers = {};
  bool _isLoading = false;
  ShiftSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadShiftSummary();
  }

  @override
  void dispose() {
    _actualCashController.dispose();
    for (var controller in _stockControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadShiftSummary() async {
    final shiftRepo = ref.read(shiftRepositoryProvider);
    final orderRepo = ref.read(orderRepositoryProvider);
    final orders = await orderRepo.getAllOrders();

    setState(() {
      _summary = shiftRepo.calculateShiftSummary(orders);
    });
  }

  Future<void> _handleEndShift() async {
    setState(() => _isLoading = true);

    final actualCash = double.tryParse(_actualCashController.text) ?? 0;
    final expectedCash = _summary?.expectedCash ?? 0;

    final productRepo = ref.read(productRepositoryProvider);
    final products = await productRepo.getAllProducts();

    final stockCounts = <String, StockCount>{};
    for (var product in products) {
      final actualStock = int.tryParse(_stockControllers[product.id]?.text ?? '${product.stock}') ?? product.stock;
      stockCounts[product.id] = StockCount(
        productId: product.id,
        productName: product.name,
        expected: product.stock,
        actual: actualStock,
        difference: actualStock - product.stock,
      );
    }

    final shiftRepo = ref.read(shiftRepositoryProvider);
    await shiftRepo.closeShift(actualCash: actualCash, expectedCash: expectedCash, stockCounts: stockCounts);

    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.logout();

    if (!mounted) return;

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_summary == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ปิดกะการทำงาน'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('สรุปกะการทำงาน', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildSummaryRow('ยอดขายรวม', Formatters.formatMoney(_summary!.totalSales)),
                    _buildSummaryRow('จำนวนออร์เดอร์', '${_summary!.orderCount}'),
                    _buildSummaryRow('เงินสดที่คาดไว้', Formatters.formatMoney(_summary!.expectedCash)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('นับเงินสด', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    MoneyTextField(
                      controller: _actualCashController,
                      label: 'เงิ้นสดจริงในลิ้นชัก',
                      hintText: 'กรอกจำนวนที่นับได้',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('นับสต็อกสินค้า', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    FutureBuilder(
                      future: ref.read(productRepositoryProvider).getAllProducts(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();

                        final products = snapshot.data!;
                        return Column(
                          children: products.map((product) {
                            _stockControllers.putIfAbsent(
                              product.id,
                              () => TextEditingController(text: '${product.stock}'),
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: Text(product.name)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextField(
                                      controller: _stockControllers[product.id],
                                      decoration: InputDecoration(labelText: 'จำนวน', hintText: '${product.stock}'),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'ปิดกะและออกจากระบบ',
              onPressed: _handleEndShift,
              isLoading: _isLoading,
              icon: Icons.exit_to_app,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
