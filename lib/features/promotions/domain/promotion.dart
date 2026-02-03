class PromotionTypeInfo {
  final int id;
  final String name;
  final String? detail;

  const PromotionTypeInfo({required this.id, required this.name, this.detail});

  factory PromotionTypeInfo.fromJson(Map<String, dynamic> json) {
    return PromotionTypeInfo(id: json['id'] as int, name: json['name'] as String, detail: json['detail'] as String?);
  }
}

class PromotionConfig {
  final double? percentDiscount;
  final double? bahtDiscount;
  final double? totalPriceSetDiscount;
  final double? oldPriceSet;
  final int? countConditionProduct;

  const PromotionConfig({
    this.percentDiscount,
    this.bahtDiscount,
    this.totalPriceSetDiscount,
    this.oldPriceSet,
    this.countConditionProduct,
  });

  factory PromotionConfig.fromJson(Map<String, dynamic> json) {
    return PromotionConfig(
      percentDiscount: (json['percent_discount'] as num?)?.toDouble(),
      bahtDiscount: (json['baht_discount'] as num?)?.toDouble(),
      totalPriceSetDiscount: (json['total_price_set_discount'] as num?)?.toDouble(),
      oldPriceSet: (json['old_price_set'] as num?)?.toDouble(),
      countConditionProduct: json['count_condition_product'] as int?,
    );
  }
}

class PromotionProduct {
  final int productId;
  final String productName;
  final double basePrice;

  const PromotionProduct({required this.productId, required this.productName, required this.basePrice});

  factory PromotionProduct.fromJson(Map<String, dynamic> json) {
    return PromotionProduct(
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      basePrice: (json['base_price'] as num).toDouble(),
    );
  }
}

class Promotion {
  final int id;
  final String name;
  final PromotionTypeInfo promotionType;
  final PromotionConfig config;
  final List<PromotionProduct> products;
  final bool isBillLevel;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const Promotion({
    required this.id,
    required this.name,
    required this.promotionType,
    required this.config,
    required this.products,
    required this.isBillLevel,
    this.isActive = true,
    this.startsAt,
    this.endsAt,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as int,
      name: json['promotion_name'] as String,
      promotionType: PromotionTypeInfo.fromJson(json['promotion_type'] as Map<String, dynamic>),
      config: PromotionConfig.fromJson(json['config'] as Map<String, dynamic>),
      products:
          (json['products'] as List<dynamic>?)
              ?.map((e) => PromotionProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isBillLevel: json['is_bill_level'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      startsAt: json['starts_at'] != null ? DateTime.parse(json['starts_at'] as String) : null,
      endsAt: json['ends_at'] != null ? DateTime.parse(json['ends_at'] as String) : null,
    );
  }

  String get description {
    final typeName = promotionType.name;
    if (config.percentDiscount != null) {
      return 'ลด ${config.percentDiscount!.toStringAsFixed(0)}%';
    }
    if (config.bahtDiscount != null) {
      return 'ลด ${config.bahtDiscount!.toStringAsFixed(0)} บาท';
    }
    if (config.totalPriceSetDiscount != null && config.oldPriceSet != null) {
      return 'ราคาพิเศษ ${config.totalPriceSetDiscount!.toStringAsFixed(0)} บาท (ปกติ ${config.oldPriceSet!.toStringAsFixed(0)} บาท)';
    }
    if (config.countConditionProduct != null) {
      if (config.percentDiscount != null) {
        return 'ซื้อ ${config.countConditionProduct} ชิ้น ลด ${config.percentDiscount!.toStringAsFixed(0)}%';
      }
      if (config.bahtDiscount != null) {
        return 'ซื้อ ${config.countConditionProduct} ชิ้น ลด ${config.bahtDiscount!.toStringAsFixed(0)} บาท';
      }
    }
    return typeName;
  }

  String get displayValue {
    if (config.percentDiscount != null) {
      return '${config.percentDiscount!.toStringAsFixed(0)}%';
    }
    if (config.bahtDiscount != null) {
      return '฿${config.bahtDiscount!.toStringAsFixed(0)}';
    }
    if (config.totalPriceSetDiscount != null) {
      return '฿${config.totalPriceSetDiscount!.toStringAsFixed(0)}';
    }
    return '';
  }

  String get typeLabel {
    if (isBillLevel) return 'ลดท้ายบิล';
    return promotionType.name;
  }
}

class CalculateDiscountResponse {
  final int promotionId;
  final String promotionName;
  final double originalTotal;
  final double discountAmount;
  final double finalTotal;
  final bool isApplicable;
  final String? message;

  const CalculateDiscountResponse({
    required this.promotionId,
    required this.promotionName,
    required this.originalTotal,
    required this.discountAmount,
    required this.finalTotal,
    required this.isApplicable,
    this.message,
  });

  factory CalculateDiscountResponse.fromJson(Map<String, dynamic> json) {
    return CalculateDiscountResponse(
      promotionId: json['promotion_id'] as int,
      promotionName: json['promotion_name'] as String,
      originalTotal: (json['original_total'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num).toDouble(),
      finalTotal: (json['final_total'] as num).toDouble(),
      isApplicable: json['is_applicable'] as bool? ?? true,
      message: json['message'] as String?,
    );
  }
}

class DetectedPromotion {
  final int promotionId;
  final String promotionName;
  final String typeName;
  final double discountAmount;
  final double finalTotal;
  final bool isAutoApplied;

  const DetectedPromotion({
    required this.promotionId,
    required this.promotionName,
    required this.typeName,
    required this.discountAmount,
    required this.finalTotal,
    required this.isAutoApplied,
  });

  factory DetectedPromotion.fromJson(Map<String, dynamic> json) {
    return DetectedPromotion(
      promotionId: json['promotion_id'] as int,
      promotionName: json['promotion_name'] as String,
      typeName: json['type_name'] as String,
      discountAmount: (json['discount_amount'] as num).toDouble(),
      finalTotal: (json['final_total'] as num).toDouble(),
      isAutoApplied: json['is_auto_applied'] as bool? ?? false,
    );
  }
}
