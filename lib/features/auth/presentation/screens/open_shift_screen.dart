import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/money_text_field.dart';
import '../../../shift/data/shift_repository.dart';

class OpenShiftScreen extends ConsumerStatefulWidget {
  const OpenShiftScreen({super.key});

  @override
  ConsumerState<OpenShiftScreen> createState() => _OpenShiftScreenState();
}

class _OpenShiftScreenState extends ConsumerState<OpenShiftScreen> {
  final _formKey = GlobalKey<FormState>();
  final _startingCashController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _startingCashController.dispose();
    super.dispose();
  }

  Future<void> _handleOpenShift() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final shiftRepo = ref.read(shiftRepositoryProvider);
    final startingCash = double.tryParse(_startingCashController.text) ?? 0;

    final result = await shiftRepo.openShiftApi(startingCash);

    if (!mounted) return;

    if (result != null) {
      context.go('/pin');
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ไม่สามารถเปิดกะได้ กรุณาลองใหม่อีกครั้ง';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: isSmall ? 20 : 32,
            right: isSmall ? 20 : 32,
            top: isSmall ? 20 : 32,
            bottom: (isSmall ? 20 : 32) + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.schedule, size: isSmall ? 56 : 80, color: const Color(0xFF6366F1)),
                  SizedBox(height: isSmall ? 16 : 24),
                  Text(
                    'เปิดกะการทำงาน',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: isSmall ? 24 : 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'กรอกเงินทอนเริ่มต้นเพื่อเริ่มกะการทำงาน',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: isSmall ? 14 : 16, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: isSmall ? 32 : 48),
                  MoneyTextField(
                    controller: _startingCashController,
                    label: 'เงินทอนเริ่มต้นในลิ้นชัก',
                    hintText: 'กรอกจำนวนเงิน (เช่น 200.00)',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'นี่คือเงินทอนที่มีในลิ้นชักตอนเริ่มกะการทำงาน',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
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
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'เปิดกะการทำงาน',
                    onPressed: _handleOpenShift,
                    isLoading: _isLoading,
                    icon: Icons.play_arrow,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
