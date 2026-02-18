import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/utils/formatters.dart';
import '../../data/inventory_repository.dart';
import '../../domain/inventory.dart';

class LowStockScreen extends ConsumerStatefulWidget {
  const LowStockScreen({super.key});

  @override
  ConsumerState<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends ConsumerState<LowStockScreen> {
  late Future<LowStockResponse?> _lowStockFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _lowStockFuture = ref.read(inventoryRepositoryProvider).getLowStockItems();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แจ้งเตือนสต็อกต่ำ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : null,
        ),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
      ),
      body: FutureBuilder<LowStockResponse?>(
        future: _lowStockFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('เกิดข้อผิดพลาด', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  TextButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('ลองใหม่')),
                ],
              ),
            );
          }

          final response = snapshot.data;
          final items = response?.items ?? [];

          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                            child: Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'สต็อกทุกรายการเพียงพอ!',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ไม่มีสินค้าที่ต้องเติมสต็อก',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                // Summary Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border(bottom: BorderSide(color: Colors.red.shade100)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'พบ ${items.length} รายการที่สต็อกต่ำ',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                // List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _buildItemCard(items[index]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(LowStockItem item) {
    final isCritical = item.isCritical;
    final cardColor = isCritical ? Colors.red.shade50 : Colors.amber.shade50;
    final accentColor = isCritical ? Colors.red : Colors.amber;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: accentColor.shade100, borderRadius: BorderRadius.circular(12)),
                child: Icon(isCritical ? Icons.error : Icons.warning, color: accentColor.shade700, size: 28),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(item.categoryName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStockBadge(item.onStock, isCritical),
                        const SizedBox(width: 8),
                        Text(
                          'เกณฑ์: ${item.reorderLevel}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatMoney(item.price.toDouble()),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: accentColor.shade700, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      isCritical ? 'หมด' : 'ต่ำ',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge(int stock, bool isCritical) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCritical ? Colors.red.shade700 : Colors.amber.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'สต็อก: $stock',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
