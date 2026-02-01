import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/services/api_client.dart';
import 'models/auth_models.dart';

class AuthRepository {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;
  final ApiClient _apiClient;

  static const _storeEmailKey = 'store_email';
  static const _storeNameKey = 'store_name';
  static const _storeIdKey = 'store_id';
  static const _branchIdKey = 'branch_id';
  static const _staffNameKey = 'staff_name';
  static const _staffIdKey = 'staff_id';
  static const _isManagerKey = 'is_manager';
  static const _pinVerifiedKey = 'pin_verified_at';

  AuthRepository(this._secureStorage, this._prefs, this._apiClient);

  Future<LoginResponse?> loginStore(String email, String password) async {
    final response = await _apiClient.post<LoginResponse>(
      '/api/v2/auth/login',
      body: {'email': email, 'password': password},
      fromJson: LoginResponse.fromJson,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      await _apiClient.setSessionToken(data.sessionToken);
      await _prefs.setString(_storeEmailKey, email);
      await _prefs.setString(_storeNameKey, data.storeName);
      await _prefs.setInt(_storeIdKey, data.storeId);
      if (data.branchId != null) {
        await _prefs.setInt(_branchIdKey, data.branchId!);
      }
      return data;
    }
    return null;
  }

  int? getBranchId() {
    return _prefs.getInt(_branchIdKey);
  }

  bool isStoreLoggedIn() {
    return _prefs.getString(_storeEmailKey) != null;
  }

  String? getStoreEmail() {
    return _prefs.getString(_storeEmailKey);
  }

  Future<String?> verifyStaffPin(String pin) async {
    final response = await _apiClient.post<PinVerifyResponse>(
      '/api/v2/auth/verify-pin',
      body: {'pin': pin},
      requireAuth: true,
      fromJson: PinVerifyResponse.fromJson,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      await _prefs.setString(_staffNameKey, data.staffName);
      await _prefs.setInt(_staffIdKey, data.staffId);
      await _prefs.setBool(_isManagerKey, data.isManager);
      await _secureStorage.write(key: _pinVerifiedKey, value: DateTime.now().millisecondsSinceEpoch.toString());
      return data.staffName;
    }
    return null;
  }

  bool isPinVerified() {
    return _prefs.getString(_staffNameKey) != null;
  }

  String? getCurrentStaffName() {
    return _prefs.getString(_staffNameKey);
  }

  Future<void> invalidatePin() async {
    await _secureStorage.delete(key: _pinVerifiedKey);
    await _prefs.remove(_staffNameKey);
  }

  Future<bool> verifyManagerPin(String pin) async {
    final isManager = _prefs.getBool(_isManagerKey) ?? false;
    if (isManager) {
      return true;
    }
    final response = await _apiClient.post<PinVerifyResponse>(
      '/api/mobile/v1/auth/verify-pin',
      body: {'pin': pin},
      requireAuth: true,
      fromJson: PinVerifyResponse.fromJson,
    );
    return response.isSuccess && response.data?.isManager == true;
  }

  Future<void> logout() async {
    await _apiClient.post('/api/mobile/v1/auth/logout', requireAuth: true);
    await _apiClient.clearSessionToken();
    await _prefs.remove(_storeEmailKey);
    await _prefs.remove(_storeNameKey);
    await _prefs.remove(_storeIdKey);
    await _prefs.remove(_staffNameKey);
    await _prefs.remove(_staffIdKey);
    await _prefs.remove(_isManagerKey);
    await _secureStorage.delete(key: _pinVerifiedKey);
  }

  Future<bool> registerBusiness({required String email, required String password, required String businessName}) async {
    final response = await _apiClient.post<RegisterResponse>(
      '/api/mobile/v1/auth/register',
      body: {'email': email, 'password': password, 'business_name': businessName},
      fromJson: RegisterResponse.fromJson,
    );
    return response.isSuccess;
  }

  Future<bool> validateSession() async {
    final response = await _apiClient.get<SessionInfo>(
      '/api/mobile/v1/auth/session',
      requireAuth: true,
      fromJson: SessionInfo.fromJson,
    );
    return response.isSuccess;
  }

  String? getStoreName() {
    return _prefs.getString(_storeNameKey);
  }

  int? getStoreId() {
    return _prefs.getInt(_storeIdKey);
  }

  bool isManager() {
    return _prefs.getBool(_isManagerKey) ?? false;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('AuthRepository must be initialized in main');
});
