import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/utils/formatters.dart';
import '../../../products/data/product_repository.dart';

class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productRepo = ref.watch(productRepositoryProvider);
    final lowStockProducts = productRepo.getLowStockProducts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('แจ้งเตือนสต็อกต่ำ'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
      ),
      body: lowStockProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 80, color: Colors.green.shade400),
                  const SizedBox(height: 16),
                  Text('สต็อกทุกรายการเพียงพอ!', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: lowStockProducts.length,
              itemBuilder: (context, index) {
                final product = lowStockProducts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.red.shade50,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
                      child: Icon(Icons.warning, color: Colors.red.shade700),
                    ),
                    title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text('หมวดหมู่: ${product.category}'),
                        Text('ราคา: ${Formatters.formatMoney(product.price)}'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'สต็อก: ${product.stock}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'เกณฑ์ต่ำสุด: ${product.lowStockThreshold}',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_down, color: Colors.red.shade700, size: 32),
                        Text(
                          'ต่ำ',
                          style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
