import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/secondary_button.dart';
import '../../../../common/widgets/money_text_field.dart';
import '../../../../common/utils/formatters.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ไม่สามารถเปิดกล้องได้: $e')));
    }
  }

  void _handleCompleteOrder() {
    if (_cashAmountController.text.isEmpty && _transferAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกจำนวนเงิน')));
      return;
    }

    if (_totalReceived < widget.total) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เงินไม่เพียงพอ')));
      return;
    }

    if (_transferAmount > 0 && _slipImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาถ่ายรูปสลิปโอนเงิน')));
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
    );
  }
}
