import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/pos_number_pad.dart';
import '../../data/auth_repository.dart';
import '../../../shift/data/shift_repository.dart';

final lockScreenProvider = StateNotifierProvider<LockScreenNotifier, bool>((ref) {
  return LockScreenNotifier(ref);
});

class LockScreenNotifier extends StateNotifier<bool> {
  final Ref ref;

  LockScreenNotifier(this.ref) : super(false) {
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
  }

  void lock() {
    final authRepo = ref.read(authRepositoryProvider);
    if (authRepo.isPinVerified()) {
      authRepo.invalidatePin();
      state = true;
    }
  }

  void unlock() {
    state = false;
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final LockScreenNotifier notifier;

  _AppLifecycleObserver(this.notifier);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      notifier.lock();
    }
  }
}

class LockScreenWrapper extends ConsumerWidget {
  final Widget child;

  const LockScreenWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = ref.watch(lockScreenProvider);

    if (isLocked) {
      return const LockScreen();
    }

    return child;
  }
}

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
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
      // Check shift status from server after unlock
      final currentShift = await shiftRepo.getCurrentShiftApi();
      if (!mounted) return;

      if (currentShift != null && currentShift.hasActiveShift && currentShift.shift != null) {
        // Shift is still open - sync and unlock
        await shiftRepo.syncShiftToLocal(currentShift.shift!);
        ref.read(lockScreenProvider.notifier).unlock();
      } else {
        // Shift was closed - clear local data and redirect to open-shift
        await shiftRepo.clearBranchSelection();
        ref.read(lockScreenProvider.notifier).unlock();
        if (mounted) {
          context.go('/open-shift');
        }
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
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'แอปถูกล็อก',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text('กรอกรหัส PIN เพื่อปลดล็อก', style: TextStyle(fontSize: 16, color: Colors.white70)),
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
                      color: isFilled ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: isFilled ? const Center(child: Icon(Icons.circle, color: Colors.black87, size: 16)) : null,
                  );
                }),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.white)
              else
                POSNumberPad(onNumberPressed: _onNumberPressed, onBackspace: _onBackspace, currentValue: _pin),
            ],
          ),
        ),
      ),
    );
  }
}
