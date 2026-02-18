import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/secondary_button.dart';
import '../../../../common/utils/toast_helper.dart';
import '../../../customers/domain/customer.dart';
import '../../../customers/data/customer_repository.dart';
import '../../data/points_repository.dart';
import '../../domain/points.dart';

class RedeemPointsScreen extends ConsumerStatefulWidget {
  const RedeemPointsScreen({super.key});

  @override
  ConsumerState<RedeemPointsScreen> createState() => _RedeemPointsScreenState();
}

class _RedeemPointsScreenState extends ConsumerState<RedeemPointsScreen> {
  int _step = 0;
  Customer? _selectedCustomer;
  CustomerPointsInfo? _customerPoints;
  bool _isLoading = false;

  Future<void> _loadCustomerPoints() async {
    if (_selectedCustomer == null || _selectedCustomer!.id == 'guest') return;

    setState(() => _isLoading = true);
    final pointsRepo = ref.read(pointsRepositoryProvider);
    final points = await pointsRepo.getCustomerPoints(
      int.parse(_selectedCustomer!.id),
      _selectedCustomer!.fullName,
      _selectedCustomer!.code,
    );
    setState(() {
      _customerPoints = points;
      _isLoading = false;
    });
  }

  void _onCustomerSelected(Customer customer) async {
    if (customer.id == 'guest') {
      ToastHelper.warning(context, 'กรุณาเลือกลูกค้าที่ลงทะเบียนแล้ว');
      return;
    }
    setState(() {
      _selectedCustomer = customer;
    });
    await _loadCustomerPoints();
    setState(() => _step = 1);
  }

  Future<void> _redeemProduct(CustomerProductPoints product, int quantity) async {
    if (!product.canRedeem) {
      ToastHelper.error(context, 'แต้มไม่เพียงพอสำหรับสินค้านี้');
      return;
    }

    setState(() => _isLoading = true);
    final pointsRepo = ref.read(pointsRepositoryProvider);
    final result = await pointsRepo.redeemPoints(
      RedeemPointsRequest(
        customerId: int.parse(_selectedCustomer!.id),
        productId: product.productId,
        quantity: quantity,
      ),
    );

    if (!mounted) return;

    if (result != null) {
      ToastHelper.success(context, result.message);
      // Refresh customer points
      await _loadCustomerPoints();
    } else {
      ToastHelper.error(context, 'ไม่สามารถแลกสินค้าได้ กรุณาลองใหม่');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แลกแต้มสะสม'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : null,
        ),
      ),
      body: _buildStepContent(),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _CustomerSearchStep(onCustomerSelected: _onCustomerSelected);
      case 1:
        return _RedeemProductsStep(
          customer: _selectedCustomer!,
          customerPoints: _customerPoints,
          isLoading: _isLoading,
          onBack: () => setState(() => _step = 0),
          onRedeem: _redeemProduct,
        );
      default:
        return const SizedBox();
    }
  }
}

class _CustomerSearchStep extends ConsumerStatefulWidget {
  final Function(Customer) onCustomerSelected;

  const _CustomerSearchStep({required this.onCustomerSelected});

  @override
  ConsumerState<_CustomerSearchStep> createState() => _CustomerSearchStepState();
}

