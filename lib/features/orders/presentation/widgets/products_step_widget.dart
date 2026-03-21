import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/secondary_button.dart';
import '../../../../common/utils/formatters.dart';
import '../../../customers/domain/customer.dart';
import '../../../products/domain/product.dart';
import '../../../products/data/product_repository.dart';
import '../../../promotions/domain/promotion.dart';
import '../../../promotions/data/promotion_repository.dart';
import '../../../points/data/points_repository.dart';
import '../../../points/domain/points.dart';

class ProductsStepWidget extends ConsumerStatefulWidget {
  final Customer? selectedCustomer;
  final Map<String, int> cart;
  final double subtotal;
  final double discount;
  final double total;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Function(String productId, int quantity) onCartChanged;
  final Function(Promotion?)? onPromotionDetected;

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
    this.onPromotionDetected,
  });

  @override
  ConsumerState<ProductsStepWidget> createState() => _ProductsStepWidgetState();
}

class _ProductsStepWidgetState extends ConsumerState<ProductsStepWidget> {
  List<DetectedPromotion> _detectedPromotions = [];
  bool _isDetecting = false;
  String _lastCartHash = '';
  String? _selectedCategory;
  Future<List<Product>>? _productsFuture;

  @override
  void initState() {
    super.initState();
    _scheduleDetection();
  }

  @override
  void didUpdateWidget(ProductsStepWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleDetection();
  }

