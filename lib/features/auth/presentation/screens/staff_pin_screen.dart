import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/pos_number_pad.dart';
import '../../data/auth_repository.dart';
import '../../../shift/data/shift_repository.dart';
import '../../../home/presentation/screens/home_screen.dart';

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
    final shiftRepo = ref.read(shiftRepositoryProvider);
    final staffName = await authRepo.verifyStaffPin(_pin);

    if (!mounted) return;

    if (staffName != null) {
      // Check shift status from server
      final currentShift = await shiftRepo.getCurrentShiftApi();
      if (!mounted) return;

      if (currentShift != null && currentShift.hasActiveShift && currentShift.shift != null) {
        // Shift is open - sync to local and go to home
        await shiftRepo.syncShiftToLocal(currentShift.shift!);
        // Invalidate staffNameProvider to refresh home screen
        ref.invalidate(staffNameProvider);
        context.go('/home');
      } else {
        // No open shift - go to open shift screen
        context.go('/open-shift');
      }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;
    final dotSize = isSmall ? 44.0 : 60.0;
    final dotMargin = isSmall ? 6.0 : 8.0;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: isSmall ? 20 : 32,
            right: isSmall ? 20 : 32,
            top: isSmall ? 20 : 32,
            bottom: (isSmall ? 20 : 32) + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_person, size: isSmall ? 56 : 80, color: const Color(0xFF6366F1)),
              SizedBox(height: isSmall ? 16 : 24),
              Text(
                'กรอกรหัส PIN พนักงาน',
                style: TextStyle(fontSize: isSmall ? 22 : 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'กรอกรหัส PIN 4 หลักเพื่อดำเนินการต่อ',
                style: TextStyle(fontSize: isSmall ? 14 : 16, color: Colors.grey.shade600),
              ),
              SizedBox(height: isSmall ? 32 : 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _pin.length;
                  return Container(
                    width: dotSize,
                    height: dotSize,
                    margin: EdgeInsets.symmetric(horizontal: dotMargin),
                    decoration: BoxDecoration(
                      color: isFilled ? const Color(0xFF6366F1) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isFilled ? const Color(0xFF6366F1) : Colors.grey.shade300, width: 2),
                    ),
                    child: isFilled
                        ? Center(
                            child: Icon(Icons.circle, color: Colors.white, size: isSmall ? 12 : 16),
                          )
                        : null,
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
            ],
          ),
        ),
      ),
    );
  }
}
