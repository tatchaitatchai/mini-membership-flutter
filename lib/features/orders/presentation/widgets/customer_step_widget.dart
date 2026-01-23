import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/secondary_button.dart';
import '../../../customers/domain/customer.dart';
import '../../../customers/data/customer_repository.dart';

class CustomerStepWidget extends ConsumerStatefulWidget {
  final Function(Customer) onCustomerSelected;

  const CustomerStepWidget({super.key, required this.onCustomerSelected});

  @override
  ConsumerState<CustomerStepWidget> createState() => _CustomerStepWidgetState();
}

class _CustomerStepWidgetState extends ConsumerState<CustomerStepWidget> {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรอกตัวเลข 4 หลัก')));
      return;
    }

    setState(() => _isLoading = true);
    final customerRepo = ref.read(customerRepositoryProvider);
    final customers = await customerRepo.findByLast4(last4);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลลูกค้า')));
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ขั้นตอนที่ 1: ระบุลูกค้า', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: _last4Controller,
            decoration: const InputDecoration(labelText: 'รหัสลูกค้า 4 หลักท้าย', hintText: 'กรอก 4 หลัก'),
            keyboardType: TextInputType.number,
            maxLength: 4,
          ),
          const SizedBox(height: 16),
          PrimaryButton(text: 'ค้นหา', onPressed: _searchCustomer, isLoading: _isLoading),
          const SizedBox(height: 16),
          SecondaryButton(text: 'ดำเนินการในฐานะแขก', onPressed: () => widget.onCustomerSelected(Customer.guest())),
        ],
      ),
    );
  }
}
