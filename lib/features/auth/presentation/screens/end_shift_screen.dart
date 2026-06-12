import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/money_text_field.dart';
import '../../../../common/utils/formatters.dart';
import '../../data/auth_repository.dart';
import '../../../shift/data/shift_repository.dart';
import '../../../shift/data/models/shift_models.dart';

class EndShiftScreen extends ConsumerStatefulWidget {
  const EndShiftScreen({super.key});

  @override
  ConsumerState<EndShiftScreen> createState() => _EndShiftScreenState();
}

class _EndShiftScreenState extends ConsumerState<EndShiftScreen> {
  final _actualCashController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingSummary = true;
  ShiftSummaryResponse? _summary;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadShiftSummary();
  }

  @override
  void dispose() {
    _actualCashController.dispose();
    super.dispose();
  }

  Future<void> _loadShiftSummary() async {
    final shiftRepo = ref.read(shiftRepositoryProvider);
    final summary = await shiftRepo.getShiftSummaryApi();

    if (!mounted) return;

    setState(() {
      _summary = summary;
      _isLoadingSummary = false;
    });
  }

  Future<void> _showConfirmDialog() async {
    final actualCash = double.tryParse(_actualCashController.text) ?? 0;
    final expectedCash = _summary?.expectedCash ?? 0;
    final difference = actualCash - expectedCash;
    final hasDifference = difference.abs() > 0.01;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันปิดกะ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('เงินสดที่ควรมี: ${Formatters.formatMoney(expectedCash)}'),
            Text('เงินสดจริง: ${Formatters.formatMoney(actualCash)}'),
            if (hasDifference) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: difference < 0 ? Colors.red.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: difference < 0 ? Colors.red.shade300 : Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: difference < 0 ? Colors.red.shade700 : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        difference < 0
                            ? 'เงินขาด ${Formatters.formatMoney(difference.abs())}'
                            : 'เงินเกิน ${Formatters.formatMoney(difference)}',
                        style: TextStyle(
                          color: difference < 0 ? Colors.red.shade700 : Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('คุณต้องการปิดกะและออกจากระบบหรือไม่?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ยืนยันปิดกะ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _handleEndShift();
    }
  }

  Future<void> _handleEndShift() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final actualCash = double.tryParse(_actualCashController.text) ?? 0;

    final shiftRepo = ref.read(shiftRepositoryProvider);
    final result = await shiftRepo.closeShiftApi(actualCash);

    if (!mounted) return;

    if (result != null) {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.logout();

      if (!mounted) return;
      context.go('/login');
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ไม่สามารถปิดกะได้ กรุณาลองใหม่อีกครั้ง';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSummary) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_summary == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ปิดกะการทำงาน'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
        ),
        body: const Center(child: Text('ไม่พบข้อมูลกะปัจจุบัน')),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;
    final padding = isSmall ? 12.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ปิดกะการทำงาน'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: padding,
          right: padding,
          top: padding,
          bottom: padding + MediaQuery.of(context).viewPadding.bottom,
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
                    const Text('สรุปกะการทำงาน', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildSummaryRow('ยอดขายรวม', Formatters.formatMoney(_summary!.totalSales)),
                    _buildSummaryRow('จำนวนออร์เดอร์', '${_summary!.orderCount}'),
                    const Divider(height: 24),
                    _buildSummaryRow('ยอดเงินสด', Formatters.formatMoney(_summary!.expectedCash - _summary!.startingCash)),
                    if (_summary!.transferSales > 0)
                      _buildHighlightRow(
                        'ยอดเงินโอน',
                        Formatters.formatMoney(_summary!.transferSales),
                        color: Colors.blue.shade700,
                        icon: Icons.account_balance_outlined,
                      ),
                    const Divider(height: 24),
                    _buildSummaryRow('เงินเปิดกะ', Formatters.formatMoney(_summary!.startingCash)),
                    _buildSummaryRow('เงินสดที่คาดไว้ในลิ้นชัก', Formatters.formatMoney(_summary!.expectedCash)),
                    if (_summary!.cancelledCount > 0) ...[const Divider(height: 24), _buildCancelledSection()],
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
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'ปิดกะและออกจากระบบ',
              onPressed: _showConfirmDialog,
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

  Widget _buildHighlightRow(String label, String value, {required Color color, IconData? icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: color), const SizedBox(width: 8)],
              Text(label, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildCancelledSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 12),
              Text(
                'ออร์เดอร์ที่ถูกยกเลิก',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('จำนวน', style: TextStyle(color: Colors.red.shade600)),
              Text(
                '${_summary!.cancelledCount} รายการ',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('มูลค่ารวม', style: TextStyle(color: Colors.red.shade600)),
              Text(
                Formatters.formatMoney(_summary!.cancelledTotal),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
