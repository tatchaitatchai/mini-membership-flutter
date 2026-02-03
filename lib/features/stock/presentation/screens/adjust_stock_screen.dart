import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/utils/toast_helper.dart';
import '../../../../common/utils/formatters.dart';
import '../../../../common/services/api_client.dart';
import '../../../orders/data/models/order_models.dart';
import '../../data/inventory_repository.dart';
import '../../domain/inventory.dart';

enum AdjustmentReason { broken, lost, damaged, expired, other }

class AdjustStockScreen extends ConsumerStatefulWidget {
  const AdjustStockScreen({super.key});

  @override
  ConsumerState<AdjustStockScreen> createState() => _AdjustStockScreenState();
}

class _AdjustStockScreenState extends ConsumerState<AdjustStockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form state
  ProductInfo? _selectedProduct;
  AdjustmentReason _adjustmentReason = AdjustmentReason.broken;
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  List<ProductInfo> _products = [];

  // History state
  late Future<List<InventoryMovement>?> _movementsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProducts();
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get<ListProductsResponse>(
        '/api/v2/products',
        requireAuth: true,
        fromJson: ListProductsResponse.fromJson,
      );
      print('Load products response: success=${response.isSuccess}, error=${response.error}, data=${response.data}');
      if (mounted) {
        if (response.isSuccess && response.data != null) {
          setState(() => _products = response.data!.products);
        } else {
          setState(() => _products = []);
          ToastHelper.error(context, response.error ?? 'ไม่สามารถโหลดรายการสินค้าได้');
        }
      }
    } catch (e) {
      print('Load products error: $e');
      if (mounted) {
        setState(() => _products = []);
        ToastHelper.error(context, 'ไม่สามารถโหลดรายการสินค้าได้: $e');
      }
    }
  }

  void _loadHistory() {
    _movementsFuture = ref.read(inventoryRepositoryProvider).getMovements();
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _loadHistory();
    });
  }

  String _getReasonText(AdjustmentReason reason) {
    switch (reason) {
      case AdjustmentReason.broken:
        return 'ชำรุด';
      case AdjustmentReason.lost:
        return 'สูญหาย';
      case AdjustmentReason.damaged:
        return 'เสียหาย';
      case AdjustmentReason.expired:
        return 'หมดอายุ';
      case AdjustmentReason.other:
        return 'อื่นๆ';
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedProduct == null) {
      ToastHelper.warning(context, 'กรุณาเลือกสินค้า');
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      ToastHelper.warning(context, 'กรุณากรอกจำนวนที่ถูกต้อง');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final reason = _getReasonText(_adjustmentReason);
      final note = _noteController.text.trim();

      final success = await ref
          .read(inventoryRepositoryProvider)
          .adjustStock(
            productId: _selectedProduct!.id,
            quantity: quantity,
            reason: reason,
            note: note.isNotEmpty ? note : null,
          );

      if (!mounted) return;

      if (success) {
        ToastHelper.success(context, 'ปรับสต็อกสำเร็จ');
        // Clear form
        setState(() {
          _selectedProduct = null;
          _quantityController.clear();
          _noteController.clear();
          _adjustmentReason = AdjustmentReason.broken;
        });
        // Refresh history and switch to history tab
        _refreshHistory();
        _tabController.animateTo(1);
      } else {
        ToastHelper.error(context, 'เกิดข้อผิดพลาดในการปรับสต็อก');
      }
    } catch (e) {
      if (!mounted) return;
      ToastHelper.error(context, 'เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ปรับสต็อก'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.tune), text: 'ปรับสต็อก'),
            Tab(icon: Icon(Icons.history), text: 'ประวัติ'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [_buildAdjustTab(), _buildHistoryTab()]),
    );
  }

  Widget _buildAdjustTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ใช้สำหรับปรับลดสต็อกกรณีสินค้าชำรุด สูญหาย หรือเสียหาย',
                    style: TextStyle(color: Colors.amber.shade800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Product Selection
          Card(
            elevation: 2,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.inventory_2, color: theme.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('เลือกสินค้า', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_products.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownButtonFormField<ProductInfo>(
                      value: _selectedProduct,
                      decoration: InputDecoration(
                        labelText: 'สินค้า',
                        hintText: 'เลือกสินค้าที่ต้องการปรับ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      isExpanded: true,
                      items: _products.map((product) {
                        return DropdownMenuItem<ProductInfo>(
                          value: product,
                          child: Text(product.productName, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedProduct = value),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Adjustment Type
          Card(
            elevation: 2,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.category, color: Colors.red.shade400, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('สาเหตุการปรับ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AdjustmentReason.values.map((reason) {
                      final isSelected = _adjustmentReason == reason;
                      return ChoiceChip(
                        label: Text(_getReasonText(reason)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _adjustmentReason = reason);
                        },
                        selectedColor: theme.primaryColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? theme.primaryColor : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quantity & Note
          Card(
            elevation: 2,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.edit_note, color: Colors.blue.shade400, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('รายละเอียด', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'จำนวนที่ปรับลด',
                      hintText: 'กรอกจำนวน',
                      prefixIcon: const Icon(Icons.remove_circle_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'หมายเหตุ (ไม่บังคับ)',
                      hintText: 'ระบุรายละเอียดเพิ่มเติม',
                      prefixIcon: const Icon(Icons.notes),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          PrimaryButton(
            text: 'บันทึกการปรับสต็อก',
            onPressed: _isLoading ? null : _handleSubmit,
            isLoading: _isLoading,
            icon: Icons.save,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<List<InventoryMovement>?>(
      future: _movementsFuture,
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
                TextButton.icon(
                  onPressed: _refreshHistory,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ลองใหม่'),
                ),
              ],
            ),
          );
        }

        final movements = snapshot.data ?? [];

        if (movements.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshHistory,
            child: ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                          child: Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'ยังไม่มีประวัติการปรับสต็อก',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'รายการจะแสดงเมื่อมีการปรับสต็อก',
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
          onRefresh: _refreshHistory,
          child: Column(
            children: [
              // Summary Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  border: Border(bottom: BorderSide(color: Colors.indigo.shade100)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.indigo.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'พบ ${movements.length} รายการ',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refreshHistory,
                      color: Colors.indigo.shade700,
                    ),
                  ],
                ),
              ),
              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: movements.length,
                  itemBuilder: (context, index) => _buildMovementCard(movements[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMovementCard(InventoryMovement movement) {
    final isPositive = movement.isPositive;
    final cardColor = isPositive ? Colors.green.shade50 : Colors.red.shade50;
    final accentColor = isPositive ? Colors.green : Colors.red;
    final icon = _getMovementIcon(movement.movementType);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: accentColor.shade100, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: accentColor.shade700, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(movement.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(movement.movementTypeDisplay, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                  // Quantity Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: accentColor.shade700, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${isPositive ? '+' : ''}${movement.quantityChange}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Details Row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    if (movement.fromStockCount != null && movement.toStockCount != null)
                      _buildDetailRow(
                        'สต็อก',
                        '${movement.fromStockCount} → ${movement.toStockCount}',
                        Icons.inventory_2_outlined,
                      ),
                    if (movement.reason != null && movement.reason!.isNotEmpty)
                      _buildDetailRow('สาเหตุ', movement.reason!, Icons.label_outline),
                    if (movement.note != null && movement.note!.isNotEmpty)
                      _buildDetailRow('หมายเหตุ', movement.note!, Icons.note_outlined),
                    _buildDetailRow('ผู้ดำเนินการ', movement.changedByName ?? 'ไม่ระบุ', Icons.person_outline),
                    _buildDetailRow('เวลา', Formatters.formatDateTime(movement.createdAt), Icons.access_time),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMovementIcon(String type) {
    switch (type) {
      case 'SALE':
        return Icons.shopping_cart;
      case 'CANCEL_SALE':
        return Icons.remove_shopping_cart;
      case 'RECEIVE':
        return Icons.add_box;
      case 'ISSUE':
        return Icons.outbox;
      case 'ADJUST':
        return Icons.tune;
      case 'TRANSFER_IN':
        return Icons.move_to_inbox;
      case 'TRANSFER_OUT':
        return Icons.outbox;
      case 'DAMAGE':
        return Icons.broken_image;
      default:
        return Icons.swap_vert;
    }
  }
}
