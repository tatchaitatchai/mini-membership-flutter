import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/secondary_button.dart';
import '../../../../common/widgets/money_text_field.dart';
import '../../../../common/utils/formatters.dart';
import '../../../../common/utils/toast_helper.dart';

class PaymentStepWidget extends StatefulWidget {
  final double subtotal;
  final double discount;
  final double total;
  final VoidCallback onBack;
  final Function(double cashAmount, double transferAmount, File? slipImage) onCompleteOrder;
  final bool isLoading;

  const PaymentStepWidget({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.onBack,
    required this.onCompleteOrder,
    required this.isLoading,
  });

  @override
  State<PaymentStepWidget> createState() => _PaymentStepWidgetState();
}

class _PaymentStepWidgetState extends State<PaymentStepWidget> {
  final _cashAmountController = TextEditingController();
  final _transferAmountController = TextEditingController();
  File? _slipImage;

  @override
  void dispose() {
    _cashAmountController.dispose();
    _transferAmountController.dispose();
    super.dispose();
  }

  double get _cashAmount => double.tryParse(_cashAmountController.text) ?? 0;
  double get _transferAmount => double.tryParse(_transferAmountController.text) ?? 0;
  double get _totalReceived => _cashAmount + _transferAmount;
  double get _change => _cashAmount > 0 ? (_totalReceived - widget.total).clamp(0, _cashAmount) : 0;

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
      ToastHelper.error(context, 'ไม่สามารถเปิดกล้องได้');
    }
  }

  void _handleCompleteOrder() {
    if (_cashAmountController.text.isEmpty && _transferAmountController.text.isEmpty) {
      ToastHelper.warning(context, 'กรุณากรอกจำนวนเงิน');
      return;
    }

    if (_totalReceived < widget.total) {
      ToastHelper.error(context, 'เงินไม่เพียงพอ');
      return;
    }

    if (_transferAmount > 0 && _slipImage == null) {
      ToastHelper.warning(context, 'กรุณาถ่ายรูปสลิปโอนเงิน');
      return;
    }

    widget.onCompleteOrder(_cashAmount, _transferAmount, _slipImage);
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

  @override
  Widget build(BuildContext context) {
    final remaining = widget.total - _totalReceived;
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
                SecondaryButton(text: 'ย้อนกลับ', onPressed: widget.onBack),
              ],
            ),
            const SizedBox(height: 24),
            _buildOrderSummaryCard(),
            const SizedBox(height: 24),
            const Text('ช่องทางชำระเงิน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPaymentInputs(),
            const SizedBox(height: 16),
            if (_transferAmount > 0) ...[_buildSlipCard(), const SizedBox(height: 16)],
            _buildPaymentSummaryCard(isPaymentComplete, remaining),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'ชำระเงินเสร็จสิ้น',
              onPressed: isPaymentComplete ? _handleCompleteOrder : null,
              isLoading: widget.isLoading,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('สรุปออร์เดอร์', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildSummaryRow('ยอดรวมย่อย', Formatters.formatMoney(widget.subtotal)),
            if (widget.discount > 0) _buildSummaryRow('ส่วนลด', '-${Formatters.formatMoney(widget.discount)}'),
            _buildSummaryRow('ยอดรวม', Formatters.formatMoney(widget.total), isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInputs() {
    return Row(
      children: [
        Expanded(
          child: MoneyTextField(controller: _cashAmountController, label: 'เงินสด', onChanged: (_) => setState(() {})),
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
    );
  }

  Widget _buildSlipCard() {
    return Card(
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
    );
  }

  Widget _buildPaymentSummaryCard(bool isPaymentComplete, double remaining) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPaymentComplete ? POSTheme.successColor.withOpacity(0.3) : POSTheme.warningColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      color: isPaymentComplete ? POSTheme.successColor.withOpacity(0.08) : POSTheme.warningColor.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSummaryRow('รับเงินสด', Formatters.formatMoney(_cashAmount)),
            _buildSummaryRow('รับโอน', Formatters.formatMoney(_transferAmount)),
            const Divider(height: 24),
            _buildSummaryRow('รวมรับ', Formatters.formatMoney(_totalReceived), isTotal: true),
            const SizedBox(height: 16),
            _buildChangeStatusWidget(isPaymentComplete, remaining),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeStatusWidget(bool isPaymentComplete, double remaining) {
    if (!isPaymentComplete) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: POSTheme.dangerColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: POSTheme.dangerColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: POSTheme.dangerColor, shape: BoxShape.circle),
              child: const Icon(Icons.warning_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'เงินยังไม่พอ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ขาดอีก ${Formatters.formatMoney(remaining)}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: POSTheme.dangerColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_change > 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: POSTheme.successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: POSTheme.successColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: POSTheme.successColor, shape: BoxShape.circle),
              child: const Icon(Icons.attach_money_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ต้องทอนเงิน',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ทอน ${Formatters.formatMoney(_change)}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: POSTheme.successColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: POSTheme.successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: POSTheme.successColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: POSTheme.successColor, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'รับเงินครบแล้ว ไม่ต้องทอน',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          ],
        ),
      );
    }
  }
}
