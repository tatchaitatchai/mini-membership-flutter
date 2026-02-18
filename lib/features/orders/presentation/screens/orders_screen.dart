import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/utils/formatters.dart';
import '../../data/order_repository.dart';
import '../../domain/order.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ออร์เดอร์'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
      ),
      body: FutureBuilder(
        future: ref.read(orderRepositoryProvider).getAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('ยังไม่มีออร์เดอร์', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          final orders = snapshot.data!;
          final screenWidth = MediaQuery.of(context).size.width;
          final isSmall = screenWidth < 600;
          return ListView.builder(
            padding: EdgeInsets.all(isSmall ? 12 : 24),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text('ออร์เดอร์ #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('ลูกค้า: ${order.customerName}'),
                      Text('วันที่: ${Formatters.formatDateTime(order.createdAt)}'),
                      Text('รายการ: ${order.items.length}'),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: order.status == OrderStatus.completed ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order.status == OrderStatus.completed ? 'สำเร็จ' : 'ยกเลิก',
                          style: TextStyle(
                            color: order.status == OrderStatus.completed ? Colors.green.shade900 : Colors.red.shade900,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.formatMoney(order.total),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => context.go('/orders/${order.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
