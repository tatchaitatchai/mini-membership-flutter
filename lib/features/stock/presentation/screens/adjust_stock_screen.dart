import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/utils/toast_helper.dart';
import '../../../products/data/product_repository.dart';
import '../../../products/domain/product.dart';
import '../../../stock/data/stock_repository.dart';
import '../../../stock/domain/stock_log.dart';
import '../../../auth/data/auth_repository.dart';

class AdjustStockScreen extends ConsumerStatefulWidget {
  const AdjustStockScreen({super.key});

  @override
  ConsumerState<AdjustStockScreen> createState() => _AdjustStockScreenState();
}

class _AdjustStockScreenState extends ConsumerState<AdjustStockScreen> {
  Product? _selectedProduct;
  AdjustmentType _adjustmentType = AdjustmentType.broken;
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
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

    if (_reasonController.text.trim().isEmpty) {
      ToastHelper.warning(context, 'กรุณากรอกเหตุผล');
      return;
    }

    if (_selectedProduct!.stock < quantity) {
      ToastHelper.error(context, 'สต็อกไม่เพียงพอ');
      return;
    }

    setState(() => _isLoading = true);

    final staffName = ref.read(authRepositoryProvider).getCurrentStaffName() ?? 'Staff';
    final stockRepo = ref.read(stockRepositoryProvider);
    final productRepo = ref.read(productRepositoryProvider);

    await stockRepo.adjustStock(
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      quantity: quantity,
      staffName: staffName,
      type: _adjustmentType,
      reason: _reasonController.text.trim(),
    );

    await productRepo.reduceStock(_selectedProduct!.id, quantity);

    if (!mounted) return;

    ToastHelper.success(context, 'ปรับสต็อกสำเร็จ');

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ปรับสต็อก'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('เลือกสินค้า', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    FutureBuilder(
                      future: ref.read(productRepositoryProvider).getAllProducts(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final products = snapshot.data!;
                        return DropdownButtonFormField<Product>(
                          value: _selectedProduct,
                          decoration: const InputDecoration(labelText: 'สินค้า', hintText: 'เลือกสินค้า'),
                          items: products.map((product) {
                            return DropdownMenuItem(
                              value: product,
                              child: Text('${product.name} (สต็อก: ${product.stock})'),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedProduct = value),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ประเภทการปรับ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<AdjustmentType>(
                      value: _adjustmentType,
                      decoration: const InputDecoration(labelText: 'ประเภท'),
                      items: AdjustmentType.values.map((type) {
                        return DropdownMenuItem(value: type, child: Text(_getAdjustmentTypeName(type)));
                      }).toList(),
                      onChanged: (value) => setState(() => _adjustmentType = value!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('รายละเอียด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'จำนวน', hintText: 'กรอกจำนวนที่ต้องการปรับ'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _reasonController,
                      decoration: const InputDecoration(labelText: 'เหตุผล', hintText: 'ระบุเหตุผลโดยละเอียด'),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'บันทึกการปรับ',
              onPressed: _handleSubmit,
              isLoading: _isLoading,
              icon: Icons.check,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  String _getAdjustmentTypeName(AdjustmentType type) {
    switch (type) {
      case AdjustmentType.broken:
        return 'ชำรุด';
      case AdjustmentType.lost:
        return 'สูญหาย';
      case AdjustmentType.damaged:
        return 'เสียหาย';
      case AdjustmentType.other:
        return 'อื่นๆ';
    }
  }
}
