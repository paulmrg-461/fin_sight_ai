import '../../../../core/domain/entity.dart';

/// Monthly spending limit for a category.
class BudgetEntity extends Entity {
  const BudgetEntity({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.month,
    this.updatedAt,
    this.isSynced = false,
    this.deletedAt,
  });

  @override
  final String id;

  final String category;
  final double monthlyLimit;

  /// Normalized to the first day of the month at midnight (local time).
  final DateTime month;
  final DateTime? updatedAt;

  /// Whether the remote backend already accepted this record.
  final bool isSynced;

  /// Soft-delete tombstone. Hidden from queries but kept for synchronization.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  DateTime get lastModified => updatedAt ?? month;

  BudgetEntity copyWith({
    String? id,
    String? category,
    double? monthlyLimit,
    DateTime? month,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
  }) {
    return BudgetEntity(
      id: id ?? this.id,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      month: month ?? this.month,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetEntity &&
          other.id == id &&
          other.category == category &&
          other.monthlyLimit == monthlyLimit &&
          other.month == month &&
          other.updatedAt == updatedAt &&
          other.isSynced == isSynced &&
          other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(id, category, monthlyLimit, month, updatedAt);

  @override
  String toString() => 'BudgetEntity($category: $monthlyLimit, month: $month)';
}

/// Budget plus the spending aggregated from transactions.
class BudgetProgress {
  const BudgetProgress({required this.budget, required this.spent});

  final BudgetEntity budget;
  final double spent;

  double get remaining => budget.monthlyLimit - spent;

  bool get isOverBudget => spent > budget.monthlyLimit;

  double get percentage {
    if (budget.monthlyLimit <= 0) {
      return 0;
    }
    return (spent / budget.monthlyLimit).clamp(0, 1).toDouble();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetProgress && other.budget == budget && other.spent == spent;

  @override
  int get hashCode => Object.hash(budget, spent);

  @override
  String toString() => 'BudgetProgress(${budget.category}, spent: $spent)';
}
