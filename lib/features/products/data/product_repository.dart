import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/product.dart';

class ProductRepository {
  final List<Product> _products = [
    const Product(id: 'P001', name: 'Espresso', category: 'Coffee', price: 3.50, stock: 50),
    const Product(id: 'P002', name: 'Cappuccino', category: 'Coffee', price: 4.50, stock: 45),
    const Product(id: 'P003', name: 'Latte', category: 'Coffee', price: 4.75, stock: 40),
    const Product(id: 'P004', name: 'Americano', category: 'Coffee', price: 3.75, stock: 38),
    const Product(id: 'P005', name: 'Croissant', category: 'Pastry', price: 3.00, stock: 25, lowStockThreshold: 10),
    const Product(id: 'P006', name: 'Muffin', category: 'Pastry', price: 2.50, stock: 8, lowStockThreshold: 10),
    const Product(id: 'P007', name: 'Sandwich', category: 'Food', price: 7.50, stock: 20),
    const Product(id: 'P008', name: 'Bagel', category: 'Food', price: 3.50, stock: 15),
    const Product(id: 'P009', name: 'Orange Juice', category: 'Beverage', price: 4.00, stock: 30),
    const Product(id: 'P010', name: 'Iced Tea', category: 'Beverage', price: 3.50, stock: 4, lowStockThreshold: 5),
  ];

  Future<List<Product>> getAllProducts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_products);
  }

  Future<List<String>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _products.map((p) => p.category).toSet().toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 300));
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
    await Future.delayed(const Duration(milliseconds: 200));
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
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _products[index] = _products[index].copyWith(lowStockThreshold: threshold);
    }
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});
