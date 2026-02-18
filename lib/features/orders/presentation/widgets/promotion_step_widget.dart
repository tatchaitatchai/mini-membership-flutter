import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/secondary_button.dart';
import '../../../../common/utils/formatters.dart';
import '../../../promotions/domain/promotion.dart';
import '../../../promotions/data/promotion_repository.dart';
import '../../../products/data/product_repository.dart';

class PromotionStepWidget extends ConsumerStatefulWidget {
  final Promotion? selectedPromotion;
  final double subtotal;
  final Map<String, int> cart;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Function(Promotion?) onPromotionSelected;

  const PromotionStepWidget({
    super.key,
    required this.selectedPromotion,
    required this.subtotal,
    required this.cart,
    required this.onBack,
    required this.onNext,
    required this.onPromotionSelected,
  });

  @override
  ConsumerState<PromotionStepWidget> createState() => _PromotionStepWidgetState();
}

class _PromotionStepWidgetState extends ConsumerState<PromotionStepWidget> {
  List<Promotion>? _promotions;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    try {
      final promotions = await ref.read(promotionRepositoryProvider).getActivePromotions();
      if (mounted) {
        setState(() {
          _promotions = promotions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;
    final padding = isSmall ? 12.0 : 24.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ขั้นตอนที่ 3: ใช้โปรโมชั่น (ถ้ามี)',
            style: TextStyle(fontSize: isSmall ? 18 : 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SecondaryButton(text: 'ย้อนกลับ', onPressed: widget.onBack),
              const SizedBox(width: 12),
              PrimaryButton(text: 'ถัดไป', onPressed: widget.onNext),
            ],
          ),
          const SizedBox(height: 16),
          // Show current subtotal
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ยอดรวมก่อนส่วนลด:', style: TextStyle(fontSize: 16)),
                Text(
                  Formatters.formatMoney(widget.subtotal),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildPromotionList()),
        ],
      ),
    );
  }

  Widget _buildPromotionList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('เกิดข้อผิดพลาด: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadPromotions, child: const Text('ลองใหม่')),
          ],
        ),
      );
    }

    final promotions = _promotions ?? [];

    // Separate bill-level and product-level promotions
    final billLevelPromos = promotions.where((p) => p.isBillLevel).toList();
    final productPromos = promotions.where((p) => !p.isBillLevel).toList();

    return ListView(
      children: [
        // No promotion option
        _buildPromotionCard(
          title: 'ไม่ใช้โปรโมชั่น',
          subtitle: 'ชำระเต็มจำนวน',
          isSelected: widget.selectedPromotion == null,
          onTap: () => widget.onPromotionSelected(null),
        ),

        // Bill-level promotions section
        if (billLevelPromos.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'ส่วนลดท้ายบิล',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ...billLevelPromos.map(
            (promo) => _buildPromotionCard(
              title: promo.name,
              subtitle: promo.description,
              badge: promo.typeLabel,
              discountPreview: _calculateDiscountPreview(promo),
              isSelected: widget.selectedPromotion?.id == promo.id,
              onTap: () => widget.onPromotionSelected(promo),
            ),
          ),
        ],

        // Product-level promotions section
        if (productPromos.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'โปรโมชั่นสินค้า',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ...productPromos.map(
            (promo) => _buildPromotionCard(
              title: promo.name,
              subtitle: promo.description,
              badge: promo.typeLabel,
              products: promo.products.map((p) => p.productName).toList(),
              discountPreview: _calculateDiscountPreview(promo),
              isSelected: widget.selectedPromotion?.id == promo.id,
              onTap: () => widget.onPromotionSelected(promo),
            ),
          ),
        ],
      ],
    );
  }

  double _calculateDiscountPreview(Promotion promo) {
    final config = promo.config;
    if (promo.isBillLevel) {
      if (config.percentDiscount != null) {
        return widget.subtotal * (config.percentDiscount! / 100);
      }
      if (config.bahtDiscount != null) {
        return config.bahtDiscount!;
      }
    }
    // For product-level, calculate based on matching products in cart
    if (config.percentDiscount != null) {
      final matchingTotal = _getMatchingProductsTotal(promo);
      return matchingTotal * (config.percentDiscount! / 100);
    }
    if (config.bahtDiscount != null) {
      final matchingQty = _getMatchingProductsQty(promo);
      return config.bahtDiscount! * matchingQty;
    }
    if (config.totalPriceSetDiscount != null && config.oldPriceSet != null) {
      return config.oldPriceSet! - config.totalPriceSetDiscount!;
    }
    return 0;
  }

  double _getMatchingProductsTotal(Promotion promo) {
    final productIds = promo.products.map((p) => p.productId).toSet();
    double total = 0;
    for (var entry in widget.cart.entries) {
      final product = ref.read(productRepositoryProvider).getProductById(entry.key);
      if (product != null && productIds.contains(int.tryParse(product.id))) {
        total += product.price * entry.value;
      }
    }
    return total;
  }

  int _getMatchingProductsQty(Promotion promo) {
    final productIds = promo.products.map((p) => p.productId).toSet();
    int qty = 0;
    for (var entry in widget.cart.entries) {
      final product = ref.read(productRepositoryProvider).getProductById(entry.key);
      if (product != null && productIds.contains(int.tryParse(product.id))) {
        qty += entry.value;
      }
    }
    return qty;
  }

  Widget _buildPromotionCard({
    required String title,
    required String subtitle,
    String? badge,
    List<String>? products,
    double? discountPreview,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      color: isSelected ? Colors.blue.shade50 : null,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(badge, style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    if (products != null && products.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: products
                            .map(
                              (p) => Chip(
                                label: Text(p, style: const TextStyle(fontSize: 11)),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (discountPreview != null && discountPreview > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '-${Formatters.formatMoney(discountPreview)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                    ),
                    if (isSelected)
                      Text(
                        'จ่าย ${Formatters.formatMoney(widget.subtotal - discountPreview)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check_circle, color: Colors.blue, size: 28),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
