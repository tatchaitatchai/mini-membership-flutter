class LoginResponse {
  final String sessionToken;
  final int storeId;
  final int? branchId;
  final String storeName;
  final DateTime expiresAt;

  LoginResponse({
    required this.sessionToken,
    required this.storeId,
    this.branchId,
    required this.storeName,
    required this.expiresAt,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      sessionToken: json['session_token'] as String,
      storeId: json['store_id'] as int,
      branchId: json['branch_id'] as int?,
      storeName: json['store_name'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

class SessionInfo {
  final int storeId;
  final String storeName;
  final int? branchId;
  final String? branchName;
  final int? staffId;
  final String? staffName;
  final DateTime expiresAt;

  SessionInfo({
    required this.storeId,
    required this.storeName,
    this.branchId,
    this.branchName,
    this.staffId,
    this.staffName,
    required this.expiresAt,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      storeId: json['store_id'] as int,
      storeName: json['store_name'] as String,
      branchId: json['branch_id'] as int?,
      branchName: json['branch_name'] as String?,
      staffId: json['staff_id'] as int?,
      staffName: json['staff_name'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

class PinVerifyResponse {
  final int staffId;
  final String staffName;
  final bool isManager;

  PinVerifyResponse({required this.staffId, required this.staffName, required this.isManager});

  factory PinVerifyResponse.fromJson(Map<String, dynamic> json) {
    return PinVerifyResponse(
      staffId: json['staff_id'] as int,
      staffName: json['staff_name'] as String,
      isManager: json['is_manager'] as bool,
    );
  }
}

class RegisterResponse {
  final int storeId;
  final String storeName;
  final String message;

  RegisterResponse({required this.storeId, required this.storeName, required this.message});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      storeId: json['store_id'] as int,
      storeName: json['store_name'] as String,
      message: json['message'] as String,
    );
  }
}
