import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../products/data/product_repository.dart';
import '../../../stock/data/stock_repository.dart';
import '../../../auth/data/auth_repository.dart';

class ReceiveGoodsScreen extends ConsumerStatefulWidget {
  const ReceiveGoodsScreen({super.key});

  @override
  ConsumerState<ReceiveGoodsScreen> createState() => _ReceiveGoodsScreenState();
}

class _ReceiveGoodsScreenState extends ConsumerState<ReceiveGoodsScreen> {
  final _deliveredByController = TextEditingController();
  final Map<String, TextEditingController> _quantityControllers = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _deliveredByController.dispose();
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_deliveredByController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อผู้ส่งสินค้า')));
      return;
    }

    final updates = <String, int>{};
    for (var entry in _quantityControllers.entries) {
      final qty = int.tryParse(entry.value.text) ?? 0;
      if (qty > 0) {
        updates[entry.key] = qty;
      }
    }

    if (updates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกจำนวนอย่างน้อย 1 รายการ')));
      return;
    }

    setState(() => _isLoading = true);

    final staffName = ref.read(authRepositoryProvider).getCurrentStaffName() ?? 'Staff';
    final deliveredBy = _deliveredByController.text.trim();
    final productRepo = ref.read(productRepositoryProvider);
    final stockRepo = ref.read(stockRepositoryProvider);

    for (var entry in updates.entries) {
      final product = productRepo.getProductById(entry.key)!;
      await stockRepo.receiveGoods(
        productId: product.id,
        productName: product.name,
        quantity: entry.value,
        staffName: staffName,
        deliveredBy: deliveredBy,
      );
      await productRepo.addStock(product.id, entry.value);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('รับสินค้าสำเร็จ'), backgroundColor: Colors.green));

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รับสินค้า'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              controller: _deliveredByController,
              decoration: const InputDecoration(
                labelText: 'ส่งโดย',
                hintText: 'กรอกชื่อผู้จัดส่ง/ผู้ส่งสินค้า',
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ),
          const Divider(),
          Expanded(
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
                    _quantityControllers.putIfAbsent(product.id, () => TextEditingController());

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  Text(
                                    'สต็อกปัจจุบัน: ${product.stock}',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: _quantityControllers[product.id],
                                decoration: const InputDecoration(labelText: 'จำนวน', hintText: '0'),
                                keyboardType: TextInputType.number,
                              ),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))],
            ),
            child: PrimaryButton(
              text: 'บันทึก',
              onPressed: _handleSubmit,
              isLoading: _isLoading,
              icon: Icons.check,
              fullWidth: true,
            ),
          ),
        ],
      ),
    );
  }
}
