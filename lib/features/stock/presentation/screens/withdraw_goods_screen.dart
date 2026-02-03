import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/utils/formatters.dart';
import '../../../../common/utils/toast_helper.dart';
import '../../../products/data/product_repository.dart';
import '../../../stock/data/stock_repository.dart';
import '../../../stock/domain/stock_transfer.dart';

class WithdrawGoodsScreen extends ConsumerStatefulWidget {
  const WithdrawGoodsScreen({super.key});

  @override
  ConsumerState<WithdrawGoodsScreen> createState() => _WithdrawGoodsScreenState();
}

class _WithdrawGoodsScreenState extends ConsumerState<WithdrawGoodsScreen> with SingleTickerProviderStateMixin {
  final _sourceBranchController = TextEditingController();
  final Map<String, TextEditingController> _quantityControllers = {};
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      ToastHelper.warning(context, 'กรุณากรอกจำนวนอย่างน้อย 1 รายการ');
      return;
    }

    setState(() => _isLoading = true);

    final note = _sourceBranchController.text.trim().isNotEmpty ? _sourceBranchController.text.trim() : null;
    final stockRepo = ref.read(stockRepositoryProvider);

    // Build items list for API
    final items = updates.entries
        .map((entry) => {'product_id': int.parse(entry.key), 'quantity': entry.value})
        .toList();

    try {
      final result = await stockRepo.withdrawGoods(items: items, note: note);

      if (!mounted) return;

      if (result != null) {
        ToastHelper.success(context, 'เบิกสินค้าสำเร็จ');
        context.go('/home');
      } else {
        ToastHelper.error(context, 'เกิดข้อผิดพลาดในการเบิกสินค้า');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      ToastHelper.error(context, 'เกิดข้อผิดพลาด: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เบิกสินค้า'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'เบิกสินค้าใหม่'),
            Tab(text: 'ประวัติ'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [_buildNewWithdrawal(), _buildHistory()]),
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
    return FutureBuilder<StockTransferListResponse?>(
      future: ref.read(stockRepositoryProvider).getTransfers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final response = snapshot.data;
        if (response == null || response.transfers.isEmpty) {
          return const Center(child: Text('ไม่มีประวัติการเบิกสินค้า'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: response.transfers.length,
          itemBuilder: (context, index) {
            final transfer = response.transfers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'รายการ #${transfer.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        _buildStatusChip(transfer.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...transfer.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text(item.productName), Text('x${item.sendCount}')],
                        ),
                      ),
                    ),
                    const Divider(),
                    if (transfer.sentByName != null)
                      Text('โดย: ${transfer.sentByName}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    if (transfer.note != null)
                      Text('หมายเหตุ: ${transfer.note}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    Text(
                      'วันที่: ${Formatters.formatDateTime(transfer.createdAt)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'SENT':
        color = Colors.orange;
        label = 'ส่งแล้ว';
        break;
      case 'RECEIVED':
        color = Colors.green;
        label = 'รับแล้ว';
        break;
      case 'CANCELLED':
        color = Colors.red;
        label = 'ยกเลิก';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
