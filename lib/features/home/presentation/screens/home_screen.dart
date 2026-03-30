import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/responsive_scaffold.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../shift/data/shift_repository.dart';

// Provider to watch staff name changes - auto-dispose to refresh on rebuild
final staffNameProvider = Provider.autoDispose<String>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getCurrentStaffName() ?? 'Staff';
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftRepo = ref.watch(shiftRepositoryProvider);
    final staffName = ref.watch(staffNameProvider);
    final shift = shiftRepo.getCurrentShift();
    final storeName = shift?.storeName ?? 'Store';

    return ResponsiveScaffold(
      appBar: POSAppBar(
        storeName: storeName,
        staffName: staffName,
        shiftStatus: 'กะเปิดอยู่',
        onEndWork: () => context.go('/end-shift'),
        onLogout: () => _showLogoutConfirmation(context, ref),
        onDeleteAccount: () => _showDeleteAccountConfirmation(context, ref),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;
          final crossAxisCount = isSmall ? 2 : 3;
          final gridSpacing = isSmall ? 12.0 : 24.0;
          final padding = isSmall ? 16.0 : 24.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Greeting section
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สวัสดี, $staffName',
                            style: TextStyle(
                              fontSize: isSmall ? 20 : 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            storeName,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'กะเปิดอยู่',
                            style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmall ? 20 : 28),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: gridSpacing,
                  mainAxisSpacing: gridSpacing,
                  childAspectRatio: isSmall ? 1.1 : 1.2,
                  children: [
                    _buildActionCard(
                      context,
                      icon: Icons.shopping_cart_rounded,
                      title: 'รับออร์เดอร์',
                      iconColor: const Color(0xFF4F46E5),
                      iconBg: const Color(0xFFEEF2FF),
                      onTap: () => context.push('/create-order'),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.person_add_alt_rounded,
                      title: 'ลงทะเบียนลูกค้า',
                      iconColor: const Color(0xFF06B6D4),
                      iconBg: const Color(0xFFECFEFF),
                      onTap: () => context.push('/register-customer'),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.card_giftcard_rounded,
                      title: 'แลกแต้มสะสม',
                      iconColor: const Color(0xFFCA8A04),
                      iconBg: const Color(0xFFFEFCE8),
                      onTap: () => context.push('/redeem-points'),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.inventory_2_rounded,
                      title: 'รับสินค้า',
                      iconColor: const Color(0xFF16A34A),
                      iconBg: const Color(0xFFF0FDF4),
                      onTap: () => context.push('/receive-goods'),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.output_rounded,
                      title: 'เบิกสินค้า',
                      iconColor: const Color(0xFFEA580C),
                      iconBg: const Color(0xFFFFF7ED),
                      onTap: () => context.push('/withdraw-goods'),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.tune_rounded,
                      title: 'ปรับสต็อก',
                      iconColor: const Color(0xFF7C3AED),
                      iconBg: const Color(0xFFF5F3FF),
                      onTap: () => context.push('/adjust-stock'),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.warning_amber_rounded,
                      title: 'สต็อกต่ำ',
                      iconColor: const Color(0xFFDC2626),
                      iconBg: const Color(0xFFFEF2F2),
                      onTap: () => context.push('/low-stock'),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.receipt_long_rounded,
                      title: 'ออร์เดอร์',
                      iconColor: const Color(0xFF2563EB),
                      iconBg: const Color(0xFFEFF6FF),
                      onTap: () => context.push('/orders'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?\n\nคุณจะต้องเข้าสู่ระบบด้วยอีเมลและรหัสผ่านใหม่'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authRepo = ref.read(authRepositoryProvider);
              final shiftRepo = ref.read(shiftRepositoryProvider);

              // Clear all data first
              await authRepo.logout();
              await shiftRepo.clearBranchSelection();

              // Invalidate providers to force router rebuild
              ref.invalidate(authRepositoryProvider);
              ref.invalidate(shiftRepositoryProvider);

              // Wait a bit for state to update
              await Future.delayed(const Duration(milliseconds: 100));

              if (context.mounted) {
                // Use go to trigger router redirect
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
            SizedBox(width: 12),
            Text('ลบบัญชีผู้ใช้งาน'),
          ],
        ),
        content: const Text(
          'คุณแน่ใจหรือไม่ว่าต้องการลบบัญชีผู้ใช้งานนี้?\n\n'
          '⚠️ การลบบัญชีจะทำให้:\n'
          '• ข้อมูลส่วนตัวของคุณถูกลบออกจากระบบ\n'
          '• คุณไม่สามารถเข้าสู่ระบบด้วยบัญชีนี้ได้อีก\n'
          '• การกระทำนี้ไม่สามารถย้อนกลับได้',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showFinalDeleteConfirmation(context, ref);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('ดำเนินการต่อ'),
          ),
        ],
      ),
    );
  }

  void _showFinalDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 28),
            SizedBox(width: 12),
            Text('ยืนยันการลบบัญชี'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'นี่คือการยืนยันครั้งสุดท้าย',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
            ),
            SizedBox(height: 12),
            Text(
              'หากคุณกดปุ่ม "ยืนยันการลบบัญชี" ด้านล่าง:\n\n'
              '🔴 บัญชีของคุณจะถูกลบออกจากระบบทันที\n'
              '🔴 ข้อมูลทั้งหมดจะถูกลบอย่างถาวร\n'
              '🔴 คุณจะไม่สามารถกู้คืนบัญชีนี้ได้อีก\n\n'
              'กรุณาพิจารณาอย่างรอบคอบก่อนดำเนินการ',
              style: TextStyle(fontSize: 13, height: 1.6),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton(
            onPressed: () => _handleDeleteAccount(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('ยืนยันการลบบัญชี', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [CircularProgressIndicator(), SizedBox(height: 16), Text('กำลังลบบัญชี...')],
            ),
          ),
        ),
      ),
    );

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.deleteAccount();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 28),
                SizedBox(width: 12),
                Text('ลบบัญชีสำเร็จ'),
              ],
            ),
            content: const Text('บัญชีของคุณถูกลบออกจากระบบเรียบร้อยแล้ว'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  final shiftRepo = ref.read(shiftRepositoryProvider);
                  shiftRepo.clearBranchSelection();
                  ref.invalidate(authRepositoryProvider);
                  ref.invalidate(shiftRepositoryProvider);
                  context.go('/login');
                },
                child: const Text('ตรวจสอบ'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 28),
                SizedBox(width: 12),
                Text('เกิดข้อผิดพลาด'),
              ],
            ),
            content: Text('ไม่สามารถลบบัญชีได้: ${e.toString()}'),
            actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('ตกลง'))],
          ),
        );
      }
    }
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE2E8F0))),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
