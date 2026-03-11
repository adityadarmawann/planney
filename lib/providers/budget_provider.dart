import 'package:flutter/foundation.dart';
import '../data/models/budget_model.dart';
import '../data/models/budget_item_model.dart';
import '../data/models/category_model.dart';
import '../data/repositories/budget_repository.dart';
import '../core/errors/app_exception.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetRepository _budgetRepository;

  List<BudgetModel> _budgets = [];
  List<BudgetItemModel> _budgetItems = [];
  List<CategoryModel> _categories = [];
  BudgetModel? _selectedBudget;
  bool _isLoading = false;
  String? _errorMessage;

  BudgetProvider({required BudgetRepository budgetRepository})
      : _budgetRepository = budgetRepository;

  List<BudgetModel> get budgets => _budgets;
  List<BudgetItemModel> get budgetItems => _budgetItems;
  List<CategoryModel> get categories => _categories;
  BudgetModel? get selectedBudget => _selectedBudget;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<CategoryModel> get incomeCategories =>
      _categories.where((c) => c.type == CategoryType.income).toList();

  List<CategoryModel> get expenseCategories =>
      _categories.where((c) => c.type == CategoryType.expense).toList();

  Future<void> loadBudgets(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _budgets = await _budgetRepository.getBudgets(userId);
    } on AppException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBudgetItems(String budgetId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _budgetItems = await _budgetRepository.getBudgetItems(budgetId);
      _selectedBudget = await _budgetRepository.getBudgetById(budgetId);
    } on AppException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories({String? userId}) async {
    try {
      _categories = await _budgetRepository.getCategories(userId: userId);
      notifyListeners();
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<BudgetModel?> createBudget({
    required String userId,
    required String name,
    required PeriodType periodType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final budget = await _budgetRepository.createBudget(
        userId: userId,
        name: name,
        periodType: periodType,
        startDate: startDate,
        endDate: endDate,
      );
      _budgets.insert(0, budget);
      return budget;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBudgetItem({
    required String budgetId,
    required String userId,
    String? categoryId,
    required ItemType type,
    required double amount,
    String? description,
    required DateTime date,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final item = await _budgetRepository.addBudgetItem(
        budgetId: budgetId,
        userId: userId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        description: description,
        date: date,
      );
      _budgetItems.insert(0, item);

      // Refresh budget totals
      _selectedBudget = await _budgetRepository.getBudgetById(budgetId);

      // Update in list
      final idx = _budgets.indexWhere((b) => b.id == budgetId);
      if (idx != -1 && _selectedBudget != null) {
        _budgets[idx] = _selectedBudget!;
      }
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBudgetItem(String id, String budgetId) async {
    _errorMessage = null;

    try {
      await _budgetRepository.deleteBudgetItem(id, budgetId);
      _budgetItems.removeWhere((item) => item.id == id);

      // Refresh budget totals
      _selectedBudget = await _budgetRepository.getBudgetById(budgetId);
      final idx = _budgets.indexWhere((b) => b.id == budgetId);
      if (idx != -1 && _selectedBudget != null) {
        _budgets[idx] = _selectedBudget!;
      }
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBudget(String id) async {
    _errorMessage = null;

    try {
      await _budgetRepository.deleteBudget(id);
      _budgets.removeWhere((b) => b.id == id);
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  void selectBudget(BudgetModel budget) {
    _selectedBudget = budget;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
