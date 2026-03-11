import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_plan_model.dart';
import '../../core/utils/date_time_utils.dart';

class ExpensePlanRepository {
  final SupabaseClient _client;

  ExpensePlanRepository({required SupabaseClient client}) : _client = client;

  // Get all expense plans untuk user
  Future<List<ExpensePlan>> getAllExpensePlans(String userId) async {
    try {
      final response = await _client
          .from('expense_plans')
          .select()
          .eq('user_id', userId)
          .order('planned_date', ascending: false);

      return (response as List)
          .map((item) => ExpensePlan.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch expense plans: $e');
    }
  }

  // Get expense plans untuk bulan tertentu
  Future<List<ExpensePlan>> getExpensePlansByMonth(
    String userId,
    int year,
    int month,
  ) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final response = await _client
          .from('expense_plans')
          .select()
          .eq('user_id', userId)
          .gte('planned_date', DateTimeUtils.toLocalDateOnlyString(startDate))
          .lte('planned_date', DateTimeUtils.toLocalDateOnlyString(endDate))
          .order('planned_date', ascending: true);

      return (response as List)
          .map((item) => ExpensePlan.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch expense plans for month: $e');
    }
  }

  // Get expense plans untuk tanggal spesifik
  Future<List<ExpensePlan>> getExpensePlansByDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final dateStr = DateTimeUtils.toLocalDateOnlyString(date);
      final response = await _client
          .from('expense_plans')
          .select()
          .eq('user_id', userId)
          .eq('planned_date', dateStr)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => ExpensePlan.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch expense plans for date: $e');
    }
  }

  // Create expense plan
  Future<ExpensePlan> createExpensePlan({
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
    try {
      final response = await _client
          .from('expense_plans')
          .insert({
            'user_id': userId,
            'title': title,
            'amount': amount,
            'planned_date': DateTimeUtils.toLocalDateOnlyString(plannedDate),
            'planned_time': plannedTime,
            'category': category,
            'payment_source': paymentSource,
            'reminder_type': reminderType,
            'custom_reminder_minutes': customReminderMinutes,
            'custom_reminder_hours':
                customReminderMinutes != null ? (customReminderMinutes / 60).ceil() : null,
            'notes': notes,
            'created_at': DateTimeUtils.toUtcIsoString(DateTime.now()),
            'updated_at': DateTimeUtils.toUtcIsoString(DateTime.now()),
          })
          .select()
          .single();

      return ExpensePlan.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create expense plan: $e');
    }
  }

  // Update expense plan
  Future<ExpensePlan> updateExpensePlan(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client
          .from('expense_plans')
          .update({
            ...updates,
            'updated_at': DateTimeUtils.toUtcIsoString(DateTime.now()),
          })
          .eq('id', id)
          .select()
          .single();

      return ExpensePlan.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update expense plan: $e');
    }
  }

  // Delete expense plan
  Future<void> deleteExpensePlan(String id) async {
    try {
      final deleted = await _client
          .from('expense_plans')
          .delete()
          .eq('id', id)
          .select('id')
          .maybeSingle();

      if (deleted == null) {
        throw Exception('Expense plan tidak ditemukan atau tidak punya akses.');
      }
    } catch (e) {
      throw Exception('Failed to delete expense plan: $e');
    }
  }

  // Mark as completed
  Future<ExpensePlan> markAsCompleted(String id) async {
    try {
      final response = await _client
          .from('expense_plans')
          .update({
            'is_completed': true,
            'completed_at': DateTimeUtils.toUtcIsoString(DateTime.now()),
            'updated_at': DateTimeUtils.toUtcIsoString(DateTime.now()),
          })
          .eq('id', id)
          .select()
          .single();

      return ExpensePlan.fromJson(response);
    } catch (e) {
      throw Exception('Failed to mark expense plan as completed: $e');
    }
  }

  // Toggle completion status
  Future<ExpensePlan> toggleCompleted(String id, bool isCompleted) async {
    try {
      final response = await _client
          .from('expense_plans')
          .update({
            'is_completed': !isCompleted,
            'completed_at':
                !isCompleted ? DateTimeUtils.toUtcIsoString(DateTime.now()) : null,
            'updated_at': DateTimeUtils.toUtcIsoString(DateTime.now()),
          })
          .eq('id', id)
          .select()
          .single();

      return ExpensePlan.fromJson(response);
    } catch (e) {
      throw Exception('Failed to toggle expense plan completion: $e');
    }
  }

  // Get summary untuk tanggal tertentu
  Future<double> getTotalAmountForDate(String userId, DateTime date) async {
    try {
      final dateStr = DateTimeUtils.toLocalDateOnlyString(date);
      final response = await _client
          .from('expense_plans')
          .select('amount')
          .eq('user_id', userId)
          .eq('planned_date', dateStr);

      final total = (response as List).fold<double>(
        0,
        (sum, item) => sum + (item['amount'] as num).toDouble(),
      );

      return total;
    } catch (e) {
      return 0;
    }
  }

  // Get total amount untuk minggu tertentu
  Future<double> getTotalAmountForWeek(
      String userId, DateTime startDate) async {
    try {
      final endDate = startDate.add(const Duration(days: 7));
      final startStr = DateTimeUtils.toLocalDateOnlyString(startDate);
      final endStr = DateTimeUtils.toLocalDateOnlyString(endDate);

      final response = await _client
          .from('expense_plans')
          .select('amount')
          .eq('user_id', userId)
          .gte('planned_date', startStr)
          .lt('planned_date', endStr);

      final total = (response as List).fold<double>(
        0,
        (sum, item) => sum + (item['amount'] as num).toDouble(),
      );

      return total;
    } catch (e) {
      return 0;
    }
  }

  // Get total amount untuk bulan tertentu
  Future<double> getTotalAmountForMonth(
    String userId,
    int year,
    int month,
  ) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);
      final startStr = DateTimeUtils.toLocalDateOnlyString(startDate);
      final endStr = DateTimeUtils.toLocalDateOnlyString(endDate);

      final response = await _client
          .from('expense_plans')
          .select('amount')
          .eq('user_id', userId)
          .gte('planned_date', startStr)
          .lte('planned_date', endStr);

      final total = (response as List).fold<double>(
        0,
        (sum, item) => sum + (item['amount'] as num).toDouble(),
      );

      return total;
    } catch (e) {
      return 0;
    }
  }
}
