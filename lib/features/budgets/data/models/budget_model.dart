import '../../../../core/utils/calendar_date.dart';
import '../../domain/entities/budget_entity.dart';

/// JSON representation of [BudgetEntity].
class BudgetModel extends BudgetEntity {
  const BudgetModel({
    required super.id,
    required super.category,
    required super.monthlyLimit,
    required super.month,
    super.updatedAt,
    super.isSynced,
    super.deletedAt,
  });

  factory BudgetModel.fromEntity(BudgetEntity budget) {
    return BudgetModel(
      id: budget.id,
      category: budget.category,
      monthlyLimit: budget.monthlyLimit,
      month: budget.month,
      updatedAt: budget.updatedAt,
      isSynced: budget.isSynced,
      deletedAt: budget.deletedAt,
    );
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final category = json['category'];
    final monthlyLimit = json['monthlyLimit'];
    final month = json['month'];
    final updatedAt = json['updatedAt'];
    final isSynced = json['isSynced'];
    final deletedAt = json['deletedAt'];

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

    final parsedMonth = DateTime.parse(month);

    return BudgetModel(
      id: id,
      category: category,
      monthlyLimit: monthlyLimit.toDouble(),
      // Rows written before the UTC-noon convention stored a local month
      // converted to UTC, so recover the local parts before normalizing.
      month: isCalendarDate(parsedMonth)
          ? parsedMonth
          : calendarMonth(parsedMonth.toLocal()),
      updatedAt: updatedAt is String ? DateTime.tryParse(updatedAt) : null,
      isSynced: isSynced is bool ? isSynced : false,
      deletedAt: deletedAt is String ? DateTime.tryParse(deletedAt) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'category': category,
      'monthlyLimit': monthlyLimit,
      'month': calendarMonth(month).toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
      'isSynced': isSynced,
      'deletedAt': deletedAt?.toUtc().toIso8601String(),
    };
  }

  BudgetEntity toEntity() {
    return BudgetEntity(
      id: id,
      category: category,
      monthlyLimit: monthlyLimit,
      month: month,
      updatedAt: updatedAt,
      isSynced: isSynced,
      deletedAt: deletedAt,
    );
  }
}