  void _scheduleDetection() {
    final newHash = _cartToHash(widget.cart);
    if (newHash != _lastCartHash) {
      _lastCartHash = newHash;
      if (widget.cart.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _detectPromotions());
      } else {
        setState(() => _detectedPromotions = []);
      }
    }
  }

  String _cartToHash(Map<String, int> cart) {
    final sorted = cart.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return sorted.map((e) => '${e.key}:${e.value}').join(',');
  }

  Future<void> _detectPromotions() async {
    if (_isDetecting || !mounted) return;

    setState(() => _isDetecting = true);

    try {
      // Build items for API
      final items = <Map<String, dynamic>>[];
      for (var entry in widget.cart.entries) {
        final product = ref.read(productRepositoryProvider).getProductById(entry.key);
        if (product != null) {
          items.add({
            'product_id': int.tryParse(product.id) ?? 0,
            'quantity': entry.value,
            'unit_price': product.price,
          });
        }
      }

      if (items.isEmpty) {
        if (mounted) {
          setState(() {
            _detectedPromotions = [];
            _isDetecting = false;
          });
        }
        return;
      }

      final detected = await ref.read(promotionRepositoryProvider).detectPromotions(items: items);

      if (mounted) {
        setState(() {
          _detectedPromotions = detected;
          _isDetecting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }

  Future<void> _showCustomerPointsDialog() async {
    if (widget.selectedCustomer == null || widget.selectedCustomer!.id == 'guest') return;

    final customerId = int.tryParse(widget.selectedCustomer!.id);
    if (customerId == null) return;

    showDialog(
      context: context,
      builder: (context) => _CustomerPointsDialog(
        customerId: customerId,
        customerName: widget.selectedCustomer!.fullName,
        customerCode: widget.selectedCustomer!.code,
      ),
    );
  }

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;
    final padding = isSmall ? 12.0 : 24.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ขั้นตอนที่ 2: เลือกสินค้า',
                style: TextStyle(fontSize: isSmall ? 18 : 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'ลูกค้า: ${widget.selectedCustomer?.fullName}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: isSmall ? 13 : 14),
                  ),
                  if (widget.selectedCustomer != null && widget.selectedCustomer!.id != 'guest')
                    InkWell(
                      onTap: _showCustomerPointsDialog,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars_rounded, size: 16, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              'เช็คแต้มสะสม',
                              style: TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SecondaryButton(text: 'ย้อนกลับ', onPressed: widget.onBack),
                  const SizedBox(width: 12),
                  PrimaryButton(text: 'ถัดไป', onPressed: widget.cart.isEmpty ? null : widget.onNext),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: isSmall
              ? _buildMobileProductLayout()
              : Row(
                  children: [
                    Expanded(flex: 2, child: _buildProductList()),
                    _buildCartSidebar(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildMobileProductLayout() {
    return Column(
      children: [
        Expanded(child: _buildProductList()),
        _buildMobileCartBar(),
      ],
    );
  }

  Widget _buildMobileCartBar() {
    final itemCount = widget.cart.values.fold<int>(0, (sum, qty) => sum + qty);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return GestureDetector(
      onTap: _showMobileCartSheet,
      child: Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12 + bottomPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text('$itemCount รายการ', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (_detectedPromotions.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_offer, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '${_detectedPromotions.length}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            Text(
              Formatters.formatMoney(widget.total),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_up, color: Colors.grey.shade500, size: 20),
          ],
        ),
      ),
    );
  }

  void _showMobileCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart),
                  const SizedBox(width: 8),
                  const Text('ตะกร้า', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(
                    '${widget.cart.values.fold<int>(0, (s, q) => s + q)} รายการ',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Cart items + promotions + summary
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  if (widget.cart.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text('ไม่มีสินค้า', style: TextStyle(color: Colors.grey.shade500)),
                      ),
                    )
                  else
                    ...widget.cart.entries.map((entry) {
                      final product = ref.read(productRepositoryProvider).getProductById(entry.key);
                      if (product == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            ClipRRect(
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  Text(
                                    '${entry.value} x ${Formatters.formatMoney(product.price)}',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              Formatters.formatMoney(product.price * entry.value),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }),
                  // Detected promotions
                  if (_detectedPromotions.isNotEmpty) ...[const SizedBox(height: 12), _buildDetectedPromotionsBanner()],
                  // Summary
                  const Divider(height: 24),
                  _buildSummaryRow('ยอดรวมย่อย', Formatters.formatMoney(widget.subtotal)),
                  if (widget.discount > 0) _buildSummaryRow('ส่วนลด', '-${Formatters.formatMoney(widget.discount)}'),
                  _buildSummaryRow('ยอดรวม', Formatters.formatMoney(widget.total), isTotal: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    _productsFuture ??= ref.read(productRepositoryProvider).getAllProducts();
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 8),
                Text('โหลดสินค้าไม่สำเร็จ', style: TextStyle(color: Colors.red.shade400)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => setState(() {
                    _productsFuture = ref.read(productRepositoryProvider).getAllProducts();
                  }),
                  child: const Text('ลองอีกครั้ง'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allProducts = snapshot.data!;
        final categories = allProducts.map((p) => p.category).toSet().toList()..sort();
        final filteredProducts = _selectedCategory == null
            ? allProducts
            : allProducts.where((p) => p.category == _selectedCategory).toList();

        return Column(
          children: [
            _buildCategoryChips(categories, allProducts),
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Text('ไม่พบสินค้าในหมวดนี้', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) => _buildProductCard(filteredProducts[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChips(List<String> categories, List<Product> allProducts) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('ทั้งหมด (${allProducts.length})'),
              selected: _selectedCategory == null,
              onSelected: (_) => setState(() => _selectedCategory = null),
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.15),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: _selectedCategory == null ? Theme.of(context).primaryColor : Colors.grey.shade700,
                fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          ...categories.map((cat) {
            final count = allProducts.where((p) => p.category == cat).length;
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('$cat ($count)'),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedCategory = isSelected ? null : cat),
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.15),
                checkmarkColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final inCart = widget.cart[product.id] ?? 0;
    final canAdd = product.stock > inCart;
    final isOutOfStock = product.stock == 0;

    return GestureDetector(
      onTap: canAdd ? () => widget.onCartChanged(product.id, inCart + 1) : null,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: inCart > 0 ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: inCart > 0
              ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
              : BorderSide(color: Colors.grey.shade200),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade100,
                            child: Icon(Icons.inventory_2, color: Colors.grey.shade400, size: 48),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: Icon(Icons.inventory_2, color: Colors.grey.shade400, size: 48),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.formatMoney(product.price),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'สต็อก: ${product.stock}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isOutOfStock ? Colors.red.shade400 : Colors.grey.shade500,
                          fontWeight: isOutOfStock ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (inCart > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => widget.onCartChanged(product.id, inCart - 1),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.remove, size: 16, color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '$inCart',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      InkWell(
                        onTap: canAdd ? () => widget.onCartChanged(product.id, inCart + 1) : null,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.add, size: 16, color: canAdd ? Colors.white : Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (isOutOfStock)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.45),
                  child: const Center(
                    child: Text(
                      'สินค้าหมด',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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
          // Show detected promotions banner
          if (_detectedPromotions.isNotEmpty) _buildDetectedPromotionsBanner(),
          _buildSummaryRow('ยอดรวมย่อย', Formatters.formatMoney(widget.subtotal)),
          if (widget.discount > 0) _buildSummaryRow('ส่วนลด', '-${Formatters.formatMoney(widget.discount)}'),
          _buildSummaryRow('ยอดรวม', Formatters.formatMoney(widget.total), isTotal: true),
        ],
      ),
    );
  }

  Widget _buildDetectedPromotionsBanner() {
    // Sort by discount amount (highest first)
    final sortedPromos = List<DetectedPromotion>.from(_detectedPromotions)
      ..sort((a, b) => b.discountAmount.compareTo(a.discountAmount));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'โปรโมชั่นที่ใช้ได้ (${sortedPromos.length})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              if (_isDetecting)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Show all promotions
          ...sortedPromos.map(
            (promo) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(promo.promotionName, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  Text(
                    'ลด ${Formatters.formatMoney(promo.discountAmount)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerPointsDialog extends ConsumerStatefulWidget {
  final int customerId;
  final String customerName;
  final String customerCode;

  const _CustomerPointsDialog({required this.customerId, required this.customerName, required this.customerCode});

  @override
  ConsumerState<_CustomerPointsDialog> createState() => _CustomerPointsDialogState();
}

class _CustomerPointsDialogState extends ConsumerState<_CustomerPointsDialog> {
  CustomerPointsInfo? _pointsInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    try {
      final pointsInfo = await ref
          .read(pointsRepositoryProvider)
          .getCustomerPoints(widget.customerId, widget.customerName, widget.customerCode);
      if (mounted) {
        setState(() {
          _pointsInfo = pointsInfo;
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
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.stars_rounded, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(child: Text('แต้มสะสม - ${widget.customerName}', style: const TextStyle(fontSize: 18))),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text('เกิดข้อผิดพลาด: $_error'))
            : _pointsInfo == null || _pointsInfo!.groups.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('ยังไม่มีแต้มสะสม', style: TextStyle(color: Colors.grey)),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _pointsInfo!.groups.length,
                itemBuilder: (context, index) {
                  final group = _pointsInfo!.groups[index];
                  final progress = group.pointsToRedeem > 0
                      ? (group.points / group.pointsToRedeem).clamp(0.0, 1.0)
                      : 0.0;
                  final canRedeem = group.canRedeem;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(group.groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: canRedeem ? Colors.green.shade100 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${group.points} แต้ม',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: canRedeem ? Colors.green.shade700 : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation(canRedeem ? Colors.green : Colors.amber),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            canRedeem
                                ? 'แลกได้! (ใช้ ${group.pointsToRedeem} แต้ม)'
                                : 'อีก ${group.pointsToRedeem - group.points} แต้มจะแลกได้',
                            style: TextStyle(
                              fontSize: 12,
                              color: canRedeem ? Colors.green.shade700 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด'))],
    );
  }
}
