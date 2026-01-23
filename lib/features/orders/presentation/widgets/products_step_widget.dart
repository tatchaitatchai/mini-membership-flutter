import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/secondary_button.dart';
import '../../../../common/utils/formatters.dart';
import '../../../customers/domain/customer.dart';
import '../../../products/domain/product.dart';
import '../../../products/data/product_repository.dart';

class ProductsStepWidget extends ConsumerStatefulWidget {
  final Customer? selectedCustomer;
  final Map<String, int> cart;
  final double subtotal;
  final double discount;
  final double total;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Function(String productId, int quantity) onCartChanged;

  const ProductsStepWidget({
    super.key,
    required this.selectedCustomer,
    required this.cart,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.onBack,
    required this.onNext,
    required this.onCartChanged,
  });

  @override
  ConsumerState<ProductsStepWidget> createState() => _ProductsStepWidgetState();
}

class _ProductsStepWidgetState extends ConsumerState<ProductsStepWidget> {
  Widget _buildPlaceholderImage({double size = 56}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
      child: Icon(Icons.inventory_2, color: Colors.grey.shade400, size: size * 0.5),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            value,
            style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ขั้นตอนที่ 2: เลือกสินค้า',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('ลูกค้า: ${widget.selectedCustomer?.fullName}', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              SecondaryButton(text: 'ย้อนกลับ', onPressed: widget.onBack),
              const SizedBox(width: 16),
              PrimaryButton(text: 'ถัดไป', onPressed: widget.cart.isEmpty ? null : widget.onNext),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 2, child: _buildProductList()),
              _buildCartSidebar(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductList() {
    return FutureBuilder<List<Product>>(
      future: ref.read(productRepositoryProvider).getAllProducts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final inCart = widget.cart[product.id] ?? 0;
            final canAdd = product.stock > inCart;

            return Card(
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
                title: Text(product.name),
                subtitle: Text('${Formatters.formatMoney(product.price)} • สต็อก: ${product.stock}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (inCart > 0) ...[
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => widget.onCartChanged(product.id, inCart - 1),
                      ),
                      Text('$inCart', style: const TextStyle(fontSize: 18)),
                    ],
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: canAdd ? () => widget.onCartChanged(product.id, inCart + 1) : null,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCartSidebar() {
    return Container(
      width: 350,
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ตะกร้า', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Divider(),
          Expanded(
            child: widget.cart.isEmpty
                ? const Center(child: Text('ไม่มีสินค้า'))
                : ListView(
                    children: widget.cart.entries.map((entry) {
                      final product = ref.read(productRepositoryProvider).getProductById(entry.key)!;
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: product.imageUrl != null
                              ? Image.network(
                                  product.imageUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildPlaceholderImage(size: 40),
                                )
                              : _buildPlaceholderImage(size: 40),
                        ),
                        title: Text(product.name),
                        subtitle: Text('${entry.value} x ${Formatters.formatMoney(product.price)}'),
                        trailing: Text(
                          Formatters.formatMoney(product.price * entry.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const Divider(),
          _buildSummaryRow('ยอดรวมย่อย', Formatters.formatMoney(widget.subtotal)),
          if (widget.discount > 0) _buildSummaryRow('ส่วนลด', '-${Formatters.formatMoney(widget.discount)}'),
          _buildSummaryRow('ยอดรวม', Formatters.formatMoney(widget.total), isTotal: true),
        ],
      ),
    );
  }
}
