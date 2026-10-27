import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/repositories/savings_repository.dart';
import '../datasources/savings_local_data_source.dart';
import '../models/savings_goal_model.dart';

@LazySingleton(as: SavingsRepository)
class SavingsRepositoryImpl implements SavingsRepository {
  const SavingsRepositoryImpl(this._localDataSource);

  final SavingsLocalDataSource _localDataSource;

  @override
  ResultFuture<List<SavingsGoalEntity>> getGoals() async {
    try {
      final goals = await _localDataSource.getGoals();
      return Right(
        List<SavingsGoalEntity>.unmodifiable(
          goals.map((goal) => goal.toEntity()),
        ),
      );
    } on CacheException catch (exception) {
      return Left(CacheFailure(exception.message, code: exception.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to read savings goals.',
          code: 'savings_read_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<SavingsGoalEntity> addGoal(SavingsGoalEntity goal) async {
    try {
      final model = SavingsGoalModel.fromEntity(goal);
      await _localDataSource.saveGoal(model);
      return Right(model.toEntity());
    } on CacheException catch (exception) {
      return Left(CacheFailure(exception.message, code: exception.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to save the savings goal.',
          code: 'savings_write_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<SavingsGoalEntity> addContribution(
    String goalId,
    SavingsContribution contribution,
  ) async {
    try {
      final goals = await _localDataSource.getGoals();
      SavingsGoalModel? existing;
      for (final goal in goals) {
        if (goal.id == goalId) {
          existing = goal;
          break;
        }
      }
      if (existing == null) {
        return const Left(
          ValidationFailure(
            'Savings goal not found.',
            code: 'savings_not_found',
          ),
        );
      }
      final updated = SavingsGoalModel.fromEntity(
        existing.copyWith(
          contributions: [...existing.contributions, contribution],
        ),
      );
      await _localDataSource.saveGoal(updated);
      return Right(updated.toEntity());
    } on CacheException catch (exception) {
      return Left(CacheFailure(exception.message, code: exception.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to add the contribution.',
          code: 'savings_write_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<void> deleteGoal(String id) async {
    try {
      await _localDataSource.deleteGoal(id);
      return const Right(null);
    } on CacheException catch (exception) {
      return Left(CacheFailure(exception.message, code: exception.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to delete the savings goal.',
          code: 'savings_delete_failed',
        ),
      );
    }
  }
}
