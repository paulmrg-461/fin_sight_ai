import 'package:equatable/equatable.dart';

import '../../domain/entities/budget_entity.dart';

/// Base state for budgets.
sealed class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object?> get props => const [];
}

final class BudgetInitial extends BudgetState {
  const BudgetInitial();
}

final class BudgetLoading extends BudgetState {
  const BudgetLoading();
}

final class BudgetLoaded extends BudgetState {
  const BudgetLoaded({
    required this.progress,
    required this.categories,
    this.month,
  });

  final List<BudgetProgress> progress;
  final List<String> categories;

  /// Selected month, or `null` when a test emits a state directly.
  final DateTime? month;

  @override
  List<Object?> get props => [progress, categories, month];
}

final class BudgetEmpty extends BudgetState {
  const BudgetEmpty({
    required this.categories,
    this.month,
    this.previousBudgetCount = 0,
  });

  final List<String> categories;

  /// Selected month, or `null` when a test emits a state directly.
  final DateTime? month;

  /// Limits available in the previous month, used by "Copy previous month".
  final int previousBudgetCount;

  @override
  List<Object?> get props => [categories, month, previousBudgetCount];
}

final class BudgetFailure extends BudgetState {
  const BudgetFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
