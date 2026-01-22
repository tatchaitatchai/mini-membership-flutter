import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/money_text_field.dart';
import '../../../../common/utils/validators.dart';
import '../../data/auth_repository.dart';
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

  @override
  void dispose() {
    _startingCashController.dispose();
    super.dispose();
  }

  Future<void> _handleOpenShift() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authRepo = ref.read(authRepositoryProvider);
    final shiftRepo = ref.read(shiftRepositoryProvider);

    final storeEmail = authRepo.getStoreEmail() ?? 'Demo Store';
    final startingCash = double.tryParse(_startingCashController.text) ?? 0;

    await shiftRepo.openShift(storeName: storeEmail, staffName: 'Staff', startingCash: startingCash);

    if (!mounted) return;

    context.go('/pin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.schedule, size: 80, color: Color(0xFF6366F1)),
                  const SizedBox(height: 24),
                  const Text(
                    'เปิดกะการทำงาน',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'กรอกเงินทอนเริ่มต้นเพื่อเริ่มกะการทำงาน',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 48),
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