class _CustomerSearchStepState extends ConsumerState<_CustomerSearchStep> {
  final _last4Controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _last4Controller.dispose();
    super.dispose();
  }

  Future<void> _searchCustomer() async {
    final last4 = _last4Controller.text.trim();
    if (last4.length != 4) {
      ToastHelper.warning(context, 'กรอกตัวเลข 4 หลัก');
      return;
    }

    setState(() => _isLoading = true);
    final customerRepo = ref.read(customerRepositoryProvider);
    final customers = await customerRepo.findByLast4(last4);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (customers.isEmpty) {
      ToastHelper.info(context, 'ไม่พบข้อมูลลูกค้า');
    } else if (customers.length == 1) {
      widget.onCustomerSelected(customers.first);
    } else {
      _showCustomerSelection(customers);
    }
  }

  void _showCustomerSelection(List<Customer> customers) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกลูกค้า'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: customers.map((customer) {
            return ListTile(
              title: Text(customer.fullName),
              subtitle: Text(customer.code),
              onTap: () {
                Navigator.of(context).pop();
                widget.onCustomerSelected(customer);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(isSmall ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ขั้นตอนที่ 1: ค้นหาลูกค้า',
            style: TextStyle(fontSize: isSmall ? 18 : 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'กรอก 4 หลักท้ายของเบอร์โทรศัพท์เพื่อค้นหาลูกค้า',
            style: TextStyle(fontSize: isSmall ? 13 : 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _last4Controller,
            decoration: const InputDecoration(
              labelText: 'รหัสลูกค้า 4 หลักท้าย',
              hintText: 'กรอก 4 หลัก',
              prefixIcon: Icon(Icons.search),
            ),
            keyboardType: TextInputType.number,
            maxLength: 4,
          ),
          const SizedBox(height: 16),
          PrimaryButton(text: 'ค้นหา', onPressed: _searchCustomer, isLoading: _isLoading, icon: Icons.search),
        ],
      ),
    );
  }
}

class _RedeemProductsStep extends StatelessWidget {
  final Customer customer;
  final CustomerPointsInfo? customerPoints;
  final bool isLoading;
  final VoidCallback onBack;
  final Function(CustomerProductPoints, int) onRedeem;

  const _RedeemProductsStep({
    required this.customer,
    required this.customerPoints,
    required this.isLoading,
    required this.onBack,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final products = customerPoints?.products ?? [];

    return Column(
      children: [
        _buildCustomerInfo(context),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : products.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'ยังไม่มีแต้มสะสม\nซื้อสินค้าเพื่อสะสมแต้ม',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(context, products[index]);
                  },
                ),
        ),
        _buildBottomBar(context),
      ],
    );
  }

  Widget _buildCustomerInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('รหัส: ${customer.code}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${customerPoints?.products.length ?? 0} สินค้า',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text('ที่มีแต้มสะสม', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, CustomerProductPoints product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: product.imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.local_cafe, size: 30),
                      ),
                    )
                  : const Icon(Icons.local_cafe, size: 30, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  if (product.categoryName != null)
                    Text(product.categoryName!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.stars, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${product.points}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber[800]),
                      ),
                      Text(
                        ' / ${product.pointsToRedeem} แต้ม',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: product.pointsToRedeem > 0 ? (product.points / product.pointsToRedeem).clamp(0.0, 1.0) : 0,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(product.canRedeem ? Colors.green : Colors.amber),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: product.canRedeem ? () => _showRedeemDialog(context, product) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: product.canRedeem ? Colors.green : Colors.grey[300],
                foregroundColor: product.canRedeem ? Colors.white : Colors.grey[600],
              ),
              child: const Text('แลก'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRedeemDialog(BuildContext context, CustomerProductPoints product) {
    int quantity = 1;
    final maxQuantity = product.pointsToRedeem > 0 ? (product.points / product.pointsToRedeem).floor() : 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final totalPointsUsed = product.pointsToRedeem * quantity;
          return AlertDialog(
            title: Text('แลก ${product.productName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('คุณมี ${product.points} แต้ม'),
                Text('ใช้ ${product.pointsToRedeem} แต้ม ต่อ 1 ชิ้น'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: quantity > 1 ? () => setDialogState(() => quantity--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Container(
                      width: 60,
                      alignment: Alignment.center,
                      child: Text('$quantity', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: quantity < maxQuantity ? () => setDialogState(() => quantity++) : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stars, color: Colors.amber[700]),
                      const SizedBox(width: 8),
                      Text(
                        'ใช้ทั้งหมด $totalPointsUsed แต้ม',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber[900]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ยกเลิก')),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRedeem(product, quantity);
                },
                child: const Text('ยืนยันแลก'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: SecondaryButton(text: 'เปลี่ยนลูกค้า', onPressed: onBack),
    );
  }
}
