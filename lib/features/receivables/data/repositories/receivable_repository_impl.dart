import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/sync/sync_operation.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/receivable_entity.dart';
import '../../domain/repositories/receivable_repository.dart';
import '../datasources/receivable_local_data_source.dart';
import '../models/receivable_model.dart';

/// Local-only implementation of [ReceivableRepository].
@LazySingleton(as: ReceivableRepository)
class ReceivableRepositoryImpl implements ReceivableRepository {
  const ReceivableRepositoryImpl(
    this._localDataSource, {
    this.syncQueue,
    this.clock = const Clock(),
  });

  final ReceivableLocalDataSource _localDataSource;
  final SyncQueue? syncQueue;
  final Clock clock;

  @override
  ResultFuture<ReceivableEntity> addReceivable(ReceivableEntity receivable) =>
      _save(receivable, failureCode: 'cache_write_failed');

  @override
  ResultFuture<ReceivableEntity> updateReceivable(
    ReceivableEntity receivable,
  ) => _save(receivable, failureCode: 'cache_write_failed');

  @override
  ResultFuture<ReceivableEntity> makePayment(
    String receivableId,
    ReceivablePayment payment,
  ) async {
    if (!payment.amount.isFinite || payment.amount <= 0) {
      return const Left(
        ValidationFailure(
          'Payment amount must be greater than zero.',
          code: 'invalid_payment',
        ),
      );
    }

    try {
      final models = await _localDataSource.getReceivables();
      ReceivableModel? existing;
      for (final model in models) {
        if (model.id == receivableId) {
          existing = model;
          break;
        }
      }
      if (existing == null) {
        return const Left(
          ValidationFailure(
            'Receivable not found.',
            code: 'receivable_not_found',
          ),
        );
      }
      if (existing.isPaid) {
        return const Left(
          ValidationFailure(
            'This receivable is already paid.',
            code: 'receivable_already_paid',
          ),
        );
      }

      final applied = payment.amount > existing.remainingAmount
          ? existing.remainingAmount
          : payment.amount;
      final roundedApplied = double.parse(applied.toStringAsFixed(2));
      final newRemaining = double.parse(
        (existing.remainingAmount - applied).toStringAsFixed(2),
      );
      final settled = newRemaining <= 0.004;

      final updated = existing.copyWith(
        remainingAmount: settled ? 0 : newRemaining,
        status: settled ? ReceivableStatus.paid : ReceivableStatus.active,
        paymentHistory: [
          ...existing.paymentHistory,
          payment.copyWith(amount: roundedApplied),
        ],
        updatedAt: clock.now(),
        isSynced: false,
      );

      final model = ReceivableModel.fromEntity(updated);
      await _localDataSource.saveReceivable(model);
      await _enqueue(model);
      return Right(model.toEntity());
    } on CacheException catch (exception) {
      return Left(_toCacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to record the receivable payment.',
          code: 'cache_write_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<List<ReceivableEntity>> getReceivables() async {
    try {
      final models = await _localDataSource.getReceivables();
      return Right(
        List<ReceivableEntity>.unmodifiable(
          models
              .where((model) => !model.isDeleted)
              .map((model) => model.toEntity()),
        ),
      );
    } on CacheException catch (exception) {
      return Left(_toCacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to read local receivables.',
          code: 'cache_read_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<void> deleteReceivable(String id) async {
    try {
      final models = await _localDataSource.getReceivables();
      ReceivableModel? existing;
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
      final tombstone = ReceivableModel.fromEntity(
        existing.copyWith(updatedAt: now, isSynced: false, deletedAt: now),
      );
      await _localDataSource.saveReceivable(tombstone);
      await _enqueue(tombstone);
      return const Right(null);
    } on CacheException catch (exception) {
      return Left(_toCacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to delete the receivable locally.',
          code: 'cache_delete_failed',
        ),
      );
    }
  }

  Future<Result<ReceivableEntity>> _save(
    ReceivableEntity receivable, {
    required String failureCode,
  }) async {
    try {
      final pending = receivable.copyWith(updatedAt: clock.now());
      final model = ReceivableModel.fromEntity(pending);
      await _localDataSource.saveReceivable(model);
      await _enqueue(model);
      return Right(model.toEntity());
    } on CacheException catch (exception) {
      return Left(_toCacheFailure(exception));
    } catch (_) {
      return Left(
        CacheFailure(
          'Unable to save the receivable locally.',
          code: failureCode,
        ),
      );
    }
  }

  Future<void> _enqueue(ReceivableModel model) async {
    final queue = syncQueue;
    if (queue == null) {
      return;
    }
    try {
      await queue.enqueue(
        SyncOperation.upsert(
          entityType: SyncEntityType.receivable,
          entityId: model.id,
          payload: model.toJson(),
          queuedAt: clock.now(),
        ),
      );
    } catch (_) {
      // The local write is authoritative; a queue failure must not lose it.
    }
  }

  CacheFailure _toCacheFailure(CacheException exception) =>
      CacheFailure(exception.message, code: exception.code);
}
