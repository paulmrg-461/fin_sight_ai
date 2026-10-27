import 'package:equatable/equatable.dart';

import '../../domain/usecases/savings_usecases.dart';

sealed class SavingsEvent extends Equatable {
  const SavingsEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadSavingsGoals extends SavingsEvent {
  const LoadSavingsGoals();
}

final class CreateSavingsGoalEvent extends SavingsEvent {
  const CreateSavingsGoalEvent(this.params);

  final CreateSavingsGoalParams params;

  @override
  List<Object?> get props => [params];
}

final class UpdateSavingsGoalEvent extends SavingsEvent {
  const UpdateSavingsGoalEvent(this.params);

  final UpdateSavingsGoalParams params;

  @override
  List<Object?> get props => [params];
}

final class AddSavingsContributionEvent extends SavingsEvent {
  const AddSavingsContributionEvent(this.params);

  final AddSavingsContributionParams params;

  @override
  List<Object?> get props => [params];
}

final class DeleteSavingsGoalEvent extends SavingsEvent {
  const DeleteSavingsGoalEvent(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
