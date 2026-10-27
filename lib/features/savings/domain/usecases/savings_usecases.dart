import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/clock.dart';
import '../entities/savings_goal_entity.dart';
import '../repositories/savings_repository.dart';

class CreateSavingsGoalParams {
  const CreateSavingsGoalParams({
    required this.name,
    required this.targetAmount,
    this.targetDate,
  });

  final String name;
  final double targetAmount;
  final DateTime? targetDate;
}

@lazySingleton
class GetSavingsGoalsUseCase
    implements UseCase<List<SavingsGoalEntity>, NoParams> {
  const GetSavingsGoalsUseCase(this._repository);

  final SavingsRepository _repository;

  @override
  ResultFuture<List<SavingsGoalEntity>> call(NoParams params) =>
      _repository.getGoals();
}

@lazySingleton
class CreateSavingsGoalUseCase
    implements UseCase<SavingsGoalEntity, CreateSavingsGoalParams> {
  CreateSavingsGoalUseCase(
    this._repository, {
    this.uuid = const Uuid(),
    this.clock = const Clock(),
  });

  final SavingsRepository _repository;
  final Uuid uuid;
  final Clock clock;

  @override
  Future<Result<SavingsGoalEntity>> call(CreateSavingsGoalParams params) async {
    final name = params.name.trim();
    if (name.isEmpty) {
      return const Left(
        ValidationFailure('Goal name is required.', code: 'missing_goal_name'),
      );
    }
    if (name.length > 120) {
      return const Left(
        ValidationFailure(
          'Goal name must be 120 characters or fewer.',
          code: 'goal_name_too_long',
        ),
      );
    }
    if (!params.targetAmount.isFinite || params.targetAmount <= 0) {
      return const Left(
        ValidationFailure(
          'Target amount must be greater than zero.',
          code: 'invalid_target',
        ),
      );
    }
    final now = clock.now();
    return _repository.addGoal(
      SavingsGoalEntity(
        id: uuid.v4(),
        name: name,
        targetAmount: double.parse(params.targetAmount.toStringAsFixed(2)),
        createdAt: now,
        targetDate: params.targetDate,
      ),
    );
  }
}

class UpdateSavingsGoalParams {
  const UpdateSavingsGoalParams({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.targetDate,
  });

  final String id;
  final String name;
  final double targetAmount;
  final DateTime? targetDate;
}

@lazySingleton
class UpdateSavingsGoalUseCase
    implements UseCase<SavingsGoalEntity, UpdateSavingsGoalParams> {
  const UpdateSavingsGoalUseCase(this._repository);

  final SavingsRepository _repository;

  @override
  Future<Result<SavingsGoalEntity>> call(UpdateSavingsGoalParams params) async {
    final id = params.id.trim();
    if (id.isEmpty) {
      return const Left(
        ValidationFailure('Goal id is required.', code: 'missing_goal_id'),
      );
    }
    final name = params.name.trim();
    if (name.isEmpty) {
      return const Left(
        ValidationFailure('Goal name is required.', code: 'missing_goal_name'),
      );
    }
    if (name.length > 120) {
      return const Left(
        ValidationFailure(
          'Goal name must be 120 characters or fewer.',
          code: 'goal_name_too_long',
        ),
      );
    }
    if (!params.targetAmount.isFinite || params.targetAmount <= 0) {
      return const Left(
        ValidationFailure(
          'Target amount must be greater than zero.',
          code: 'invalid_target',
        ),
      );
    }
    return _repository.updateGoal(
      SavingsGoalEntity(
        id: id,
        name: name,
        targetAmount: double.parse(params.targetAmount.toStringAsFixed(2)),
        createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        targetDate: params.targetDate,
      ),
    );
  }
}

class AddSavingsContributionParams {
  const AddSavingsContributionParams({
    required this.goalId,
    required this.amount,
    this.date,
  });

  final String goalId;
  final double amount;
  final DateTime? date;
}

@lazySingleton
class AddSavingsContributionUseCase
    implements UseCase<SavingsGoalEntity, AddSavingsContributionParams> {
  AddSavingsContributionUseCase(
    this._repository, {
    this.uuid = const Uuid(),
    this.clock = const Clock(),
  });

  final SavingsRepository _repository;
  final Uuid uuid;
  final Clock clock;

  @override
  Future<Result<SavingsGoalEntity>> call(
    AddSavingsContributionParams params,
  ) async {
    if (params.goalId.trim().isEmpty) {
      return const Left(
        ValidationFailure('Goal id is required.', code: 'missing_goal_id'),
      );
    }
    if (!params.amount.isFinite || params.amount <= 0) {
      return const Left(
        ValidationFailure(
          'Contribution must be greater than zero.',
          code: 'invalid_contribution',
        ),
      );
    }
    return _repository.addContribution(
      params.goalId,
      SavingsContribution(
        id: uuid.v4(),
        amount: double.parse(params.amount.toStringAsFixed(2)),
        date: params.date ?? clock.now(),
      ),
    );
  }
}

@lazySingleton
class DeleteSavingsGoalUseCase implements UseCase<void, String> {
  const DeleteSavingsGoalUseCase(this._repository);

  final SavingsRepository _repository;

  @override
  Future<Result<void>> call(String id) {
    if (id.trim().isEmpty) {
      return Future.value(
        const Left(
          ValidationFailure('Goal id is required.', code: 'missing_goal_id'),
        ),
      );
    }
    return _repository.deleteGoal(id);
  }
}
