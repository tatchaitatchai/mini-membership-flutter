import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/secondary_button.dart';
import '../../../../common/widgets/terms_and_privacy_dialog.dart';
import '../../../../common/utils/validators.dart';
import '../../../../common/utils/toast_helper.dart';
import '../../data/auth_repository.dart';

class RegisterBusinessScreen extends ConsumerStatefulWidget {
  const RegisterBusinessScreen({super.key});

  @override
  ConsumerState<RegisterBusinessScreen> createState() => _RegisterBusinessScreenState();
}

class _RegisterBusinessScreenState extends ConsumerState<RegisterBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessNameController = TextEditingController();
  bool _isLoading = false;
  bool _acceptPolicy = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณายืนยันรหัสผ่าน';
    }
    if (value != _passwordController.text) {
      return 'รหัสผ่านไม่ตรงกัน';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptPolicy) {
      ToastHelper.warning(context, 'กรุณายอมรับข้อกำหนดและนโยบาย');
      return;
    }

    setState(() => _isLoading = true);

    final authRepo = ref.read(authRepositoryProvider);
    final success = await authRepo.registerBusiness(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      businessName: _businessNameController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ToastHelper.success(context, 'ลงทะเบียนสำเร็จ! กรุณาเข้าสู่ระบบ');
      context.go('/login');
    } else {
      setState(() => _isLoading = false);
      ToastHelper.error(context, 'ลงทะเบียนไม่สำเร็จ กรุณาลองใหม่อีกครั้ง');
    }
  }

  void _showPolicy() {
    TermsAndPrivacyDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/login')),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('ลงทะเบียนธุรกิจ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('สร้างบัญชี POS ของคุณ', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อธุรกิจ',
                      hintText: 'กรอกชื่อธุรกิจของคุณ',
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (v) => Validators.validateRequired(v, 'ชื่อธุรกิจ'),
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'อีเมล',
                      hintText: 'กรอกอีเมลของคุณ',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่าน',
                      hintText: 'กรอกรหัสผ่านของคุณ',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: Validators.validatePassword,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'ยืนยันรหัสผ่าน',
                      hintText: 'กรอกรหัสผ่านอีกครั้ง',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: _validateConfirmPassword,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),
                  CheckboxListTile(
                    value: _acceptPolicy,
                    onChanged: _isLoading ? null : (value) => setState(() => _acceptPolicy = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Row(
                      children: [
                        const Text('ฉันยอมรับ '),
                        GestureDetector(
                          onTap: _showPolicy,
                          child: const Text(
                            'ข้อกำหนดและนโยบาย',
                            style: TextStyle(color: Color(0xFF6366F1), decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(text: 'สร้างบัญชี', onPressed: _handleRegister, isLoading: _isLoading, fullWidth: true),
                  const SizedBox(height: 16),
                  SecondaryButton(
                    text: 'กลับไปหน้าเข้าสู่ระบบ',
                    onPressed: () => context.go('/login'),
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
