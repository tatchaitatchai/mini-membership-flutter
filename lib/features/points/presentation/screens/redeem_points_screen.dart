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
  // step 0 = search customer, 1 = show groups, 2 = show products in group
  int _step = 0;
  Customer? _selectedCustomer;
  CustomerPointsInfo? _customerPoints;
  bool _isLoading = false;

  // step 2: selected group & products
  CustomerGroupPointsInfo? _selectedGroup;
  List<RedeemableGroupProduct> _groupProducts = [];

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

  Future<void> _onGroupSelected(CustomerGroupPointsInfo group) async {
    setState(() {
      _selectedGroup = group;
      _isLoading = true;
    });
    final pointsRepo = ref.read(pointsRepositoryProvider);
    final resp = await pointsRepo.getGroupRedeemableProducts(group.pointGroupId);
    if (!mounted) return;
    setState(() {
      _groupProducts = resp?.products ?? [];
      _isLoading = false;
      _step = 2;
    });
  }

  Future<void> _redeemProduct(RedeemableGroupProduct product, int quantity) async {
    if (_selectedGroup == null) return;

    setState(() => _isLoading = true);
    final pointsRepo = ref.read(pointsRepositoryProvider);
    final result = await pointsRepo.redeemGroupPoints(
      RedeemGroupPointsRequest(
        customerId: int.parse(_selectedCustomer!.id),
        pointGroupId: _selectedGroup!.pointGroupId,
        productId: product.productId,
        quantity: quantity,
      ),
    );

    if (!mounted) return;

    if (result != null) {
      ToastHelper.success(context, result.message);
      // Refresh customer points and products
      await _loadCustomerPoints();
      final resp = await pointsRepo.getGroupRedeemableProducts(_selectedGroup!.pointGroupId);
      if (mounted) {
        setState(() {
          _groupProducts = resp?.products ?? [];
          // Update selected group from refreshed data
          _selectedGroup = _customerPoints?.groups.cast<CustomerGroupPointsInfo?>().firstWhere(
            (g) => g?.pointGroupId == _selectedGroup!.pointGroupId,
            orElse: () => _selectedGroup,
          );
        });
      }
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
          onPressed: () {
            if (_step == 2) {
              setState(() => _step = 1);
            } else if (_step == 1) {
              setState(() => _step = 0);
            } else {
              if (context.canPop()) context.pop();
            }
          },
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
        return _GroupListStep(
          customer: _selectedCustomer!,
          customerPoints: _customerPoints,
          isLoading: _isLoading,
          onBack: () => setState(() => _step = 0),
          onGroupSelected: _onGroupSelected,
        );
      case 2:
        return _GroupProductsStep(
          customer: _selectedCustomer!,
          group: _selectedGroup!,
          products: _groupProducts,
          isLoading: _isLoading,
          onBack: () => setState(() => _step = 1),
          onRedeem: _redeemProduct,
        );
      default:
        return const SizedBox();
    }
  }
}

// ── Step 0: Customer Search ─────────────────────────────────────────

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

// ── Step 1: Group List ──────────────────────────────────────────────

class _GroupListStep extends StatelessWidget {
  final Customer customer;
  final CustomerPointsInfo? customerPoints;
  final bool isLoading;
  final VoidCallback onBack;
  final Function(CustomerGroupPointsInfo) onGroupSelected;

  const _GroupListStep({
    required this.customer,
    required this.customerPoints,
    required this.isLoading,
    required this.onBack,
    required this.onGroupSelected,
  });

  @override
  Widget build(BuildContext context) {
    final groups = customerPoints?.groups ?? [];

    return Column(
      children: [
        _buildCustomerInfo(context),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : groups.isEmpty
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
                  itemCount: groups.length,
                  itemBuilder: (context, index) => _buildGroupCard(context, groups[index]),
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
                '${customerPoints?.groups.length ?? 0} กลุ่ม',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text('ที่มีแต้มสะสม', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, CustomerGroupPointsInfo group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onGroupSelected(group),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: group.canRedeem ? Colors.green[50] : Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.stars, color: group.canRedeem ? Colors.green : Colors.amber[700], size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.groupName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.stars, color: Colors.amber[700], size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${group.points}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber[800]),
                        ),
                        Text(
                          ' / ${group.pointsToRedeem} แต้ม',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: group.pointsToRedeem > 0 ? (group.points / group.pointsToRedeem).clamp(0.0, 1.0) : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(group.canRedeem ? Colors.green : Colors.amber),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (group.canRedeem)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                  child: const Text(
                    'แลกได้',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                )
              else
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
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

// ── Step 2: Products in Group ───────────────────────────────────────

class _GroupProductsStep extends StatelessWidget {
  final Customer customer;
  final CustomerGroupPointsInfo group;
  final List<RedeemableGroupProduct> products;
  final bool isLoading;
  final VoidCallback onBack;
  final Function(RedeemableGroupProduct, int) onRedeem;

  const _GroupProductsStep({
    required this.customer,
    required this.group,
    required this.products,
    required this.isLoading,
    required this.onBack,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildGroupHeader(context),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : products.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'ไม่มีสินค้าในกลุ่มนี้',
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
                  itemBuilder: (context, index) => _buildProductCard(context, products[index]),
                ),
        ),
        _buildBottomBar(context),
      ],
    );
  }

  Widget _buildGroupHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('กลุ่ม: ${group.groupName}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stars, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${group.points}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber[800]),
                      ),
                    ],
                  ),
                  Text('แลกใช้ ${group.pointsToRedeem} แต้ม', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, RedeemableGroupProduct product) {
    final canRedeem = group.canRedeem && product.onStock > 0;

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
                  const SizedBox(height: 4),
                  Text(
                    '฿${double.tryParse(product.basePrice)?.toStringAsFixed(2) ?? product.basePrice}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.onStock > 0 ? 'คงเหลือ ${product.onStock} ชิ้น' : 'สินค้าหมด',
                    style: TextStyle(
                      fontSize: 12,
                      color: product.onStock > 0 ? Colors.green[700] : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: canRedeem ? () => _showRedeemDialog(context, product) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canRedeem ? Colors.green : Colors.grey[300],
                foregroundColor: canRedeem ? Colors.white : Colors.grey[600],
              ),
              child: const Text('แลก'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRedeemDialog(BuildContext context, RedeemableGroupProduct product) {
    int quantity = 1;
    // Max quantity limited by points and stock
    final maxByPoints = group.pointsToRedeem > 0 ? (group.points / group.pointsToRedeem).floor() : 0;
    final maxQuantity = maxByPoints < product.onStock ? maxByPoints : product.onStock;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final totalPointsUsed = group.pointsToRedeem * quantity;
          return AlertDialog(
            title: Text('แลก ${product.productName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('คุณมี ${group.points} แต้ม (กลุ่ม ${group.groupName})'),
                Text('ใช้ ${group.pointsToRedeem} แต้ม ต่อ 1 ชิ้น'),
                Text('คงเหลือ ${product.onStock} ชิ้น', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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
      child: SecondaryButton(text: 'กลับหน้ากลุ่ม', onPressed: onBack),
    );
  }
}
