import '../../core/utils/date_time_utils.dart';

enum ItemType { income, expense }

class BudgetItemModel {
  final String id;
  final String budgetId;
  final String? categoryId;
  final String userId;
  final ItemType type;
  final double amount;
  final String? description;
  final DateTime date;
  final DateTime createdAt;

  const BudgetItemModel({
    required this.id,
    required this.budgetId,
    this.categoryId,
    required this.userId,
    required this.type,
    required this.amount,
    this.description,
    required this.date,
    required this.createdAt,
  });

  factory BudgetItemModel.fromJson(Map<String, dynamic> json) {
    return BudgetItemModel(
      id: json['id'] as String,
      budgetId: json['budget_id'] as String,
      categoryId: json['category_id'] as String?,
      userId: json['user_id'] as String,
      type: json['type'] == 'income' ? ItemType.income : ItemType.expense,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'budget_id': budgetId,
      'category_id': categoryId,
      'user_id': userId,
      'type': type == ItemType.income ? 'income' : 'expense',
      'amount': amount,
      'description': description,
      'date': DateTimeUtils.toLocalDateOnlyString(date),
      'created_at': DateTimeUtils.toUtcIsoString(createdAt),
    };
  }
}
