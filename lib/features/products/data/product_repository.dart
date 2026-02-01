import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/services/api_client.dart';
import '../../orders/data/models/order_models.dart';
import '../domain/product.dart';

class ProductRepository {
  final ApiClient _apiClient;
  List<Product> _products = [];

  ProductRepository(this._apiClient);

  Future<List<Product>> getAllProducts() async {
    final response = await _apiClient.get<ListProductsResponse>(
      '/api/v2/products',
      requireAuth: true,
      fromJson: ListProductsResponse.fromJson,
    );

    if (response.isSuccess && response.data != null) {
      _products = response.data!.products
          .map(
            (p) => Product(
              id: p.id.toString(),
              name: p.productName,
              category: p.categoryName ?? 'Uncategorized',
              price: p.basePrice,
              stock: p.onStock,
              imageUrl: p.imagePath,
            ),
          )
          .toList();
      return _products;
    }
    return _products;
  }

  Future<List<String>> getCategories() async {
    if (_products.isEmpty) {
      await getAllProducts();
    }
    return _products.map((p) => p.category).toSet().toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    if (_products.isEmpty) {
      await getAllProducts();
    }
    return _products.where((p) => p.category == category).toList();
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateStock(String productId, int newStock) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _products[index] = _products[index].copyWith(stock: newStock);
    }
  }

  Future<void> addStock(String productId, int quantity) async {
    final product = getProductById(productId);
    if (product != null) {
      await updateStock(productId, product.stock + quantity);
    }
  }

  Future<void> reduceStock(String productId, int quantity) async {
    final product = getProductById(productId);
    if (product != null) {
      await updateStock(productId, product.stock - quantity);
    }
  }

  List<Product> getLowStockProducts() {
    return _products.where((p) => p.isLowStock).toList();
  }

  Future<void> updateLowStockThreshold(String productId, int threshold) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _products[index] = _products[index].copyWith(lowStockThreshold: threshold);
    }
  }

  void clearCache() {
    _products = [];
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  throw UnimplementedError('ProductRepository must be initialized in main');
});
