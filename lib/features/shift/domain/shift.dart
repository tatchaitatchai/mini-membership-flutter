class Shift {
  final String id;
  final String storeName;
  final String staffName;
  final double startingCash;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double? actualCash;
  final double? expectedCash;
  final double? cashDifference;
  final Map<String, StockCount>? stockCounts;
  final bool isOpen;

  const Shift({
    required this.id,
    required this.storeName,
    required this.staffName,
    required this.startingCash,
    required this.startedAt,
    this.endedAt,
    this.actualCash,
    this.expectedCash,
    this.cashDifference,
    this.stockCounts,
    required this.isOpen,
  });

  Shift copyWith({
    String? id,
    String? storeName,
    String? staffName,
    double? startingCash,
    DateTime? startedAt,
    DateTime? endedAt,
    double? actualCash,
    double? expectedCash,
    double? cashDifference,
    Map<String, StockCount>? stockCounts,
    bool? isOpen,
  }) {
    return Shift(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      staffName: staffName ?? this.staffName,
      startingCash: startingCash ?? this.startingCash,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      actualCash: actualCash ?? this.actualCash,
      expectedCash: expectedCash ?? this.expectedCash,
      cashDifference: cashDifference ?? this.cashDifference,
      stockCounts: stockCounts ?? this.stockCounts,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}

class StockCount {
  final String productId;
  final String productName;
  final int expected;
  final int actual;
  final int difference;

  const StockCount({
    required this.productId,
    required this.productName,
    required this.expected,
    required this.actual,
    required this.difference,
  });
}

class ShiftSummary {
  final double totalSales;
  final int orderCount;
  final double expectedCash;

  const ShiftSummary({required this.totalSales, required this.orderCount, required this.expectedCash});
}
