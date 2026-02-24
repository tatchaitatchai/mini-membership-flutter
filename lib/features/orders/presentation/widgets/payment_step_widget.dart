import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/secondary_button.dart';
import '../../../../common/widgets/money_text_field.dart';
import '../../../../common/utils/formatters.dart';
import '../../../../common/utils/toast_helper.dart';
import '../../../../common/utils/image_helper.dart';
import '../../../auth/presentation/widgets/lock_screen.dart';

class PaymentStepWidget extends StatefulWidget {
  final double subtotal;
  final double discount;
  final double total;
  final VoidCallback onBack;
  final Function(double cashAmount, double transferAmount, List<File>? slipImages) onCompleteOrder;
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
  final List<File> _slipImages = [];

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
      // On iOS, image_picker handles permissions automatically
      // Manual permission check causes permanentlyDenied state issues
      ProviderScope.containerOf(context).read(lockScreenProvider.notifier).setSkipNextLock();
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        final compressedFile = await ImageHelper.compressAndResizeImage(
          File(pickedFile.path),
          maxWidth: 1024,
          maxHeight: 1024,
          quality: 60,
        );
        if (compressedFile != null) {
          setState(() => _slipImages.add(compressedFile));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ToastHelper.error(context, 'ไม่สามารถเปิดกล้องได้: ${e.toString()}');
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

    if (_transferAmount > 0 && _slipImages.isEmpty) {
      ToastHelper.warning(context, 'กรุณาถ่ายรูปสลิปโอนเงิน');
      return;
    }

    widget.onCompleteOrder(_cashAmount, _transferAmount, _slipImages.isNotEmpty ? _slipImages : null);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;
    final padding = isSmall ? 12.0 : 24.0;

    return Padding(
      padding: EdgeInsets.only(
        left: padding,
        right: padding,
        top: padding,
        bottom: padding + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ขั้นตอนที่ 4: ชำระเงิน',
                    style: TextStyle(fontSize: isSmall ? 18 : 24, fontWeight: FontWeight.bold),
                  ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;

    if (isSmall) {
      return Column(
        children: [
          MoneyTextField(controller: _cashAmountController, label: 'เงินสด', onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          MoneyTextField(controller: _transferAmountController, label: 'โอนเงิน', onChanged: (_) => setState(() {})),
        ],
      );
    }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('สลิปโอนเงิน', style: TextStyle(fontWeight: FontWeight.bold)),
                if (_slipImages.isNotEmpty)
                  Text('${_slipImages.length} รูป', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            if (_slipImages.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _slipImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_slipImages[index], height: 120, width: 120, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _slipImages.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _pickSlipImage,
              icon: const Icon(Icons.add_a_photo),
              label: Text(_slipImages.isEmpty ? 'ถ่ายรูปสลิป' : 'เพิ่มรูปสลิป'),
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
