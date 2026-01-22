class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final String? imageUrl;
  final int lowStockThreshold;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.lowStockThreshold = 5,
  });

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    int? stock,
    String? imageUrl,
    int? lowStockThreshold,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }

  bool get isLowStock => stock <= lowStockThreshold;
}
