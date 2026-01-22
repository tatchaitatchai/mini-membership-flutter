import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/shift.dart';

class ShiftRepository {
  final SharedPreferences _prefs;
  Shift? _currentShift;

  static const _shiftOpenKey = 'shift_open';
  static const _shiftIdKey = 'shift_id';
  static const _shiftStartingCashKey = 'shift_starting_cash';
  static const _shiftStartTimeKey = 'shift_start_time';

  ShiftRepository(this._prefs);

  bool isShiftOpen() {
    return _prefs.getBool(_shiftOpenKey) ?? false;
  }

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
    await _prefs.setString(_shiftIdKey, shiftId);
    await _prefs.setDouble(_shiftStartingCashKey, startingCash);
    await _prefs.setString(_shiftStartTimeKey, now.toIso8601String());
  }

  Shift? getCurrentShift() {
    if (!isShiftOpen()) return null;

    if (_currentShift != null) return _currentShift;

    final shiftId = _prefs.getString(_shiftIdKey);
    final startingCash = _prefs.getDouble(_shiftStartingCashKey);
    final startTimeStr = _prefs.getString(_shiftStartTimeKey);

    if (shiftId == null || startingCash == null || startTimeStr == null) {
      return null;
    }

    _currentShift = Shift(
      id: shiftId,
      storeName: 'Demo Store',
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
