import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  static const _storeEmailKey = 'store_email';
  static const _staffNameKey = 'staff_name';
  static const _pinVerifiedKey = 'pin_verified_at';

  static const _validStaffPins = {'1234': 'John Staff', '5678': 'Jane Staff'};
  static const _validManagerPin = '9999';
  static const _validStoreEmail = 'demo@store.com';

  AuthRepository(this._secureStorage, this._prefs);

  Future<bool> loginStore(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (email.toLowerCase() == _validStoreEmail) {
      await _prefs.setString(_storeEmailKey, email);
      return true;
    }
    return false;
  }

  bool isStoreLoggedIn() {
    return _prefs.getString(_storeEmailKey) != null;
  }

  String? getStoreEmail() {
    return _prefs.getString(_storeEmailKey);
  }

  Future<String?> verifyStaffPin(String pin) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final staffName = _validStaffPins[pin];
    if (staffName != null) {
      await _prefs.setString(_staffNameKey, staffName);
      await _secureStorage.write(key: _pinVerifiedKey, value: DateTime.now().millisecondsSinceEpoch.toString());
      return staffName;
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
    await Future.delayed(const Duration(milliseconds: 300));
    return pin == _validManagerPin;
  }

  Future<void> logout() async {
    await _prefs.remove(_storeEmailKey);
    await _prefs.remove(_staffNameKey);
    await _secureStorage.delete(key: _pinVerifiedKey);
  }

  Future<bool> registerBusiness({required String email, required String password, required String businessName}) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('AuthRepository must be initialized in main');
});
