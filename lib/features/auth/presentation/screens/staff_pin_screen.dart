import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/pos_number_pad.dart';
import '../../data/auth_repository.dart';

class StaffPinScreen extends ConsumerStatefulWidget {
  const StaffPinScreen({super.key});

  @override
  ConsumerState<StaffPinScreen> createState() => _StaffPinScreenState();
}

class _StaffPinScreenState extends ConsumerState<StaffPinScreen> {
  String _pin = '';
  bool _isLoading = false;
  String? _errorMessage;

  void _onNumberPressed(String number) {
    if (_pin.length < 4) {
      setState(() {
        _pin += number;
        _errorMessage = null;
      });

      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);

    final authRepo = ref.read(authRepositoryProvider);
    final staffName = await authRepo.verifyStaffPin(_pin);

    if (!mounted) return;

    if (staffName != null) {
      context.go('/home');
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'รหัส PIN ไม่ถูกต้อง';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person, size: 80, color: Color(0xFF6366F1)),
              const SizedBox(height: 24),
              const Text('กรอกรหัส PIN พนักงาน', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('กรอกรหัส PIN 4 หลักเพื่อดำเนินการต่อ', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _pin.length;
                  return Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isFilled ? const Color(0xFF6366F1) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isFilled ? const Color(0xFF6366F1) : Colors.grey.shade300, width: 2),
                    ),
                    child: isFilled ? const Center(child: Icon(Icons.circle, color: Colors.white, size: 16)) : null,
                  );
                }),
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
                  child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                POSNumberPad(onNumberPressed: _onNumberPressed, onBackspace: _onBackspace, currentValue: _pin),
              const SizedBox(height: 32),
              Text('รหัส PIN ทดสอบ: 1234, 5678', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }
}
