import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/services/api_client.dart';
import '../domain/points.dart';

class PointsRepository {
  final ApiClient _apiClient;

  PointsRepository(this._apiClient);

  Future<CustomerPointsInfo?> getCustomerPoints(int customerId, String customerName, String customerCode) async {
    final response = await _apiClient.get<CustomerPointsInfo>(
      '/api/v2/points/customer/$customerId?name=$customerName&code=$customerCode',
      requireAuth: true,
      fromJson: CustomerPointsInfo.fromJson,
    );

    if (response.isSuccess && response.data != null) {
      return response.data;
    }
    return null;
  }

  Future<List<RedeemableProduct>> getRedeemableProducts() async {
    final response = await _apiClient.get<RedeemableProductsResponse>(
      '/api/v2/points/redeemable-products',
      requireAuth: true,
      fromJson: RedeemableProductsResponse.fromJson,
    );

    if (response.isSuccess && response.data != null) {
      return response.data!.products;
    }
    return [];
  }

  Future<RedeemPointsResponse?> redeemPoints(RedeemPointsRequest request) async {
    final response = await _apiClient.post<RedeemPointsResponse>(
      '/api/v2/points/redeem',
      body: request.toJson(),
      requireAuth: true,
      fromJson: RedeemPointsResponse.fromJson,
    );

    if (response.isSuccess && response.data != null) {
      return response.data;
    }
    return null;
  }

  Future<PointHistoryResponse?> getPointHistory(int customerId, {int page = 1, int limit = 20}) async {
    final response = await _apiClient.get<PointHistoryResponse>(
      '/api/v2/points/customer/$customerId/history?page=$page&limit=$limit',
      requireAuth: true,
      fromJson: PointHistoryResponse.fromJson,
    );

    if (response.isSuccess && response.data != null) {
      return response.data;
    }
    return null;
  }
}

final pointsRepositoryProvider = Provider<PointsRepository>((ref) {
  throw UnimplementedError('PointsRepository must be initialized in main');
});
