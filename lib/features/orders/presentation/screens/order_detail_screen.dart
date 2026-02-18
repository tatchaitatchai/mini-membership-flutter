import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/danger_button.dart';
import '../../../../common/widgets/pos_number_pad.dart';
import '../../../../common/utils/formatters.dart';
import '../../../../common/utils/toast_helper.dart';
import '../../data/order_repository.dart';
import '../../domain/order.dart';
import '../../../auth/data/auth_repository.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref, Order order) async {
    final pinResult = await showDialog<String>(context: context, builder: (context) => const _StaffPinDialog());

    if (pinResult == null) return;

    final authRepo = ref.read(authRepositoryProvider);
    final staffName = await authRepo.verifyStaffPin(pinResult);

    if (!context.mounted) return;

    if (staffName == null) {
      ToastHelper.error(context, 'รหัส PIN ไม่ถูกต้อง');
      return;
    }

    final reason = await showDialog<String>(context: context, builder: (context) => _CancelReasonDialog());

    if (reason == null || reason.isEmpty) return;

    final success = await ref.read(orderRepositoryProvider).cancelOrderApi(int.parse(orderId), reason, pinResult);

    if (!context.mounted) return;

    if (success) {
      ToastHelper.success(context, 'ยกเลิกออร์เดอร์สำเร็จ');
      if (context.canPop()) context.pop();
    } else {
      ToastHelper.error(context, 'ไม่สามารถยกเลิกออร์เดอร์ได้');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดออร์เดอร์'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : null,
        ),
      ),
      body: FutureBuilder(
        future: ref.read(orderRepositoryProvider).getOrderById(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('ไม่พบออร์เดอร์'));
          }

          final order = snapshot.data!;
          final screenWidth = MediaQuery.of(context).size.width;
          final isSmall = screenWidth < 600;
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: isSmall ? 12 : 24,
              right: isSmall ? 12 : 24,
              top: isSmall ? 12 : 24,
              bottom: (isSmall ? 12 : 24) + MediaQuery.of(context).viewPadding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ข้อมูลออร์เดอร์', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: order.status == OrderStatus.completed
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                order.status == OrderStatus.completed ? 'สำเร็จ' : 'ยกเลิก',
                                style: TextStyle(
                                  color: order.status == OrderStatus.completed
                                      ? Colors.green.shade900
                                      : Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        _buildInfoRow('หมายเลขออร์เดอร์', order.id),
                        _buildInfoRow('ลูกค้า', order.customerName),
                        _buildInfoRow('วันที่', Formatters.formatDateTime(order.createdAt)),
                        _buildInfoRow('พนักงาน', order.createdBy),
                        if (order.status == OrderStatus.cancelled) ...[
                          const SizedBox(height: 16),
                          _buildInfoRow('ยกเลิกโดย', order.cancelledBy ?? 'ไม่ระบุ'),
                          _buildInfoRow(
                            'ยกเลิกเมื่อ',
                            order.cancelledAt != null ? Formatters.formatDateTime(order.cancelledAt!) : 'ไม่ระบุ',
                          ),
                          _buildInfoRow('เหตุผล', order.cancellationReason ?? 'ไม่ระบุ'),
                        ],
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
                        const Text('รายการสินค้า', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Divider(),
                        ...order.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text(
                                        '${item.quantity} x ${Formatters.formatMoney(item.price)}',
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  Formatters.formatMoney(item.total),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildSummaryRow('ยอดรวมย่อย', Formatters.formatMoney(order.subtotal)),
                        if (order.discount > 0)
                          _buildSummaryRow('ส่วนลด', '-${Formatters.formatMoney(order.discount)}'),
                        _buildSummaryRow('ยอดรวม', Formatters.formatMoney(order.total), isTotal: true),
                        const Divider(),
                        _buildSummaryRow('เงินที่รับมา', Formatters.formatMoney(order.cashReceived)),
                        _buildSummaryRow('เงินทอน', Formatters.formatMoney(order.change)),
                      ],
                    ),
                  ),
                ),
                if (order.status == OrderStatus.completed) ...[
                  const SizedBox(height: 24),
                  DangerButton(
                    text: 'ยกเลิกออร์เดอร์ (ต้องใช้ PIN)',
                    icon: Icons.cancel,
                    onPressed: () => _cancelOrder(context, ref, order),
                    fullWidth: true,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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

class _StaffPinDialog extends StatefulWidget {
  const _StaffPinDialog();

  @override
  State<_StaffPinDialog> createState() => _StaffPinDialogState();
}

class _StaffPinDialogState extends State<_StaffPinDialog> {
  String _pin = '';

  void _onNumberPressed(String number) {
    if (_pin.length < 4) {
      setState(() => _pin += number);
      if (_pin.length == 4) {
        Navigator.of(context).pop(_pin);
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;
    final dotSize = isSmall ? 36.0 : 50.0;

    return AlertDialog(
      title: const Text('ยืนยันตัวตน'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('กรอกรหัส PIN ของคุณเพื่อยกเลิกออร์เดอร์'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = index < _pin.length;
              return Container(
                width: dotSize,
                height: dotSize,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isFilled ? const Color(0xFF6366F1) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isFilled
                    ? Center(
                        child: Icon(Icons.circle, color: Colors.white, size: isSmall ? 10 : 12),
                      )
                    : null,
              );
            }),
          ),
          const SizedBox(height: 24),
          POSNumberPad(onNumberPressed: _onNumberPressed, onBackspace: _onBackspace, currentValue: _pin),
        ],
      ),
    );
  }
}

class _CancelReasonDialog extends StatelessWidget {
  final _controller = TextEditingController();

  _CancelReasonDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เหตุผลการยกเลิก'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: 'เหตุผล', hintText: 'ระบุเหตุผลการยกเลิก'),
        maxLines: 3,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ยกเลิก')),
        ElevatedButton(onPressed: () => Navigator.of(context).pop(_controller.text), child: const Text('ยืนยัน')),
      ],
    );
  }
}
