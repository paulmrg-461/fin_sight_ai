import 'package:equatable/equatable.dart';

/// Base event for budgets.
sealed class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadBudgets extends BudgetEvent {
  const LoadBudgets();
}

/// Selects another budget month and reloads its progress.
final class ChangeBudgetMonth extends BudgetEvent {
  const ChangeBudgetMonth(this.month);

  final DateTime month;

  @override
  List<Object?> get props => [month];
}

final class AddBudget extends BudgetEvent {
  const AddBudget({required this.category, required this.monthlyLimit});

  final String category;
  final double monthlyLimit;

  @override
  List<Object?> get props => [category, monthlyLimit];
}

final class UpdateBudget extends BudgetEvent {
  const UpdateBudget({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.month,
  });

  final String id;
  final String category;
  final double monthlyLimit;
  final DateTime month;

  @override
  List<Object?> get props => [id, category, monthlyLimit, month];
}

final class DeleteBudget extends BudgetEvent {
  const DeleteBudget(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
