import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/budget_model.dart';
import '../models/budget_item_model.dart';
import '../models/category_model.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/date_time_utils.dart';

class BudgetRepository {
  final SupabaseClient _client;

  BudgetRepository({required SupabaseClient client}) : _client = client;

  Future<List<BudgetModel>> getBudgets(String userId) async {
    try {
      final data = await _client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .order('start_date', ascending: false);
      return (data as List).map((e) => BudgetModel.fromJson(e)).toList();
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<BudgetModel?> getBudgetById(String id) async {
    try {
      final data = await _client
          .from('budgets')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return BudgetModel.fromJson(data);
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<BudgetModel> createBudget({
    required String userId,
    required String name,
    required PeriodType periodType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final periodTypeStr = periodType == PeriodType.weekly
          ? 'weekly'
          : periodType == PeriodType.monthly
              ? 'monthly'
              : 'custom';

      final data = await _client.from('budgets').insert({
        'user_id': userId,
        'name': name,
        'period_type': periodTypeStr,
        'start_date': DateTimeUtils.toLocalDateOnlyString(startDate),
        'end_date': DateTimeUtils.toLocalDateOnlyString(endDate),
        'total_income': 0,
        'total_expense': 0,
      }).select().single();
      return BudgetModel.fromJson(data);
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _client.from('budgets').delete().eq('id', id);
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<List<BudgetItemModel>> getBudgetItems(String budgetId) async {
    try {
      final data = await _client
          .from('budget_items')
          .select()
          .eq('budget_id', budgetId)
          .order('date', ascending: false);
      return (data as List).map((e) => BudgetItemModel.fromJson(e)).toList();
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<BudgetItemModel> addBudgetItem({
    required String budgetId,
    required String userId,
    String? categoryId,
    required ItemType type,
    required double amount,
    String? description,
    required DateTime date,
  }) async {
    try {
      final itemData = await _client.from('budget_items').insert({
        'budget_id': budgetId,
        'user_id': userId,
        'category_id': categoryId,
        'type': type == ItemType.income ? 'income' : 'expense',
        'amount': amount,
        'description': description,
        'date': DateTimeUtils.toLocalDateOnlyString(date),
      }).select().single();

      // Update budget totals
      final budget = await getBudgetById(budgetId);
      if (budget != null) {
        final updates = <String, dynamic>{};
        if (type == ItemType.income) {
          updates['total_income'] = budget.totalIncome + amount;
        } else {
          updates['total_expense'] = budget.totalExpense + amount;
        }
        await _client.from('budgets').update(updates).eq('id', budgetId);
      }

      return BudgetItemModel.fromJson(itemData);
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<void> deleteBudgetItem(String id, String budgetId) async {
    try {
      final itemData = await _client
          .from('budget_items')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (itemData == null) return;

      final item = BudgetItemModel.fromJson(itemData);
      await _client.from('budget_items').delete().eq('id', id);

      // Update budget totals
      final budget = await getBudgetById(budgetId);
      if (budget != null) {
        final updates = <String, dynamic>{};
        if (item.type == ItemType.income) {
          updates['total_income'] =
              (budget.totalIncome - item.amount).clamp(0, double.infinity);
        } else {
          updates['total_expense'] =
              (budget.totalExpense - item.amount).clamp(0, double.infinity);
        }
        await _client.from('budgets').update(updates).eq('id', budgetId);
      }
    } catch (e) {
      throw AppException.fromError(e);
    }
  }

  Future<List<CategoryModel>> getCategories({String? userId}) async {
    try {
      var query = _client.from('categories').select();
      if (userId != null) {
        query = query.or('user_id.is.null,user_id.eq.$userId');
      } else {
        query = query.filter('user_id', 'is', null);
      }
      final data = await query.order('name');
      return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
    } catch (e) {
      throw AppException.fromError(e);
    }
  }
}
