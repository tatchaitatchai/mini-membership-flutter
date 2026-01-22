import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/utils/formatters.dart';
import '../../../products/data/product_repository.dart';
import '../../../stock/data/stock_repository.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../stock/domain/stock_log.dart';

class WithdrawGoodsScreen extends ConsumerStatefulWidget {
  const WithdrawGoodsScreen({super.key});

  @override
  ConsumerState<WithdrawGoodsScreen> createState() => _WithdrawGoodsScreenState();
}

class _WithdrawGoodsScreenState extends ConsumerState<WithdrawGoodsScreen> {
  final _sourceBranchController = TextEditingController();
  final Map<String, TextEditingController> _quantityControllers = {};
  bool _isLoading = false;
  int _selectedTab = 0;

  @override
  void dispose() {
    _sourceBranchController.dispose();
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
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
    final sourceBranch = _sourceBranchController.text.trim().isNotEmpty ? _sourceBranchController.text.trim() : null;
    final productRepo = ref.read(productRepositoryProvider);
    final stockRepo = ref.read(stockRepositoryProvider);

    for (var entry in updates.entries) {
      final product = productRepo.getProductById(entry.key)!;
      if (product.stock < entry.value) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('สต็อกไม่เพียงพอสำหรับ ${product.name}')));
        setState(() => _isLoading = false);
        return;
      }

      await stockRepo.withdrawGoods(
        productId: product.id,
        productName: product.name,
        quantity: entry.value,
        staffName: staffName,
        sourceBranch: sourceBranch,
      );
      await productRepo.reduceStock(product.id, entry.value);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('เบิกสินค้าสำเร็จ'), backgroundColor: Colors.green));

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เบิกสินค้า'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
        bottom: TabBar(
          controller: null,
          onTap: (index) => setState(() => _selectedTab = index),
          tabs: const [
            Tab(text: 'เบิกสินค้าใหม่'),
            Tab(text: 'ประวัติ'),
          ],
        ),
      ),
      body: _selectedTab == 0 ? _buildNewWithdrawal() : _buildHistory(),
    );
  }

  Widget _buildNewWithdrawal() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: TextField(
            controller: _sourceBranchController,
            decoration: const InputDecoration(
              labelText: 'สาขาต้นทาง (ถ้ามี)',
              hintText: 'กรอกชื่อสาขาถ้ามี',
              prefixIcon: Icon(Icons.store),
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
                                  'สต็อกที่มี: ${product.stock}',
                                  style: TextStyle(color: product.stock > 0 ? Colors.grey.shade600 : Colors.red),
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
                              enabled: product.stock > 0,
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
    );
  }

  Widget _buildHistory() {
    return FutureBuilder(
      future: ref.read(stockRepositoryProvider).getLogsByType(StockLogType.withdraw),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data!;
        if (logs.isEmpty) {
          return const Center(child: Text('ไม่มีประวัติการเบิกสินค้า'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text(log.productName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('จำนวน: ${log.quantity}'),
                    Text('โดย: ${log.staffName}'),
                    if (log.sourceBranch != null) Text('สาขา: ${log.sourceBranch}'),
                    Text('วันที่: ${Formatters.formatDateTime(log.createdAt)}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
