import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/secondary_button.dart';
import '../../../../common/utils/validators.dart';
import '../../data/auth_repository.dart';
import '../../../shift/data/shift_repository.dart';

class LoginStoreScreen extends ConsumerStatefulWidget {
  const LoginStoreScreen({super.key});

  @override
  ConsumerState<LoginStoreScreen> createState() => _LoginStoreScreenState();
}

class _LoginStoreScreenState extends ConsumerState<LoginStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final success = await authRepo.loginStore(_emailController.text.trim());

    if (!mounted) return;

    if (success) {
      final shiftRepo = ref.read(shiftRepositoryProvider);
      if (shiftRepo.isShiftOpen()) {
        context.go('/pin');
      } else {
        context.go('/open-shift');
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'อีเมลร้านค้าไม่ถูกต้อง ใช้: demo@store.com';
      });
    }
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
                  const Icon(Icons.store, size: 80, color: Color(0xFF6366F1)),
                  const SizedBox(height: 24),
                  const Text(
                    'POS ME',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ระบบขายหน้าร้านสมัยใหม่',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'อีเมลร้านค้า',
                      hintText: 'กรอกอีเมลร้านค้าของคุณ',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),
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
                  PrimaryButton(text: 'ดำเนินการต่อ', onPressed: _handleLogin, isLoading: _isLoading, fullWidth: true),
                  const SizedBox(height: 16),
                  SecondaryButton(
                    text: 'ลงทะเบียนธุรกิจใหม่',
                    onPressed: () => context.go('/register'),
                    fullWidth: true,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'อีเมลทดสอบ: demo@store.com',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
