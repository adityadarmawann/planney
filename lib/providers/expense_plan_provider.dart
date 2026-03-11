import 'package:flutter/material.dart';
import '../data/models/expense_plan_model.dart';
import '../data/repositories/expense_plan_repository.dart';
import '../core/services/calendar_service.dart';

class ExpensePlanProvider extends ChangeNotifier {
  final ExpensePlanRepository _repository;
  final CalendarService _calendarService = CalendarService();

  ExpensePlanProvider({required ExpensePlanRepository repository})
      : _repository = repository;

  List<ExpensePlan> _expensePlans = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _syncWarningMessage;
  DateTime _currentMonth = DateTime.now();

  List<ExpensePlan> get expensePlans => _expensePlans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get syncWarningMessage => _syncWarningMessage;
  DateTime get currentMonth => _currentMonth;

  // Load expense plans untuk bulan tertentu
  Future<void> loadExpensePlansForMonth(
      String userId, int year, int month) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expensePlans =
          await _repository.getExpensePlansByMonth(userId, year, month);
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  // Load expense plans untuk tanggal spesifik
  Future<void> loadExpensePlansForDate(String userId, DateTime date) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expensePlans = await _repository.getExpensePlansByDate(userId, date);
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  // Create expense plan
  Future<bool> createExpensePlan({
    required String userId,
    required String title,
    required double amount,
    required DateTime plannedDate,
    required String plannedTime,
    required String category,
    required String paymentSource,
    String? reminderType,
    int? customReminderMinutes,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _syncWarningMessage = null;
    notifyListeners();

    try {
      final plan = await _repository.createExpensePlan(
        userId: userId,
        title: title,
        amount: amount,
        plannedDate: plannedDate,
        plannedTime: plannedTime,
        category: category,
        paymentSource: paymentSource,
        reminderType: reminderType,
        customReminderMinutes: customReminderMinutes,
        notes: notes,
      );

      final eventId = await _calendarService.syncExpensePlanToCalendar(plan);
      if (eventId == null) {
        _syncWarningMessage =
            'Data tersimpan, tapi sinkronisasi ke kalender perangkat gagal.';
      }

      _expensePlans.add(plan);
      _expensePlans.sort((a, b) => a.plannedDate.compareTo(b.plannedDate));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update expense plan
  Future<bool> updateExpensePlan(
    String id,
    Map<String, dynamic> updates,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    _syncWarningMessage = null;
    notifyListeners();

    try {
      final index = _expensePlans.indexWhere((p) => p.id == id);
      final updated = await _repository.updateExpensePlan(id, updates);

      final eventId = await _calendarService.syncExpensePlanToCalendar(updated);
      if (eventId == null) {
        _syncWarningMessage =
            'Perubahan tersimpan, tapi sinkronisasi ke kalender perangkat gagal.';
      }

      if (index >= 0) {
        _expensePlans[index] = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete expense plan
  Future<bool> deleteExpensePlan(String id) async {
    _isLoading = true;
    _errorMessage = null;
    _syncWarningMessage = null;
    notifyListeners();

    try {
      final hasCalendarPermission = await _calendarService.hasPermission();
      if (hasCalendarPermission) {
        final calendarDeleted =
            await _calendarService.deleteExpensePlanByPlanId(id);
        if (!calendarDeleted) {
          _syncWarningMessage =
              'Rencana terhapus, tapi event kalender perangkat tidak ditemukan.';
        }
      }

      await _repository.deleteExpensePlan(id);

      _expensePlans.removeWhere((p) => p.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mark as completed
  Future<bool> markAsCompleted(String id) async {
    try {
      final updated = await _repository.markAsCompleted(id);
      final index = _expensePlans.indexWhere((p) => p.id == id);
      if (index >= 0) {
        _expensePlans[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // Toggle completion status
  Future<bool> toggleCompleted(String id, bool currentStatus) async {
    try {
      final updated = await _repository.toggleCompleted(id, currentStatus);
      final index = _expensePlans.indexWhere((p) => p.id == id);
      if (index >= 0) {
        _expensePlans[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // Get expense plans untuk tanggal tertentu
  List<ExpensePlan> getExpensePlansForDate(DateTime date) {
    return _expensePlans
        .where((p) =>
            p.plannedDate.year == date.year &&
            p.plannedDate.month == date.month &&
            p.plannedDate.day == date.day)
        .toList();
  }

  // Get dates yang punya expense plans
  List<DateTime> getDatesWithPlans() {
    return _expensePlans
        .map((p) => DateTime(
            p.plannedDate.year, p.plannedDate.month, p.plannedDate.day))
        .toSet()
        .toList();
  }

  // Get total untuk bulan
  Future<double> getTotalForMonth(String userId, int year, int month) async {
    return await _repository.getTotalAmountForMonth(userId, year, month);
  }

  // Get total untuk minggu
  Future<double> getTotalForWeek(String userId, DateTime startDate) async {
    return await _repository.getTotalAmountForWeek(userId, startDate);
  }

  // Get total untuk hari
  Future<double> getTotalForDate(String userId, DateTime date) async {
    return await _repository.getTotalAmountForDate(userId, date);
  }

  // Navigate to next month
  void nextMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    notifyListeners();
  }

  // Navigate to previous month
  void previousMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    notifyListeners();
  }

  // Set current month
  void setMonth(DateTime date) {
    _currentMonth = DateTime(date.year, date.month);
    notifyListeners();
  }
}
