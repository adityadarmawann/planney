import '../../core/utils/date_time_utils.dart';

enum PeriodType { weekly, monthly, custom }

class BudgetModel {
  final String id;
  final String userId;
  final String name;
  final PeriodType periodType;
  final DateTime startDate;
  final DateTime endDate;
  final double totalIncome;
  final double totalExpense;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    this.totalIncome = 0,
    this.totalExpense = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remaining => totalIncome - totalExpense;

  double get percentageUsed =>
      totalIncome > 0 ? (totalExpense / totalIncome * 100).clamp(0, 100) : 0;

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      periodType: _parsePeriodType(json['period_type'] as String),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      totalIncome: (json['total_income'] as num? ?? 0).toDouble(),
      totalExpense: (json['total_expense'] as num? ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static PeriodType _parsePeriodType(String value) {
    switch (value) {
      case 'weekly':
        return PeriodType.weekly;
      case 'monthly':
        return PeriodType.monthly;
      default:
        return PeriodType.custom;
    }
  }

  String get periodTypeLabel {
    switch (periodType) {
      case PeriodType.weekly:
        return 'Mingguan';
      case PeriodType.monthly:
        return 'Bulanan';
      case PeriodType.custom:
        return 'Kustom';
    }
  }

  String get periodTypeString {
    switch (periodType) {
      case PeriodType.weekly:
        return 'weekly';
      case PeriodType.monthly:
        return 'monthly';
      case PeriodType.custom:
        return 'custom';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'period_type': periodTypeString,
      'start_date': DateTimeUtils.toLocalDateOnlyString(startDate),
      'end_date': DateTimeUtils.toLocalDateOnlyString(endDate),
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'created_at': DateTimeUtils.toUtcIsoString(createdAt),
      'updated_at': DateTimeUtils.toUtcIsoString(updatedAt),
    };
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? name,
    PeriodType? periodType,
    DateTime? startDate,
    DateTime? endDate,
    double? totalIncome,
    double? totalExpense,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      periodType: periodType ?? this.periodType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
