import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/customer.dart';

class CustomerRepository {
  final List<Customer> _customers = const [
    Customer(id: 'C001', code: 'CUST1234', last4: '1234', fullName: 'Alice Johnson', phone: '555-0101'),
    Customer(id: 'C002', code: 'CUST5678', last4: '5678', fullName: 'Bob Smith', phone: '555-0102'),
    Customer(id: 'C003', code: 'CUST9012', last4: '9012', fullName: 'Carol White', phone: '555-0103'),
    Customer(id: 'C004', code: 'CUST3456', last4: '3456', fullName: 'David Brown', phone: '555-0104'),
    Customer(id: 'C005', code: 'CUST7890', last4: '7890', fullName: 'Emma Davis', phone: '555-0105'),
    Customer(id: 'C006', code: 'CUST1111', last4: '1111', fullName: 'Frank Miller', phone: '555-0106'),
    Customer(id: 'C007', code: 'CUST2222', last4: '2222', fullName: 'Grace Wilson', phone: '555-0107'),
    Customer(id: 'C008', code: 'CUST3333', last4: '3333', fullName: 'Henry Moore', phone: '555-0108'),
    Customer(id: 'C009', code: 'CUST4444', last4: '4444', fullName: 'Ivy Taylor', phone: '555-0109'),
    Customer(id: 'C010', code: 'CUST1234', last4: '1234', fullName: 'Jack Anderson', phone: '555-0110'),
  ];

  Future<List<Customer>> findByLast4(String last4) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _customers.where((c) => c.last4 == last4).toList();
  }

  Future<Customer?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});
