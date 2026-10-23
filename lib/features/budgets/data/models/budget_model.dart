import '../../domain/entities/budget_entity.dart';

/// JSON representation of [BudgetEntity].
class BudgetModel extends BudgetEntity {
  const BudgetModel({
    required super.id,
    required super.category,
    required super.monthlyLimit,
    required super.month,
    super.updatedAt,
  });

  factory BudgetModel.fromEntity(BudgetEntity budget) {
    return BudgetModel(
      id: budget.id,
      category: budget.category,
      monthlyLimit: budget.monthlyLimit,
      month: budget.month,
      updatedAt: budget.updatedAt,
    );
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final category = json['category'];
    final monthlyLimit = json['monthlyLimit'];
    final month = json['month'];
    final updatedAt = json['updatedAt'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Budget id is missing.');
    }
    if (category is! String) {
      throw const FormatException('Budget category is missing.');
    }
    if (monthlyLimit is! num) {
      throw const FormatException('Budget limit is missing.');
    }
    if (month is! String) {
      throw const FormatException('Budget month is missing.');
    }

    return BudgetModel(
      id: id,
      category: category,
      monthlyLimit: monthlyLimit.toDouble(),
      month: DateTime.parse(month),
      updatedAt: updatedAt is String ? DateTime.tryParse(updatedAt) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'category': category,
      'monthlyLimit': monthlyLimit,
      'month': month.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
    };
  }

  BudgetEntity toEntity() {
    return BudgetEntity(
      id: id,
      category: category,
      monthlyLimit: monthlyLimit,
      month: month,
      updatedAt: updatedAt,
    );
  }
}
