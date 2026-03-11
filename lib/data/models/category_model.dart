import '../../core/utils/date_time_utils.dart';

enum CategoryType { income, expense }

class CategoryModel {
  final String id;
  final String? userId;
  final String name;
  final String icon;
  final String color;
  final CategoryType type;
  final bool isDefault;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      type: json['type'] == 'income' ? CategoryType.income : CategoryType.expense,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type == CategoryType.income ? 'income' : 'expense',
      'is_default': isDefault,
      'created_at': DateTimeUtils.toUtcIsoString(createdAt),
    };
  }
}
