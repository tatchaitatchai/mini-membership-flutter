import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/services/api_client.dart';
import '../domain/shift.dart';
import 'models/shift_models.dart';

class ShiftRepository {
  final SharedPreferences _prefs;
  final ApiClient _apiClient;
  Shift? _currentShift;

  static const _shiftOpenKey = 'shift_open';
  static const _shiftIdKey = 'shift_id';
  static const _shiftStartingCashKey = 'shift_starting_cash';
  static const _shiftStartTimeKey = 'shift_start_time';
  static const _branchIdKey = 'branch_id';
  static const _branchNameKey = 'branch_name';

  ShiftRepository(this._prefs, this._apiClient);

  bool isShiftOpen() {
    return _prefs.getBool(_shiftOpenKey) ?? false;
  }

  // API Methods
  Future<List<BranchInfo>> getBranches() async {
    final response = await _apiClient.get<ListBranchesResponse>(
      '/api/v2/branches',
      requireAuth: true,
      fromJson: ListBranchesResponse.fromJson,
    );
    if (response.isSuccess && response.data != null) {
      return response.data!.branches;
    }
    return [];
  }

  Future<SelectBranchResponse?> selectBranch(int branchId) async {
    final response = await _apiClient.post<SelectBranchResponse>(
      '/api/v2/branches/select',
      body: {'branch_id': branchId},
      requireAuth: true,
      fromJson: SelectBranchResponse.fromJson,
    );
    if (response.isSuccess && response.data != null) {
      await _prefs.setInt(_branchIdKey, response.data!.branchId);
      await _prefs.setString(_branchNameKey, response.data!.branchName);
      return response.data;
    }
    return null;
  }

  Future<OpenShiftResponse?> openShiftApi(double startingCash) async {
    final response = await _apiClient.post<OpenShiftResponse>(
      '/api/v2/shifts/open',
      body: {'starting_cash': startingCash},
      requireAuth: true,
      fromJson: OpenShiftResponse.fromJson,
    );
    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      await _prefs.setBool(_shiftOpenKey, true);
      await _prefs.setInt(_shiftIdKey, data.shiftId);
      await _prefs.setDouble(_shiftStartingCashKey, data.startingCash);
      await _prefs.setString(_shiftStartTimeKey, data.startedAt.toIso8601String());
      return data;
    }
    return null;
  }

  Future<CurrentShiftResponse?> getCurrentShiftApi() async {
    final response = await _apiClient.get<CurrentShiftResponse>(
      '/api/v2/shifts/current',
      requireAuth: true,
      fromJson: CurrentShiftResponse.fromJson,
    );
    if (response.isSuccess && response.data != null) {
      return response.data;
    }
    return null;
  }

  int? getSelectedBranchId() {
    return _prefs.getInt(_branchIdKey);
  }

  String? getSelectedBranchName() {
    return _prefs.getString(_branchNameKey);
  }

  Future<void> clearBranchSelection() async {
    await _prefs.remove(_branchIdKey);
    await _prefs.remove(_branchNameKey);
  }

  // Legacy local methods (kept for backward compatibility)
  Future<void> openShift({required String storeName, required String staffName, required double startingCash}) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final shiftId = 'SHIFT_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    _currentShift = Shift(
      id: shiftId,
      storeName: storeName,
      staffName: staffName,
      startingCash: startingCash,
      startedAt: now,
      isOpen: true,
    );

    await _prefs.setBool(_shiftOpenKey, true);
    await _prefs.setString(_shiftIdKey, shiftId.toString());
    await _prefs.setDouble(_shiftStartingCashKey, startingCash);
    await _prefs.setString(_shiftStartTimeKey, now.toIso8601String());
  }

  Shift? getCurrentShift() {
    if (!isShiftOpen()) return null;

    if (_currentShift != null) return _currentShift;

    // Handle both int and string for backward compatibility
    String? shiftIdStr;
    final shiftIdInt = _prefs.getInt(_shiftIdKey);
    if (shiftIdInt != null) {
      shiftIdStr = shiftIdInt.toString();
    } else {
      shiftIdStr = _prefs.getString(_shiftIdKey);
    }

    final startingCash = _prefs.getDouble(_shiftStartingCashKey);
    final startTimeStr = _prefs.getString(_shiftStartTimeKey);
    final branchName = _prefs.getString(_branchNameKey);

    if (shiftIdStr == null || startingCash == null || startTimeStr == null) {
      return null;
    }

    _currentShift = Shift(
      id: shiftIdStr,
      storeName: branchName ?? 'Store',
      staffName: 'Staff',
      startingCash: startingCash,
      startedAt: DateTime.parse(startTimeStr),
      isOpen: true,
    );

    return _currentShift;
  }

  Future<void> closeShift({
    required double actualCash,
    required double expectedCash,
    required Map<String, StockCount> stockCounts,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final cashDifference = actualCash - expectedCash;

    _currentShift = _currentShift?.copyWith(
      endedAt: DateTime.now(),
      actualCash: actualCash,
      expectedCash: expectedCash,
      cashDifference: cashDifference,
      stockCounts: stockCounts,
      isOpen: false,
    );

    await _prefs.remove(_shiftOpenKey);
    await _prefs.remove(_shiftIdKey);
    await _prefs.remove(_shiftStartingCashKey);
    await _prefs.remove(_shiftStartTimeKey);
  }

  ShiftSummary calculateShiftSummary(List<dynamic> orders) {
    double totalSales = 0;
    int orderCount = 0;

    for (var order in orders) {
      totalSales += order.total;
      orderCount++;
    }

    final startingCash = _currentShift?.startingCash ?? 0;
    final expectedCash = startingCash + totalSales;

    return ShiftSummary(totalSales: totalSales, orderCount: orderCount, expectedCash: expectedCash);
  }
}

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  throw UnimplementedError('ShiftRepository must be initialized in main');
});
