import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/utils/formatters.dart';
import '../../../../common/utils/toast_helper.dart';
import '../../../stock/data/stock_repository.dart';
import '../../../stock/domain/stock_transfer.dart';

class ReceiveGoodsScreen extends ConsumerStatefulWidget {
  const ReceiveGoodsScreen({super.key});

  @override
  ConsumerState<ReceiveGoodsScreen> createState() => _ReceiveGoodsScreenState();
}

class _ReceiveGoodsScreenState extends ConsumerState<ReceiveGoodsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<int, Map<int, TextEditingController>> _receiveControllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controllers in _receiveControllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _handleReceive(StockTransfer transfer) async {
    final controllers = _receiveControllers[transfer.id];
    if (controllers == null) return;

    final items = <Map<String, dynamic>>[];
    for (var item in transfer.items) {
      final qty = int.tryParse(controllers[item.productId]?.text ?? '') ?? 0;
      if (qty > 0) {
        items.add({'product_id': item.productId, 'receive_count': qty});
      }
    }

    if (items.isEmpty) {
      ToastHelper.warning(context, 'กรุณากรอกจำนวนที่รับอย่างน้อย 1 รายการ');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ref.read(stockRepositoryProvider).receiveTransfer(transferId: transfer.id, items: items);

      if (!mounted) return;

      if (success) {
        ToastHelper.success(context, 'รับสินค้าสำเร็จ');
        setState(() {});
      } else {
        ToastHelper.error(context, 'เกิดข้อผิดพลาดในการรับสินค้า');
      }
    } catch (e) {
      if (!mounted) return;
      ToastHelper.error(context, 'เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รับสินค้า'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'รอรับสินค้า'),
            Tab(text: 'ประวัติ'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [_buildPendingTransfers(), _buildHistory()]),
    );
  }

  Widget _buildPendingTransfers() {
    return FutureBuilder<List<StockTransfer>>(
      future: ref.read(stockRepositoryProvider).getPendingTransfers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final transfers = snapshot.data ?? [];
        if (transfers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('ไม่มีรายการรอรับสินค้า', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transfers.length,
          itemBuilder: (context, index) {
            final transfer = transfers[index];
            return _buildTransferCard(transfer);
          },
        );
      },
    );
  }

  Widget _buildTransferCard(StockTransfer transfer) {
    _receiveControllers.putIfAbsent(transfer.id, () => {});
    final controllers = _receiveControllers[transfer.id]!;

    for (var item in transfer.items) {
      controllers.putIfAbsent(item.productId, () => TextEditingController(text: item.sendCount.toString()));
    }

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
                Text('คำขอ #${transfer.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Text('รอรับ', style: TextStyle(color: Colors.orange, fontSize: 12)),
                ),
              ],
            ),
            if (transfer.fromBranchName != null) ...[
              const SizedBox(height: 8),
              Text('จาก: ${transfer.fromBranchName}', style: TextStyle(color: Colors.grey.shade600)),
            ],
            Text(
              'วันที่ขอ: ${Formatters.formatDateTime(transfer.createdAt)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const Divider(height: 24),
            const Text('รายการสินค้า:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ...transfer.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text('ขอ: ${item.sendCount}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: controllers[item.productId],
                        decoration: const InputDecoration(
                          labelText: 'รับจริง',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              text: 'ยืนยันรับสินค้า',
              onPressed: () => _handleReceive(transfer),
              isLoading: _isLoading,
              icon: Icons.check,
              fullWidth: true,
            ),
          ],
        ),
      ),
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
        final received = response?.transfers.where((t) => t.isReceived).toList() ?? [];

        if (received.isEmpty) {
          return const Center(child: Text('ไม่มีประวัติการรับสินค้า'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: received.length,
          itemBuilder: (context, index) {
            final transfer = received[index];
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
                        Text('รายการ #${transfer.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Text('รับแล้ว', style: TextStyle(color: Colors.green, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...transfer.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text(item.productName), Text('รับ ${item.receiveCount}/${item.sendCount}')],
                        ),
                      ),
                    ),
                    const Divider(),
                    Text(
                      'รับเมื่อ: ${transfer.receivedAt != null ? Formatters.formatDateTime(transfer.receivedAt!) : "-"}',
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
}
