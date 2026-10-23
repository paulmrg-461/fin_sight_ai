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
  const BudgetLoaded({required this.progress, required this.categories});

  final List<BudgetProgress> progress;
  final List<String> categories;

  @override
  List<Object?> get props => [progress, categories];
}

final class BudgetEmpty extends BudgetState {
  const BudgetEmpty({required this.categories});

  final List<String> categories;

  @override
  List<Object?> get props => [categories];
}

final class BudgetFailure extends BudgetState {
  const BudgetFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
