class StockTransfer {
  final int id;
  final int? fromBranchId;
  final String? fromBranchName;
  final int toBranchId;
  final String toBranchName;
  final String status;
  final String? sentByName;
  final String? receivedByName;
  final DateTime? sentAt;
  final DateTime? receivedAt;
  final String? note;
  final List<StockTransferItem> items;
  final DateTime createdAt;

  const StockTransfer({
    required this.id,
    this.fromBranchId,
    this.fromBranchName,
    required this.toBranchId,
    required this.toBranchName,
    required this.status,
    this.sentByName,
    this.receivedByName,
    this.sentAt,
    this.receivedAt,
    this.note,
    required this.items,
    required this.createdAt,
  });

  factory StockTransfer.fromJson(Map<String, dynamic> json) {
    return StockTransfer(
      id: json['id'] as int,
      fromBranchId: json['from_branch_id'] as int?,
      fromBranchName: json['from_branch_name'] as String?,
      toBranchId: json['to_branch_id'] as int,
      toBranchName: json['to_branch_name'] as String,
      status: json['status'] as String,
      sentByName: json['sent_by_name'] as String?,
      receivedByName: json['received_by_name'] as String?,
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String) : null,
      receivedAt: json['received_at'] != null ? DateTime.parse(json['received_at'] as String) : null,
      note: json['note'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => StockTransferItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isWithdrawal => fromBranchId == toBranchId;
  bool get isSent => status == 'SENT';
  bool get isReceived => status == 'RECEIVED';
  bool get isCancelled => status == 'CANCELLED';
}

class StockTransferItem {
  final int id;
  final int productId;
  final String productName;
  final int sendCount;
  final int receiveCount;

  const StockTransferItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sendCount,
    required this.receiveCount,
  });

  factory StockTransferItem.fromJson(Map<String, dynamic> json) {
    return StockTransferItem(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      sendCount: json['send_count'] as int,
      receiveCount: json['receive_count'] as int,
    );
  }
}

class StockTransferListResponse {
  final List<StockTransfer> transfers;
  final int total;

  const StockTransferListResponse({
    required this.transfers,
    required this.total,
  });

  factory StockTransferListResponse.fromJson(Map<String, dynamic> json) {
    return StockTransferListResponse(
      transfers: (json['transfers'] as List<dynamic>?)
              ?.map((e) => StockTransfer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
    );
  }
}
