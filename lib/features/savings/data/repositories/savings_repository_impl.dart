import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/sync/sync_operation.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/repositories/savings_repository.dart';
import '../datasources/savings_local_data_source.dart';
import '../models/savings_goal_model.dart';

@LazySingleton(as: SavingsRepository)
class SavingsRepositoryImpl implements SavingsRepository {
  SavingsRepositoryImpl(
    this._localDataSource, {
    this.syncQueue,
    this.clock = const Clock(),
  });

  final SavingsLocalDataSource _localDataSource;
  final SyncQueue? syncQueue;
  final Clock clock;

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
      final now = clock.now();
      final model = SavingsGoalModel.fromEntity(
        goal.copyWith(updatedAt: now, isSynced: false),
      );
      await _localDataSource.saveGoal(model);
      await _enqueue(model);
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
  @override
  ResultFuture<SavingsGoalEntity> updateGoal(SavingsGoalEntity goal) async {
    try {
      final goals = await _localDataSource.getGoals();
      SavingsGoalModel? existing;
      for (final item in goals) {
        if (item.id == goal.id) {
          existing = item;
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
      final now = clock.now();
      final updated = SavingsGoalModel.fromEntity(
        existing.copyWith(
          name: goal.name,
          targetAmount: goal.targetAmount,
          targetDate: goal.targetDate,
          updatedAt: now,
          isSynced: false,
        ),
      );
      await _localDataSource.saveGoal(updated);
      await _enqueue(updated);
      return Right(updated.toEntity());
    } on CacheException catch (exception) {
      return Left(CacheFailure(exception.message, code: exception.code));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to update the savings goal.',
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
      final now = clock.now();
      final updated = SavingsGoalModel.fromEntity(
        existing.copyWith(
          contributions: [...existing.contributions, contribution],
          updatedAt: now,
          isSynced: false,
        ),
      );
      await _localDataSource.saveGoal(updated);
      await _enqueue(updated);
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

  Future<void> _enqueue(SavingsGoalModel model) async {
    final queue = syncQueue;
    if (queue == null) {
      return;
    }
    try {
      await queue.enqueue(
        SyncOperation.upsert(
          entityType: SyncEntityType.savingsGoal,
          entityId: model.id,
          payload: model.toJson(),
          queuedAt: clock.now(),
        ),
      );
    } catch (_) {
      // The local write is authoritative; a queue failure must not lose it.
    }
  }

  @override
  ResultFuture<void> deleteGoal(String id) async {
    try {
      final goals = await _localDataSource.getGoals();
      SavingsGoalModel? existing;
      for (final goal in goals) {
        if (goal.id == id) {
          existing = goal;
          break;
        }
      }
      if (existing == null) {
        return const Right(null);
      }
      final now = clock.now();
      final tombstone = SavingsGoalModel.fromEntity(
        existing.copyWith(updatedAt: now, isSynced: false, deletedAt: now),
      );
      await _localDataSource.saveGoal(tombstone);
      await _enqueue(tombstone);
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
