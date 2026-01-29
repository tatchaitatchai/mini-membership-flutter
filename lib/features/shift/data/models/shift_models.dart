class BranchInfo {
  final int id;
  final String branchName;
  final bool isShiftOpened;

  BranchInfo({
    required this.id,
    required this.branchName,
    required this.isShiftOpened,
  });

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
      branches: (json['branches'] as List<dynamic>)
          .map((e) => BranchInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SelectBranchResponse {
  final int branchId;
  final String branchName;
  final bool isShiftOpened;

  SelectBranchResponse({
    required this.branchId,
    required this.branchName,
    required this.isShiftOpened,
  });

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

  CurrentShiftResponse({
    required this.hasActiveShift,
    this.shift,
  });

  factory CurrentShiftResponse.fromJson(Map<String, dynamic> json) {
    return CurrentShiftResponse(
      hasActiveShift: json['has_active_shift'] as bool,
      shift: json['shift'] != null
          ? ShiftInfo.fromJson(json['shift'] as Map<String, dynamic>)
          : null,
    );
  }
}
