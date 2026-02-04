class BranchInfo {
  final int id;
  final String branchName;
  final bool isShiftOpened;

  BranchInfo({required this.id, required this.branchName, required this.isShiftOpened});

  factory BranchInfo.fromJson(Map<String, dynamic> json) {
    return BranchInfo(
      id: json['id'] as int,
      branchName: json['branch_name'] as String,
      isShiftOpened: json['is_shift_opened'] as bool,
    );
  }
}

class ListBranchesResponse {
  final List<BranchInfo> branches;

  ListBranchesResponse({required this.branches});

  factory ListBranchesResponse.fromJson(Map<String, dynamic> json) {
    return ListBranchesResponse(
      branches: (json['branches'] as List<dynamic>).map((e) => BranchInfo.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class SelectBranchResponse {
  final int branchId;
  final String branchName;
  final bool isShiftOpened;

  SelectBranchResponse({required this.branchId, required this.branchName, required this.isShiftOpened});

  factory SelectBranchResponse.fromJson(Map<String, dynamic> json) {
    return SelectBranchResponse(
      branchId: json['branch_id'] as int,
      branchName: json['branch_name'] as String,
      isShiftOpened: json['is_shift_opened'] as bool,
    );
  }
}

class OpenShiftResponse {
  final int shiftId;
  final int branchId;
  final String branchName;
  final double startingCash;
  final DateTime startedAt;

  OpenShiftResponse({
    required this.shiftId,
    required this.branchId,
    required this.branchName,
    required this.startingCash,
    required this.startedAt,
  });

  factory OpenShiftResponse.fromJson(Map<String, dynamic> json) {
    return OpenShiftResponse(
      shiftId: json['shift_id'] as int,
      branchId: json['branch_id'] as int,
      branchName: json['branch_name'] as String,
      startingCash: (json['starting_cash'] as num).toDouble(),
      startedAt: DateTime.parse(json['started_at'] as String),
    );
  }
}

class ShiftInfo {
  final int id;
  final int branchId;
  final String branchName;
  final double startingCash;
  final DateTime startedAt;

  ShiftInfo({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.startingCash,
    required this.startedAt,
  });

  factory ShiftInfo.fromJson(Map<String, dynamic> json) {
    return ShiftInfo(
      id: json['id'] as int,
      branchId: json['branch_id'] as int,
      branchName: json['branch_name'] as String,
      startingCash: (json['starting_cash'] as num).toDouble(),
      startedAt: DateTime.parse(json['started_at'] as String),
    );
  }
}

class CurrentShiftResponse {
  final bool hasActiveShift;
  final ShiftInfo? shift;

  CurrentShiftResponse({required this.hasActiveShift, this.shift});

  factory CurrentShiftResponse.fromJson(Map<String, dynamic> json) {
    return CurrentShiftResponse(
      hasActiveShift: json['has_active_shift'] as bool,
      shift: json['shift'] != null ? ShiftInfo.fromJson(json['shift'] as Map<String, dynamic>) : null,
    );
  }
}

class ShiftSummaryResponse {
  final int shiftId;
  final double startingCash;
  final double totalSales;
  final int orderCount;
  final double expectedCash;
  final double cancelledTotal;
  final int cancelledCount;

  ShiftSummaryResponse({
    required this.shiftId,
    required this.startingCash,
    required this.totalSales,
    required this.orderCount,
    required this.expectedCash,
    required this.cancelledTotal,
    required this.cancelledCount,
  });

  factory ShiftSummaryResponse.fromJson(Map<String, dynamic> json) {
    return ShiftSummaryResponse(
      shiftId: json['shift_id'] as int,
      startingCash: (json['starting_cash'] as num).toDouble(),
      totalSales: (json['total_sales'] as num).toDouble(),
      orderCount: json['order_count'] as int,
      expectedCash: (json['expected_cash'] as num).toDouble(),
      cancelledTotal: (json['cancelled_total'] as num?)?.toDouble() ?? 0,
      cancelledCount: json['cancelled_count'] as int? ?? 0,
    );
  }
}

class StockCountInput {
  final int productId;
  final int actualStock;

  StockCountInput({required this.productId, required this.actualStock});

  Map<String, dynamic> toJson() {
    return {'product_id': productId, 'actual_stock': actualStock};
  }
}

class CloseShiftRequest {
  final double actualCash;
  final String? note;
  final List<StockCountInput>? stockCounts;

  CloseShiftRequest({required this.actualCash, this.note, this.stockCounts});

  Map<String, dynamic> toJson() {
    return {
      'actual_cash': actualCash,
      if (note != null) 'note': note,
      if (stockCounts != null && stockCounts!.isNotEmpty) 'stock_counts': stockCounts!.map((e) => e.toJson()).toList(),
    };
  }
}

class CloseShiftResponse {
  final int shiftId;
  final int branchId;
  final String branchName;
  final double startingCash;
  final double expectedCash;
  final double actualCash;
  final double cashDifference;
  final double totalSales;
  final int orderCount;
  final DateTime startedAt;
  final DateTime endedAt;
  final String? closedBy;

  CloseShiftResponse({
    required this.shiftId,
    required this.branchId,
    required this.branchName,
    required this.startingCash,
    required this.expectedCash,
    required this.actualCash,
    required this.cashDifference,
    required this.totalSales,
    required this.orderCount,
    required this.startedAt,
    required this.endedAt,
    this.closedBy,
  });

  factory CloseShiftResponse.fromJson(Map<String, dynamic> json) {
    return CloseShiftResponse(
      shiftId: json['shift_id'] as int,
      branchId: json['branch_id'] as int,
      branchName: json['branch_name'] as String,
      startingCash: (json['starting_cash'] as num).toDouble(),
      expectedCash: (json['expected_cash'] as num).toDouble(),
      actualCash: (json['actual_cash'] as num).toDouble(),
      cashDifference: (json['cash_difference'] as num).toDouble(),
      totalSales: (json['total_sales'] as num).toDouble(),
      orderCount: json['order_count'] as int,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: DateTime.parse(json['ended_at'] as String),
      closedBy: json['closed_by'] as String?,
    );
  }
}
