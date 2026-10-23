import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/sync/sync_operation.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../../domain/services/debt_payoff_calculator.dart';
import '../datasources/debt_local_data_source.dart';
import '../models/debt_model.dart';

/// Local-first implementation of [DebtRepository].
@LazySingleton(as: DebtRepository)
class DebtRepositoryImpl implements DebtRepository {
  const DebtRepositoryImpl(
    this._localDataSource, {
    this.syncQueue,
    this.clock = const Clock(),
  });

  final DebtLocalDataSource _localDataSource;
  final SyncQueue? syncQueue;
  final Clock clock;

  @override
  ResultFuture<DebtEntity> addDebt(DebtEntity debt) =>
      _save(debt, failureCode: 'cache_write_failed');

  @override
  ResultFuture<DebtEntity> updateDebt(DebtEntity debt) =>
      _save(debt, failureCode: 'cache_write_failed');

  @override
  ResultFuture<void> deleteDebt(String id) async {
    try {
      final models = await _localDataSource.getDebts();
      DebtModel? existing;
      for (final model in models) {
        if (model.id == id) {
          existing = model;
          break;
        }
      }
      if (existing == null) {
        return const Right(null);
      }

      final now = clock.now();
      final tombstone = DebtModel.fromEntity(
        existing.copyWith(updatedAt: now, isSynced: false, deletedAt: now),
      );
      await _localDataSource.saveDebt(tombstone);
      await _enqueue(
        SyncOperation.upsert(
          entityType: SyncEntityType.debt,
          entityId: tombstone.id,
          payload: tombstone.toJson(),
          queuedAt: now,
        ),
      );
      return const Right(null);
    } on CacheException catch (exception) {
      return Left(_toCacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to delete the debt locally.',
          code: 'cache_delete_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<List<DebtEntity>> getDebts() async {
    try {
      final models = await _localDataSource.getDebts();
      return Right(
        List<DebtEntity>.unmodifiable(models.map((model) => model.toEntity())),
      );
    } on CacheException catch (exception) {
      return Left(_toCacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure('Unable to read local debts.', code: 'cache_read_failed'),
      );
    }
  }

  @override
  ResultFuture<DateTime?> calculatePayoffDate(
    DebtEntity debt, {
    double? monthlyPayment,
  }) async {
    return Right(
      DebtPayoffCalculator.calculatePayoffDate(
        remainingAmount: debt.remainingAmount,
        annualInterestRate: debt.interestRate,
        monthlyPayment: monthlyPayment ?? debt.minimumPayment,
        from: DateTime.now(),
      ),
    );
  }

  Future<Result<DebtEntity>> _save(
    DebtEntity debt, {
    required String failureCode,
  }) async {
    try {
      final pending = debt.copyWith(updatedAt: clock.now(), isSynced: false);
      final model = DebtModel.fromEntity(pending);
      await _localDataSource.saveDebt(model);
      await _enqueue(
        SyncOperation.upsert(
          entityType: SyncEntityType.debt,
          entityId: model.id,
          payload: model.toJson(),
          queuedAt: clock.now(),
        ),
      );
      return Right(model.toEntity());
    } on CacheException catch (exception) {
      return Left(_toCacheFailure(exception));
    } catch (_) {
      return Left(
        CacheFailure('Unable to save the debt locally.', code: failureCode),
      );
    }
  }

  CacheFailure _toCacheFailure(CacheException exception) =>
      CacheFailure(exception.message, code: exception.code);

  Future<void> _enqueue(SyncOperation operation) async {
    final queue = syncQueue;
    if (queue == null) {
      return;
    }
    try {
      await queue.enqueue(operation);
    } catch (_) {
      // The local write is authoritative; a queue failure must not lose it.
    }
  }
}
