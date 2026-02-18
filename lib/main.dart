/// POS ME - Point of Sale and Membership Management System
/// Copyright (c) 2026 POS ME Team. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'common/services/api_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/shift/data/shift_repository.dart';
import 'features/products/data/product_repository.dart';
import 'features/customers/data/customer_repository.dart';
import 'features/orders/data/order_repository.dart';
import 'features/points/data/points_repository.dart';

const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8085');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  final apiClient = ApiClient(baseUrl: apiBaseUrl, secureStorage: secureStorage);
  final authRepository = AuthRepository(secureStorage, sharedPreferences, apiClient);
  final shiftRepository = ShiftRepository(sharedPreferences, apiClient);
  final productRepository = ProductRepository(apiClient);
  final customerRepository = CustomerRepository(apiClient);
  final orderRepository = OrderRepository(apiClient);
  final pointsRepository = PointsRepository(apiClient);

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        shiftRepositoryProvider.overrideWithValue(shiftRepository),
        productRepositoryProvider.overrideWithValue(productRepository),
        customerRepositoryProvider.overrideWithValue(customerRepository),
        orderRepositoryProvider.overrideWithValue(orderRepository),
        pointsRepositoryProvider.overrideWithValue(pointsRepository),
      ],
      child: const POSMeApp(),
    ),
  );
}
