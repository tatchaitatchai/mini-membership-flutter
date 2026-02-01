import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/services/api_client.dart';
import '../../orders/data/models/order_models.dart';
import '../domain/customer.dart';

class CustomerRepository {
  final ApiClient _apiClient;

  CustomerRepository(this._apiClient);

  Future<List<Customer>> findByLast4(String last4) async {
    final response = await _apiClient.get<SearchCustomersResponse>(
      '/api/v2/customers/search?last4=$last4',
      requireAuth: true,
      fromJson: SearchCustomersResponse.fromJson,
    );

    if (response.isSuccess && response.data != null) {
      return response.data!.customers
          .map((c) => Customer(id: c.id.toString(), code: c.customerCode, last4: c.phoneLast4, fullName: c.fullName))
          .toList();
    }
    return [];
  }

  Future<Customer?> getById(String id) async {
    return null;
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  throw UnimplementedError('CustomerRepository must be initialized in main');
});
