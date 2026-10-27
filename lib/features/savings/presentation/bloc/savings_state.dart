import 'package:equatable/equatable.dart';

import '../../domain/entities/savings_goal_entity.dart';

sealed class SavingsState extends Equatable {
  const SavingsState();

  @override
  List<Object?> get props => const [];
}

final class SavingsInitial extends SavingsState {
  const SavingsInitial();
}

final class SavingsLoading extends SavingsState {
  const SavingsLoading();
}

final class SavingsLoaded extends SavingsState {
  const SavingsLoaded(this.goals);

  final List<SavingsGoalEntity> goals;

  @override
  List<Object?> get props => [goals];
}

final class SavingsEmpty extends SavingsState {
  const SavingsEmpty();
}

final class SavingsFailure extends SavingsState {
  const SavingsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
