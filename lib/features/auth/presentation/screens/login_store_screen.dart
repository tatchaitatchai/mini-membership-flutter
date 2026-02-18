import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/secondary_button.dart';
import '../../../../common/utils/validators.dart';
import '../../data/auth_repository.dart';

class LoginStoreScreen extends ConsumerStatefulWidget {
  const LoginStoreScreen({super.key});

  @override
  ConsumerState<LoginStoreScreen> createState() => _LoginStoreScreenState();
}

class _LoginStoreScreenState extends ConsumerState<LoginStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final loginResponse = await authRepo.loginStore(_emailController.text.trim(), _passwordController.text);
    if (!mounted) return;

    if (loginResponse != null) {
      if (loginResponse.branchId != null) {
        context.go('/open-shift');
      } else {
        context.go('/select-branch');
      }
    } else {
      print('Login failed: $loginResponse');
      setState(() {
        _isLoading = false;
        _errorMessage = 'อีเมลร้านค้า หรือ พาสเวิด ไม่ถูกต้อง';
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
          padding: EdgeInsets.all(isSmall ? 20 : 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.store, size: isSmall ? 56 : 80, color: const Color(0xFF6366F1)),
                  SizedBox(height: isSmall ? 16 : 24),
                  Text(
                    'POS ME',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmall ? 28 : 36,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ระบบขายหน้าร้านสมัยใหม่',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: isSmall ? 14 : 16, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: isSmall ? 32 : 48),
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

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่าน',
                      hintText: 'กรอกรหัสผ่าน',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกรหัสผ่าน';
                      }
                      if (value.length < 6) {
                        return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                      }
                      return null;
                    },
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
                  const SizedBox(height: 24),
                  PrimaryButton(text: 'ดำเนินการต่อ', onPressed: _handleLogin, isLoading: _isLoading, fullWidth: true),
                  const SizedBox(height: 16),
                  SecondaryButton(
                    text: 'ลงทะเบียนธุรกิจใหม่',
                    onPressed: () => context.go('/register'),
                    fullWidth: true,
                  ),
                  const SizedBox(height: 24),
                  // Text(
                  //   'อีเมลทดสอบ: demo@store.com',
                  //   textAlign: TextAlign.center,
                  //   style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
