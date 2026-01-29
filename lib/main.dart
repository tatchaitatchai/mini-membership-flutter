/// POS ME - Modern Tablet POS System
///
/// DEMO APP - UI ONLY (No backend, no real API)
///
/// HOW TO RUN:
/// 1. Add dependencies to pubspec.yaml:
///    - flutter_riverpod: ^2.4.0
///    - go_router: ^12.0.0
///    - flutter_secure_storage: ^9.0.0
///    - shared_preferences: ^2.2.2
/// 2. Run: flutter pub get
/// 3. Run: flutter run
///
/// DEMO DATA:
/// - Store Email: demo@store.com
/// - Staff PIN: 1234 or 5678
/// - Manager PIN: 9999
/// - Products: 10 items with stock
/// - Customers: Sample customers with last4 codes
/// - Promotions: 10% off, Buy 2 Get 1, etc.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'common/services/api_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/shift/data/shift_repository.dart';

const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8085');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

  final sharedPreferences = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  final apiClient = ApiClient(baseUrl: apiBaseUrl, secureStorage: secureStorage);
  final authRepository = AuthRepository(secureStorage, sharedPreferences, apiClient);
  final shiftRepository = ShiftRepository(sharedPreferences, apiClient);

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        shiftRepositoryProvider.overrideWithValue(shiftRepository),
      ],
      child: const POSMeApp(),
    ),
  );
}
