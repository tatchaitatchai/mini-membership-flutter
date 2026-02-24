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
    final shiftRepo = ref.read(shiftRepositoryProvider);

    await shiftRepo.clearBranchSelection();

    final loginResponse = await authRepo.loginStore(_emailController.text.trim(), _passwordController.text);
    if (!mounted) return;
    if (loginResponse != null) {
      if (loginResponse.branchId != null) {
        context.go('/open-shift');
      } else {
        context.go('/select-branch');
      }
    } else {
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 24 : 40, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo mark
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.storefront_rounded, size: 28, color: Colors.white),
                  ),
                  SizedBox(height: isSmall ? 20 : 28),
                  const Text(
                    'ยินดีต้อนรับ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'เข้าสู่ระบบด้วยอีเมลและรหัสผ่านของร้านค้า',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
                  ),
                  SizedBox(height: isSmall ? 28 : 36),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'อีเมลร้านค้า',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            hintText: 'example@store.com',
                            prefixIcon: Icon(Icons.email_outlined, size: 18, color: Color(0xFF94A3B8)),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'รหัสผ่าน',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 18,
                                color: const Color(0xFF94A3B8),
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                            if (value.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                            return null;
                          },
                          enabled: !_isLoading,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: const Border.fromBorderSide(BorderSide(color: Color(0xFFFECACA))),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: 'เข้าสู่ระบบ',
                          onPressed: _handleLogin,
                          isLoading: _isLoading,
                          fullWidth: true,
                        ),
                        const SizedBox(height: 12),
                        SecondaryButton(
                          text: 'ลงทะเบียนธุรกิจใหม่',
                          onPressed: () => context.go('/register'),
                          fullWidth: true,
                        ),
                      ],
                    ),
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
