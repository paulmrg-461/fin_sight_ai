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

final class AddBudget extends BudgetEvent {
  const AddBudget({required this.category, required this.monthlyLimit});

  final String category;
  final double monthlyLimit;

  @override
  List<Object?> get props => [category, monthlyLimit];
}

final class DeleteBudget extends BudgetEvent {
  const DeleteBudget(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
