import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/responsive_scaffold.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../shift/data/shift_repository.dart';
import '../../../products/data/product_repository.dart';

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
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('สวัสดีค่ะ $staffName!', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('คุณต้องการทำอะไรคะ?', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.2,
                children: [
                  _buildActionCard(
                    context,
                    icon: Icons.shopping_cart,
                    title: 'รับออร์เดอร์',
                    subtitle: 'ลูกค้าเข้ามา',
                    color: const Color(0xFF6366F1),
                    onTap: () => context.go('/create-order'),
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.inventory_2,
                    title: 'รับสินค้า',
                    subtitle: 'สินค้าเข้า',
                    color: Colors.green,
                    onTap: () => context.go('/receive-goods'),
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.output,
                    title: 'เบิกสินค้า',
                    subtitle: 'สินค้าออก',
                    color: Colors.orange,
                    onTap: () => context.go('/withdraw-goods'),
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.edit,
                    title: 'ปรับสต็อก',
                    subtitle: 'ชำรุด/สูญหาย/เสียหาย',
                    color: Colors.purple,
                    onTap: () => context.go('/adjust-stock'),
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.warning,
                    title: 'แจ้งเตือนสต็อกต่ำ',
                    subtitle: 'ดูรายการแจ้งเตือน',
                    color: Colors.red,
                    onTap: () => context.go('/low-stock'),
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.receipt_long,
                    title: 'ออร์เดอร์',
                    subtitle: 'ดูและจัดการ',
                    color: Colors.blue,
                    onTap: () => context.go('/orders'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
