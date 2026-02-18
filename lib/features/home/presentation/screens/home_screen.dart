import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../common/widgets/responsive_scaffold.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../shift/data/shift_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.watch(authRepositoryProvider);
    final shiftRepo = ref.watch(shiftRepositoryProvider);
    final staffName = authRepo.getCurrentStaffName() ?? 'Staff';
    final shift = shiftRepo.getCurrentShift();
    final storeName = shift?.storeName ?? 'Store';

    return ResponsiveScaffold(
      appBar: POSAppBar(
        storeName: storeName,
        staffName: staffName,
        shiftStatus: 'กะเปิดอยู่',
        onEndWork: () => context.go('/end-shift'),
        onLogout: () => _showLogoutConfirmation(context, ref),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;
          final crossAxisCount = isSmall ? 2 : 3;
          final gridSpacing = isSmall ? 12.0 : 24.0;
          final padding = isSmall ? 16.0 : 24.0;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'สวัสดีค่ะ $staffName!',
                  style: TextStyle(fontSize: isSmall ? 20 : 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'คุณต้องการทำอะไรคะ?',
                  style: TextStyle(fontSize: isSmall ? 14 : 16, color: Colors.grey.shade600),
                ),
                SizedBox(height: isSmall ? 16 : 32),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: gridSpacing,
                    mainAxisSpacing: gridSpacing,
                    childAspectRatio: isSmall ? 1.0 : 1.2,
                    children: [
                      _buildActionCard(
                        context,
                        icon: Icons.shopping_cart_rounded,
                        title: 'รับออร์เดอร์',
                        color: POSTheme.primaryColor,
                        onTap: () => context.push('/create-order'),
                      ),

                      _buildActionCard(
                        context,
                        icon: Icons.card_giftcard_rounded,
                        title: 'แลกแต้มสะสม',
                        color: Colors.amber,
                        onTap: () => context.push('/redeem-points'),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.inventory_2_rounded,
                        title: 'รับสินค้า',
                        color: POSTheme.successColor,
                        onTap: () => context.push('/receive-goods'),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.output_rounded,
                        title: 'เบิกสินค้า',
                        color: POSTheme.orangeColor,
                        onTap: () => context.push('/withdraw-goods'),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.edit_rounded,
                        title: 'ปรับสต็อก',
                        color: POSTheme.purpleColor,
                        onTap: () => context.push('/adjust-stock'),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.warning_rounded,
                        title: 'แจ้งเตือนสต็อกต่ำ',
                        color: POSTheme.dangerColor,
                        onTap: () => context.push('/low-stock'),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.receipt_long_rounded,
                        title: 'ออร์เดอร์',
                        color: POSTheme.infoColor,
                        onTap: () => context.push('/orders'),
                      ),
                    ],
                  ),
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
              await authRepo.logout();
              await shiftRepo.clearBranchSelection();
              if (context.mounted) {
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

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.15), width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.05), color.withOpacity(0.02)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
