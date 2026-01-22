class Promotion {
  final String id;
  final String name;
  final String description;
  final PromotionType type;
  final double value;
  final bool isActive;

  const Promotion({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    this.isActive = true,
  });

  double calculateDiscount(double subtotal) {
    switch (type) {
      case PromotionType.percentage:
        return subtotal * (value / 100);
      case PromotionType.fixedAmount:
        return value;
      case PromotionType.buyXGetY:
        return 0;
    }
  }

  String get displayValue {
    switch (type) {
      case PromotionType.percentage:
        return '${value.toStringAsFixed(0)}% OFF';
      case PromotionType.fixedAmount:
        return '\$${value.toStringAsFixed(2)} OFF';
      case PromotionType.buyXGetY:
        return 'Buy ${value.toInt()} Get 1 FREE';
    }
  }
}

enum PromotionType { percentage, fixedAmount, buyXGetY }
