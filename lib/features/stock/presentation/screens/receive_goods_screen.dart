import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int? _processingTransferId;
  final _refreshKey = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshKey.dispose();
    for (var controllers in _receiveControllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _refresh() {
    _refreshKey.value++;
    setState(() {});
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

    final confirmed = await _showConfirmDialog(transfer, items);
    if (confirmed != true) return;

    setState(() {
      _processingTransferId = transfer.id;
    });

    try {
      final success = await ref.read(stockRepositoryProvider).receiveTransfer(transferId: transfer.id, items: items);

      if (!mounted) return;

      if (success) {
        ToastHelper.success(context, 'รับสินค้าสำเร็จ');
        _receiveControllers.remove(transfer.id);
        _refresh();
      } else {
        ToastHelper.error(context, 'เกิดข้อผิดพลาดในการรับสินค้า');
      }
    } catch (e) {
      if (!mounted) return;
      ToastHelper.error(context, 'เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) {
        setState(() {
          _processingTransferId = null;
        });
      }
    }
  }

  Future<bool?> _showConfirmDialog(StockTransfer transfer, List<Map<String, dynamic>> items) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text('ยืนยันรับสินค้า'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คำขอ #${transfer.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (transfer.fromBranchName != null)
              Text('จาก: ${transfer.fromBranchName}', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            const Text('รายการที่จะรับ:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ...items.map((item) {
              final transferItem = transfer.items.firstWhere((i) => i.productId == item['product_id']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(transferItem.productName)),
                    Text('${item['receive_count']} ชิ้น', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ยืนยัน')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('รับสินค้า'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.inbox), text: 'รอรับสินค้า'),
            Tab(icon: Icon(Icons.history), text: 'ประวัติ'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [_buildPendingTransfers(theme), _buildHistory(theme)]),
    );
  }

  Widget _buildPendingTransfers(ThemeData theme) {
    return ValueListenableBuilder<int>(
      valueListenable: _refreshKey,
      builder: (context, _, __) => FutureBuilder<List<StockTransfer>>(
        future: ref.read(stockRepositoryProvider).getPendingTransfers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final transfers = snapshot.data ?? [];
          if (transfers.isEmpty) {
            return _buildEmptyState(
              icon: Icons.inbox_outlined,
              title: 'ไม่มีรายการรอรับสินค้า',
              subtitle: 'รายการโอนสินค้าที่รอรับจะแสดงที่นี่',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transfers.length,
              itemBuilder: (context, index) => _buildPendingCard(transfers[index], theme),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingCard(StockTransfer transfer, ThemeData theme) {
    _receiveControllers.putIfAbsent(transfer.id, () => {});
    final controllers = _receiveControllers[transfer.id]!;

    for (var item in transfer.items) {
      controllers.putIfAbsent(item.productId, () => TextEditingController(text: item.sendCount.toString()));
    }

    final isProcessing = _processingTransferId == transfer.id;
    final canReceive = transfer.canReceive;
    final statusText = transfer.isCreated ? 'รอส่ง' : 'กำลังส่ง';
    final statusColor = transfer.isCreated ? Colors.grey : Colors.orange;
    final headerColor = transfer.isCreated ? Colors.grey.shade100 : Colors.orange.shade50;
    final iconBgColor = transfer.isCreated ? Colors.grey.shade200 : Colors.orange.shade100;
    final iconColor = transfer.isCreated ? Colors.grey.shade600 : Colors.orange.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
                  child: Icon(
                    transfer.isCreated ? Icons.hourglass_empty : Icons.local_shipping,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('คำขอ #${transfer.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (transfer.fromBranchName != null)
                        Text(
                          'จาก: ${transfer.fromBranchName}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        )
                      else
                        Text('จาก: ส่วนกลาง', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    ],
                  ),
                ),
                _buildStatusBadge(statusText, statusColor),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      Formatters.formatDateTime(transfer.createdAt),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'สินค้า',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              'ขอ',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ),
                          const SizedBox(
                            width: 90,
                            child: Text(
                              'รับจริง',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      ...transfer.items.map((item) => _buildItemRow(item, controllers[item.productId]!)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!canReceive)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'รอส่วนกลางส่งสินค้าก่อนจึงจะรับได้',
                            style: TextStyle(color: Colors.amber.shade800, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  PrimaryButton(
                    text: 'ยืนยันรับสินค้า',
                    onPressed: isProcessing ? null : () => _handleReceive(transfer),
                    isLoading: isProcessing,
                    icon: Icons.check_circle,
                    fullWidth: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(StockTransferItem item, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(item.productName, style: const TextStyle(fontSize: 14))),
          SizedBox(
            width: 60,
            child: Text(
              '${item.sendCount}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          SizedBox(
            width: 90,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(ThemeData theme) {
    return ValueListenableBuilder<int>(
      valueListenable: _refreshKey,
      builder: (context, _, __) => FutureBuilder<StockTransferListResponse?>(
        future: ref.read(stockRepositoryProvider).getTransfers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final response = snapshot.data;
          final received = response?.transfers.where((t) => t.isReceived).toList() ?? [];

          if (received.isEmpty) {
            return _buildEmptyState(
              icon: Icons.history,
              title: 'ไม่มีประวัติการรับสินค้า',
              subtitle: 'รายการที่รับแล้วจะแสดงที่นี่',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: received.length,
              itemBuilder: (context, index) => _buildHistoryCard(received[index], theme),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(StockTransfer transfer, ThemeData theme) {
    final totalSent = transfer.items.fold<int>(0, (sum, i) => sum + i.sendCount);
    final totalReceived = transfer.items.fold<int>(0, (sum, i) => sum + i.receiveCount);
    final isFullyReceived = totalReceived >= totalSent;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showHistoryDetail(transfer),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'รายการ #${transfer.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        if (transfer.fromBranchName != null)
                          Text(
                            'จาก: ${transfer.fromBranchName}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(
                    isFullyReceived ? 'รับครบ' : 'รับไม่ครบ',
                    isFullyReceived ? Colors.green : Colors.amber,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(Icons.inventory_2, 'สินค้า', '${transfer.items.length} รายการ'),
                    Container(width: 1, height: 30, color: Colors.grey.shade300),
                    _buildStatItem(Icons.download, 'รับแล้ว', '$totalReceived/$totalSent'),
                    Container(width: 1, height: 30, color: Colors.grey.shade300),
                    _buildStatItem(
                      Icons.calendar_today,
                      'วันที่รับ',
                      transfer.receivedAt != null ? Formatters.formatDate(transfer.receivedAt!) : '-',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
      ],
    );
  }

  void _showHistoryDetail(StockTransfer transfer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('รายละเอียด #${transfer.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDetailRow('สถานะ', 'รับสินค้าแล้ว', valueColor: Colors.green),
                  if (transfer.fromBranchName != null) _buildDetailRow('จากสาขา', transfer.fromBranchName!),
                  _buildDetailRow('ไปสาขา', transfer.toBranchName),
                  _buildDetailRow('วันที่สร้าง', Formatters.formatDateTime(transfer.createdAt)),
                  if (transfer.receivedAt != null)
                    _buildDetailRow('วันที่รับ', Formatters.formatDateTime(transfer.receivedAt!)),
                  if (transfer.receivedByName != null) _buildDetailRow('ผู้รับ', transfer.receivedByName!),
                  const SizedBox(height: 16),
                  const Text('รายการสินค้า', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text('สินค้า', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  'ขอ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  'รับ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...transfer.items.map((item) {
                          final isShort = item.receiveCount < item.sendCount;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: Colors.grey.shade200)),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(item.productName)),
                                SizedBox(width: 60, child: Text('${item.sendCount}', textAlign: TextAlign.center)),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    '${item.receiveCount}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isShort ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
            child: Icon(icon, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text('เกิดข้อผิดพลาด', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            error,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('ลองใหม่')),
        ],
      ),
    );
  }
}
