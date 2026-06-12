import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../products/data/product_repository.dart';
import '../../../products/domain/product.dart';
import '../../../shift/data/shift_repository.dart';
import '../../data/models/shift_models.dart';

class OpenShiftStockCountScreen extends ConsumerStatefulWidget {
  const OpenShiftStockCountScreen({super.key});

  @override
  ConsumerState<OpenShiftStockCountScreen> createState() => _OpenShiftStockCountScreenState();
}

class _OpenShiftStockCountScreenState extends ConsumerState<OpenShiftStockCountScreen> {
  final Map<String, TextEditingController> _controllers = {};
  List<Product> _products = [];
  bool _isLoadingProducts = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final products = await ref.read(productRepositoryProvider).getAllProducts();
    if (!mounted) return;
    setState(() {
      _products = products;
      _isLoadingProducts = false;
    });
  }

  Future<void> _onConfirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการนับสต็อก'),
        content: const Text(
          'ข้อมูลที่กรอกจะอัปเดตสต็อกสินค้าจริงในระบบทันที\n\n'
          'กรุณาตรวจสอบตัวเลขให้ถูกต้องก่อนยืนยัน เพราะการนับนี้จะเป็นฐานข้อมูลสต็อกของกะนี้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('กลับไปแก้ไข'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    _submit();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final items = _products.map((p) {
      final qty = int.tryParse(_controllers[p.id]?.text ?? '0') ?? 0;
      return StockCountInput(productId: int.parse(p.id), actualStock: qty);
    }).toList();

    final shiftRepo = ref.read(shiftRepositoryProvider);
    final success = await shiftRepo.submitStockCount(items);

    if (!mounted) return;

    if (success) {
      context.go('/pin');
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'ไม่สามารถบันทึกสต็อกได้ กรุณาลองใหม่อีกครั้ง';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;
    final padding = isSmall ? 16.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('นับสต็อกเปิดกะ'),
        centerTitle: false,
      ),
      body: _isLoadingProducts
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(padding, padding, padding, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(isSmall),
                        const SizedBox(height: 12),
                        _buildOrderWarning(),
                        const SizedBox(height: 12),
                        _buildProductList(isSmall),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          _buildError(),
                        ],
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(padding),
              ],
            ),
    );
  }

  Widget _buildOrderWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'มีลูกค้าสั่งออร์เดอร์ระหว่างนับ?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'จดรายการลงกระดาษก่อน แล้วค่อยกรอกเข้าระบบหลังจากนับสต็อกเสร็จ',
                  style: TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSmall) {
    return Card(
      color: const Color(0xFF6366F1).withValues(alpha: 0.06),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: Color(0xFF6366F1), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'นับสต็อกสินค้าก่อนเริ่มกะ',
                    style: TextStyle(
                      fontSize: isSmall ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'กรอกจำนวนที่นับได้จริง (0 = ไม่มีสินค้า)',
                    style: TextStyle(fontSize: isSmall ? 13 : 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(bool isSmall) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สินค้าทั้งหมด ${_products.length} รายการ',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._products.map((product) => _buildProductRow(product, isSmall)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow(Product product, bool isSmall) {
    _controllers.putIfAbsent(product.id, () => TextEditingController(text: '0'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(fontSize: isSmall ? 14 : 15, fontWeight: FontWeight.w500),
                ),
                Text(
                  product.category,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 90,
            child: TextField(
              controller: _controllers[product.id],
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              onTap: () => _controllers[product.id]?.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _controllers[product.id]!.text.length,
              ),
              decoration: InputDecoration(
                labelText: 'จำนวน',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        _errorMessage!,
        style: TextStyle(color: Colors.red.shade700),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBottomBar(double padding) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        padding,
        12,
        padding,
        12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: PrimaryButton(
        text: 'ยืนยันการนับสต็อก',
        onPressed: _onConfirm,
        isLoading: _isSubmitting,
        icon: Icons.check_circle_outline,
        fullWidth: true,
      ),
    );
  }
}
